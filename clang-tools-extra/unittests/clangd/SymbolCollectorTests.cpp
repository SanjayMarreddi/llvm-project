//===-- SymbolCollectorTests.cpp  -------------------------------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "Annotations.h"
#include "TestFS.h"
#include "index/SymbolCollector.h"
#include "index/SymbolYAML.h"
#include "clang/Basic/FileManager.h"
#include "clang/Basic/FileSystemOptions.h"
#include "clang/Basic/VirtualFileSystem.h"
#include "clang/Frontend/CompilerInstance.h"
#include "clang/Index/IndexingAction.h"
#include "clang/Tooling/Tooling.h"
#include "llvm/ADT/IntrusiveRefCntPtr.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/Support/MemoryBuffer.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"

#include <memory>
#include <string>

using testing::AllOf;
using testing::Eq;
using testing::Field;
using testing::Not;
using testing::UnorderedElementsAre;
using testing::UnorderedElementsAreArray;

// GMock helpers for matching Symbol.
MATCHER_P(Labeled, Label, "") { return arg.CompletionLabel == Label; }
MATCHER(HasDetail, "") { return arg.Detail; }
MATCHER_P(Detail, D, "") {
  return arg.Detail && arg.Detail->CompletionDetail == D;
}
MATCHER_P(Doc, D, "") { return arg.Detail && arg.Detail->Documentation == D; }
MATCHER_P(Plain, Text, "") { return arg.CompletionPlainInsertText == Text; }
MATCHER_P(Snippet, S, "") {
  return arg.CompletionSnippetInsertText == S;
}
MATCHER_P(QName, Name, "") { return (arg.Scope + arg.Name).str() == Name; }
MATCHER_P(DeclURI, P, "") { return arg.CanonicalDeclaration.FileURI == P; }
MATCHER_P(DefURI, P, "") { return arg.Definition.FileURI == P; }
MATCHER_P(IncludeHeader, P, "") {
  return arg.Detail && arg.Detail->IncludeHeader == P;
}
MATCHER_P(DeclRange, Pos, "") {
  return std::tie(arg.CanonicalDeclaration.Start.Line,
                  arg.CanonicalDeclaration.Start.Column,
                  arg.CanonicalDeclaration.End.Line,
                  arg.CanonicalDeclaration.End.Column) ==
         std::tie(Pos.start.line, Pos.start.character, Pos.end.line,
                  Pos.end.character);
}
MATCHER_P(DefRange, Pos, "") {
  return std::tie(arg.Definition.Start.Line,
                  arg.Definition.Start.Column, arg.Definition.End.Line,
                  arg.Definition.End.Column) ==
         std::tie(Pos.start.line, Pos.start.character, Pos.end.line,
                  Pos.end.character);
}
MATCHER_P(Refs, R, "") { return int(arg.References) == R; }
MATCHER_P(ForCodeCompletion, IsIndexedForCodeCompletion, "") {
  return arg.IsIndexedForCodeCompletion == IsIndexedForCodeCompletion;
}

namespace clang {
namespace clangd {

namespace {
class SymbolIndexActionFactory : public tooling::FrontendActionFactory {
public:
  SymbolIndexActionFactory(SymbolCollector::Options COpts,
                           CommentHandler *PragmaHandler)
      : COpts(std::move(COpts)), PragmaHandler(PragmaHandler) {}

  clang::FrontendAction *create() override {
    class WrappedIndexAction : public WrapperFrontendAction {
    public:
      WrappedIndexAction(std::shared_ptr<SymbolCollector> C,
                         const index::IndexingOptions &Opts,
                         CommentHandler *PragmaHandler)
          : WrapperFrontendAction(
                index::createIndexingAction(C, Opts, nullptr)),
            PragmaHandler(PragmaHandler) {}

      std::unique_ptr<ASTConsumer>
      CreateASTConsumer(CompilerInstance &CI, StringRef InFile) override {
        if (PragmaHandler)
          CI.getPreprocessor().addCommentHandler(PragmaHandler);
        return WrapperFrontendAction::CreateASTConsumer(CI, InFile);
      }

    private:
      index::IndexingOptions IndexOpts;
      CommentHandler *PragmaHandler;
    };
    index::IndexingOptions IndexOpts;
    IndexOpts.SystemSymbolFilter =
        index::IndexingOptions::SystemSymbolFilterKind::All;
    IndexOpts.IndexFunctionLocals = false;
    Collector = std::make_shared<SymbolCollector>(COpts);
    return new WrappedIndexAction(Collector, std::move(IndexOpts),
                                  PragmaHandler);
  }

  std::shared_ptr<SymbolCollector> Collector;
  SymbolCollector::Options COpts;
  CommentHandler *PragmaHandler;
};

class SymbolCollectorTest : public ::testing::Test {
public:
  SymbolCollectorTest()
      : InMemoryFileSystem(new vfs::InMemoryFileSystem),
        TestHeaderName(testPath("symbol.h")),
        TestFileName(testPath("symbol.cc")) {
    TestHeaderURI = URI::createFile(TestHeaderName).toString();
    TestFileURI = URI::createFile(TestFileName).toString();
  }

  bool runSymbolCollector(StringRef HeaderCode, StringRef MainCode,
                          const std::vector<std::string> &ExtraArgs = {}) {
    llvm::IntrusiveRefCntPtr<FileManager> Files(
        new FileManager(FileSystemOptions(), InMemoryFileSystem));

    auto Factory = llvm::make_unique<SymbolIndexActionFactory>(
        CollectorOpts, PragmaHandler.get());

    std::vector<std::string> Args = {
        "symbol_collector", "-fsyntax-only", "-xc++",
        "-std=c++11",       "-include",      TestHeaderName};
    Args.insert(Args.end(), ExtraArgs.begin(), ExtraArgs.end());
    // This allows to override the "-xc++" with something else, i.e.
    // -xobjective-c++.
    Args.push_back(TestFileName);

    tooling::ToolInvocation Invocation(
        Args,
        Factory->create(), Files.get(),
        std::make_shared<PCHContainerOperations>());

    InMemoryFileSystem->addFile(TestHeaderName, 0,
                                llvm::MemoryBuffer::getMemBuffer(HeaderCode));
    InMemoryFileSystem->addFile(TestFileName, 0,
                                llvm::MemoryBuffer::getMemBuffer(MainCode));
    Invocation.run();
    Symbols = Factory->Collector->takeSymbols();
    return true;
  }

protected:
  llvm::IntrusiveRefCntPtr<vfs::InMemoryFileSystem> InMemoryFileSystem;
  std::string TestHeaderName;
  std::string TestHeaderURI;
  std::string TestFileName;
  std::string TestFileURI;
  SymbolSlab Symbols;
  SymbolCollector::Options CollectorOpts;
  std::unique_ptr<CommentHandler> PragmaHandler;
};

TEST_F(SymbolCollectorTest, CollectSymbols) {
  const std::string Header = R"(
    class Foo {
      Foo() {}
      Foo(int a) {}
      void f();
      friend void f1();
      friend class Friend;
      Foo& operator=(const Foo&);
      ~Foo();
      class Nested {
      void f();
      };
    };
    class Friend {
    };

    void f1();
    inline void f2() {}
    static const int KInt = 2;
    const char* kStr = "123";

    namespace {
    void ff() {} // ignore
    }

    void f1() {}

    namespace foo {
    // Type alias
    typedef int int32;
    using int32_t = int32;

    // Variable
    int v1;

    // Namespace
    namespace bar {
    int v2;
    }
    // Namespace alias
    namespace baz = bar;

    // FIXME: using declaration is not supported as the IndexAction will ignore
    // implicit declarations (the implicit using shadow declaration) by default,
    // and there is no way to customize this behavior at the moment.
    using bar::v2;
    } // namespace foo
  )";
  runSymbolCollector(Header, /*Main=*/"");
  EXPECT_THAT(Symbols,
              UnorderedElementsAreArray(
                  {AllOf(QName("Foo"), ForCodeCompletion(true)),
                   AllOf(QName("Foo::Foo"), ForCodeCompletion(false)),
                   AllOf(QName("Foo::Foo"), ForCodeCompletion(false)),
                   AllOf(QName("Foo::f"), ForCodeCompletion(false)),
                   AllOf(QName("Foo::~Foo"), ForCodeCompletion(false)),
                   AllOf(QName("Foo::operator="), ForCodeCompletion(false)),
                   AllOf(QName("Foo::Nested"), ForCodeCompletion(false)),
                   AllOf(QName("Foo::Nested::f"), ForCodeCompletion(false)),

                   AllOf(QName("Friend"), ForCodeCompletion(true)),
                   AllOf(QName("f1"), ForCodeCompletion(true)),
                   AllOf(QName("f2"), ForCodeCompletion(true)),
                   AllOf(QName("KInt"), ForCodeCompletion(true)),
                   AllOf(QName("kStr"), ForCodeCompletion(true)),
                   AllOf(QName("foo"), ForCodeCompletion(true)),
                   AllOf(QName("foo::bar"), ForCodeCompletion(true)),
                   AllOf(QName("foo::int32"), ForCodeCompletion(true)),
                   AllOf(QName("foo::int32_t"), ForCodeCompletion(true)),
                   AllOf(QName("foo::v1"), ForCodeCompletion(true)),
                   AllOf(QName("foo::bar::v2"), ForCodeCompletion(true)),
                   AllOf(QName("foo::baz"), ForCodeCompletion(true))}));
}

TEST_F(SymbolCollectorTest, Template) {
  Annotations Header(R"(
    // Template is indexed, specialization and instantiation is not.
    template <class T> struct [[Tmpl]] {T $xdecl[[x]] = 0;};
    template <> struct Tmpl<int> {};
    extern template struct Tmpl<float>;
    template struct Tmpl<double>;
  )");
  runSymbolCollector(Header.code(), /*Main=*/"");
  EXPECT_THAT(Symbols,
              UnorderedElementsAreArray(
                  {AllOf(QName("Tmpl"), DeclRange(Header.range())),
                   AllOf(QName("Tmpl::x"), DeclRange(Header.range("xdecl")))}));
}

TEST_F(SymbolCollectorTest, ObjCSymbols) {
  const std::string Header = R"(
    @interface Person
    - (void)someMethodName:(void*)name1 lastName:(void*)lName;
    @end

    @implementation Person
    - (void)someMethodName:(void*)name1 lastName:(void*)lName{
      int foo;
      ^(int param){ int bar; };
    }
    @end

    @interface Person (MyCategory)
    - (void)someMethodName2:(void*)name2;
    @end

    @implementation Person (MyCategory)
    - (void)someMethodName2:(void*)name2 {
      int foo2;
    }
    @end

    @protocol MyProtocol
    - (void)someMethodName3:(void*)name3;
    @end
  )";
  TestFileName = "test.m";
  runSymbolCollector(Header, /*Main=*/"", {"-fblocks", "-xobjective-c++"});
  EXPECT_THAT(Symbols,
              UnorderedElementsAre(
                  QName("Person"), QName("Person::someMethodName:lastName:"),
                  QName("MyCategory"), QName("Person::someMethodName2:"),
                  QName("MyProtocol"), QName("MyProtocol::someMethodName3:")));
}

TEST_F(SymbolCollectorTest, Locations) {
  Annotations Header(R"cpp(
    // Declared in header, defined in main.
    extern int $xdecl[[X]];
    class $clsdecl[[Cls]];
    void $printdecl[[print]]();

    // Declared in header, defined nowhere.
    extern int $zdecl[[Z]];

    void $foodecl[[fo\
o]]();
  )cpp");
  Annotations Main(R"cpp(
    int $xdef[[X]] = 42;
    class $clsdef[[Cls]] {};
    void $printdef[[print]]() {}

    // Declared/defined in main only.
    int Y;
  )cpp");
  runSymbolCollector(Header.code(), Main.code());
  EXPECT_THAT(
      Symbols,
      UnorderedElementsAre(
          AllOf(QName("X"), DeclRange(Header.range("xdecl")),
                DefRange(Main.range("xdef"))),
          AllOf(QName("Cls"), DeclRange(Header.range("clsdecl")),
                DefRange(Main.range("clsdef"))),
          AllOf(QName("print"), DeclRange(Header.range("printdecl")),
                DefRange(Main.range("printdef"))),
          AllOf(QName("Z"), DeclRange(Header.range("zdecl"))),
          AllOf(QName("foo"), DeclRange(Header.range("foodecl")))
          ));
}

TEST_F(SymbolCollectorTest, References) {
  const std::string Header = R"(
    class W;
    class X {};
    class Y;
    class Z {}; // not used anywhere
    Y* y = nullptr;  // used in header doesn't count
    #define GLOBAL_Z(name) Z name;
  )";
  const std::string Main = R"(
    W* w = nullptr;
    W* w2 = nullptr; // only one usage counts
    X x();
    class V;
    V* v = nullptr; // Used, but not eligible for indexing.
    class Y{}; // definition doesn't count as a reference
    GLOBAL_Z(z); // Not a reference to Z, we don't spell the type.
  )";
  CollectorOpts.CountReferences = true;
  runSymbolCollector(Header, Main);
  EXPECT_THAT(Symbols,
              UnorderedElementsAre(AllOf(QName("W"), Refs(1)),
                                   AllOf(QName("X"), Refs(1)),
                                   AllOf(QName("Y"), Refs(0)),
                                   AllOf(QName("Z"), Refs(0)), QName("y")));
}

TEST_F(SymbolCollectorTest, SymbolRelativeNoFallback) {
  runSymbolCollector("class Foo {};", /*Main=*/"");
  EXPECT_THAT(Symbols, UnorderedElementsAre(
                           AllOf(QName("Foo"), DeclURI(TestHeaderURI))));
}

TEST_F(SymbolCollectorTest, SymbolRelativeWithFallback) {
  TestHeaderName = "x.h";
  TestFileName = "x.cpp";
  TestHeaderURI = URI::createFile(testPath(TestHeaderName)).toString();
  CollectorOpts.FallbackDir = testRoot();
  runSymbolCollector("class Foo {};", /*Main=*/"");
  EXPECT_THAT(Symbols,
              UnorderedElementsAre(AllOf(QName("Foo"), DeclURI(TestHeaderURI))));
}

TEST_F(SymbolCollectorTest, CustomURIScheme) {
  // Use test URI scheme from URITests.cpp
  CollectorOpts.URISchemes.insert(CollectorOpts.URISchemes.begin(), "unittest");
  TestHeaderName = testPath("x.h");
  TestFileName = testPath("x.cpp");
  runSymbolCollector("class Foo {};", /*Main=*/"");
  EXPECT_THAT(Symbols, UnorderedElementsAre(
                           AllOf(QName("Foo"), DeclURI("unittest:///x.h"))));
}

TEST_F(SymbolCollectorTest, InvalidURIScheme) {
  // Use test URI scheme from URITests.cpp
  CollectorOpts.URISchemes = {"invalid"};
  runSymbolCollector("class Foo {};", /*Main=*/"");
  EXPECT_THAT(Symbols, UnorderedElementsAre(AllOf(QName("Foo"), DeclURI(""))));
}

TEST_F(SymbolCollectorTest, FallbackToFileURI) {
  // Use test URI scheme from URITests.cpp
  CollectorOpts.URISchemes = {"invalid", "file"};
  runSymbolCollector("class Foo {};", /*Main=*/"");
  EXPECT_THAT(Symbols, UnorderedElementsAre(
                           AllOf(QName("Foo"), DeclURI(TestHeaderURI))));
}

TEST_F(SymbolCollectorTest, IncludeEnums) {
  const std::string Header = R"(
    enum {
      Red
    };
    enum Color {
      Green
    };
    enum class Color2 {
      Yellow
    };
    namespace ns {
    enum {
      Black
    };
    }
  )";
  runSymbolCollector(Header, /*Main=*/"");
  EXPECT_THAT(Symbols,
              UnorderedElementsAre(
                  AllOf(QName("Red"), ForCodeCompletion(true)),
                  AllOf(QName("Color"), ForCodeCompletion(true)),
                  AllOf(QName("Green"), ForCodeCompletion(true)),
                  AllOf(QName("Color2"), ForCodeCompletion(true)),
                  AllOf(QName("Color2::Yellow"), ForCodeCompletion(false)),
                  AllOf(QName("ns"), ForCodeCompletion(true)),
                  AllOf(QName("ns::Black"), ForCodeCompletion(true))));
}

TEST_F(SymbolCollectorTest, NamelessSymbols) {
  const std::string Header = R"(
    struct {
      int a;
    } Foo;
  )";
  runSymbolCollector(Header, /*Main=*/"");
  EXPECT_THAT(Symbols, UnorderedElementsAre(QName("Foo"),
                                            QName("(anonymous struct)::a")));
}

TEST_F(SymbolCollectorTest, SymbolFormedFromMacro) {

  Annotations Header(R"(
    #define FF(name) \
      class name##_Test {};

    $expansion[[FF]](abc);

    #define FF2() \
      class $spelling[[Test]] {};

    FF2();
  )");

  runSymbolCollector(Header.code(), /*Main=*/"");
  EXPECT_THAT(
      Symbols,
      UnorderedElementsAre(
          AllOf(QName("abc_Test"), DeclRange(Header.range("expansion")),
                DeclURI(TestHeaderURI)),
          AllOf(QName("Test"), DeclRange(Header.range("spelling")),
                DeclURI(TestHeaderURI))));
}

TEST_F(SymbolCollectorTest, SymbolFormedByCLI) {
  Annotations Header(R"(
    #ifdef NAME
    class $expansion[[NAME]] {};
    #endif
  )");

  runSymbolCollector(Header.code(), /*Main=*/"",
                     /*ExtraArgs=*/{"-DNAME=name"});
  EXPECT_THAT(Symbols,
              UnorderedElementsAre(AllOf(
                  QName("name"),
                  DeclRange(Header.range("expansion")),
                  DeclURI(TestHeaderURI))));
}

TEST_F(SymbolCollectorTest, IgnoreSymbolsInMainFile) {
  const std::string Header = R"(
    class Foo {};
    void f1();
    inline void f2() {}
  )";
  const std::string Main = R"(
    namespace {
    void ff() {} // ignore
    }
    void main_f() {} // ignore
    void f1() {}
  )";
  runSymbolCollector(Header, Main);
  EXPECT_THAT(Symbols,
              UnorderedElementsAre(QName("Foo"), QName("f1"), QName("f2")));
}

TEST_F(SymbolCollectorTest, ClassMembers) {
  const std::string Header = R"(
    class Foo {
      void f() {}
      void g();
      static void sf() {}
      static void ssf();
      static int x;
    };
  )";
  const std::string Main = R"(
    void Foo::g() {}
    void Foo::ssf() {}
  )";
  runSymbolCollector(Header, Main);
  EXPECT_THAT(Symbols,
              UnorderedElementsAre(QName("Foo"), QName("Foo::f"),
                                   QName("Foo::g"), QName("Foo::sf"),
                                   QName("Foo::ssf"), QName("Foo::x")));
}

TEST_F(SymbolCollectorTest, Scopes) {
  const std::string Header = R"(
    namespace na {
    class Foo {};
    namespace nb {
    class Bar {};
    }
    }
  )";
  runSymbolCollector(Header, /*Main=*/"");
  EXPECT_THAT(Symbols,
              UnorderedElementsAre(QName("na"), QName("na::nb"),
                                   QName("na::Foo"), QName("na::nb::Bar")));
}

TEST_F(SymbolCollectorTest, ExternC) {
  const std::string Header = R"(
    extern "C" { class Foo {}; }
    namespace na {
    extern "C" { class Bar {}; }
    }
  )";
  runSymbolCollector(Header, /*Main=*/"");
  EXPECT_THAT(Symbols, UnorderedElementsAre(QName("na"), QName("Foo"),
                                            QName("na::Bar")));
}

TEST_F(SymbolCollectorTest, SkipInlineNamespace) {
  const std::string Header = R"(
    namespace na {
    inline namespace nb {
    class Foo {};
    }
    }
    namespace na {
    // This is still inlined.
    namespace nb {
    class Bar {};
    }
    }
  )";
  runSymbolCollector(Header, /*Main=*/"");
  EXPECT_THAT(Symbols,
              UnorderedElementsAre(QName("na"), QName("na::nb"),
                                   QName("na::Foo"), QName("na::Bar")));
}

TEST_F(SymbolCollectorTest, SymbolWithDocumentation) {
  const std::string Header = R"(
    namespace nx {
    /// Foo comment.
    int ff(int x, double y) { return 0; }
    }
  )";
  runSymbolCollector(Header, /*Main=*/"");
  EXPECT_THAT(
      Symbols,
      UnorderedElementsAre(
          QName("nx"), AllOf(QName("nx::ff"), Labeled("ff(int x, double y)"),
                             Detail("int"), Doc("Foo comment."))));
}

TEST_F(SymbolCollectorTest, PlainAndSnippet) {
  const std::string Header = R"(
    namespace nx {
    void f() {}
    int ff(int x, double y) { return 0; }
    }
  )";
  runSymbolCollector(Header, /*Main=*/"");
  EXPECT_THAT(
      Symbols,
      UnorderedElementsAre(
          QName("nx"),
          AllOf(QName("nx::f"), Labeled("f()"), Plain("f"), Snippet("f()")),
          AllOf(QName("nx::ff"), Labeled("ff(int x, double y)"), Plain("ff"),
                Snippet("ff(${1:int x}, ${2:double y})"))));
}

TEST_F(SymbolCollectorTest, YAMLConversions) {
  const std::string YAML1 = R"(
---
ID: 057557CEBF6E6B2DD437FBF60CC58F352D1DF856
Name:   'Foo1'
Scope:   'clang::'
SymInfo:
  Kind:            Function
  Lang:            Cpp
CanonicalDeclaration:
  FileURI:        file:///path/foo.h
  Start:
    Line: 1
    Column: 0
  End:
    Line: 1
    Column: 1
IsIndexedForCodeCompletion:    true
CompletionLabel:    'Foo1-label'
CompletionFilterText:    'filter'
CompletionPlainInsertText:    'plain'
Detail:
  Documentation:    'Foo doc'
  CompletionDetail:    'int'
...
)";
  const std::string YAML2 = R"(
---
ID: 057557CEBF6E6B2DD437FBF60CC58F352D1DF858
Name:   'Foo2'
Scope:   'clang::'
SymInfo:
  Kind:            Function
  Lang:            Cpp
CanonicalDeclaration:
  FileURI:        file:///path/bar.h
  Start:
    Line: 1
    Column: 0
  End:
    Line: 1
    Column: 1
IsIndexedForCodeCompletion:    false
CompletionLabel:    'Foo2-label'
CompletionFilterText:    'filter'
CompletionPlainInsertText:    'plain'
CompletionSnippetInsertText:    'snippet'
...
)";

  auto Symbols1 = SymbolsFromYAML(YAML1);

  EXPECT_THAT(Symbols1,
              UnorderedElementsAre(AllOf(
                  QName("clang::Foo1"), Labeled("Foo1-label"), Doc("Foo doc"),
                  Detail("int"), DeclURI("file:///path/foo.h"),
                  ForCodeCompletion(true))));
  auto Symbols2 = SymbolsFromYAML(YAML2);
  EXPECT_THAT(Symbols2,
              UnorderedElementsAre(AllOf(
                  QName("clang::Foo2"), Labeled("Foo2-label"), Not(HasDetail()),
                  DeclURI("file:///path/bar.h"), ForCodeCompletion(false))));

  std::string ConcatenatedYAML;
  {
    llvm::raw_string_ostream OS(ConcatenatedYAML);
    SymbolsToYAML(Symbols1, OS);
    SymbolsToYAML(Symbols2, OS);
  }
  auto ConcatenatedSymbols = SymbolsFromYAML(ConcatenatedYAML);
  EXPECT_THAT(ConcatenatedSymbols,
              UnorderedElementsAre(QName("clang::Foo1"),
                                   QName("clang::Foo2")));
}

TEST_F(SymbolCollectorTest, IncludeHeaderSameAsFileURI) {
  CollectorOpts.CollectIncludePath = true;
  runSymbolCollector("class Foo {};", /*Main=*/"");
  EXPECT_THAT(Symbols,
              UnorderedElementsAre(AllOf(QName("Foo"), DeclURI(TestHeaderURI),
                                         IncludeHeader(TestHeaderURI))));
}

#ifndef _WIN32
TEST_F(SymbolCollectorTest, CanonicalSTLHeader) {
  CollectorOpts.CollectIncludePath = true;
  CanonicalIncludes Includes;
  addSystemHeadersMapping(&Includes);
  CollectorOpts.Includes = &Includes;
  // bits/basic_string.h$ should be mapped to <string>
  TestHeaderName = "/nasty/bits/basic_string.h";
  TestFileName = "/nasty/bits/basic_string.cpp";
  TestHeaderURI = URI::createFile(TestHeaderName).toString();
  runSymbolCollector("class string {};", /*Main=*/"");
  EXPECT_THAT(Symbols, UnorderedElementsAre(AllOf(QName("string"),
                                                  DeclURI(TestHeaderURI),
                                                  IncludeHeader("<string>"))));
}
#endif

TEST_F(SymbolCollectorTest, STLiosfwd) {
  CollectorOpts.CollectIncludePath = true;
  CanonicalIncludes Includes;
  addSystemHeadersMapping(&Includes);
  CollectorOpts.Includes = &Includes;
  // Symbols from <iosfwd> should be mapped individually.
  TestHeaderName = testPath("iosfwd");
  TestFileName = testPath("iosfwd.cpp");
  std::string Header = R"(
    namespace std {
      class no_map {};
      class ios {};
      class ostream {};
      class filebuf {};
    } // namespace std
  )";
  runSymbolCollector(Header, /*Main=*/"");
  EXPECT_THAT(Symbols,
              UnorderedElementsAre(
                  QName("std"),
                  AllOf(QName("std::no_map"), IncludeHeader("<iosfwd>")),
                  AllOf(QName("std::ios"), IncludeHeader("<ios>")),
                  AllOf(QName("std::ostream"), IncludeHeader("<ostream>")),
                  AllOf(QName("std::filebuf"), IncludeHeader("<fstream>"))));
}

TEST_F(SymbolCollectorTest, IWYUPragma) {
  CollectorOpts.CollectIncludePath = true;
  CanonicalIncludes Includes;
  PragmaHandler = collectIWYUHeaderMaps(&Includes);
  CollectorOpts.Includes = &Includes;
  const std::string Header = R"(
    // IWYU pragma: private, include the/good/header.h
    class Foo {};
  )";
  runSymbolCollector(Header, /*Main=*/"");
  EXPECT_THAT(Symbols, UnorderedElementsAre(
                           AllOf(QName("Foo"), DeclURI(TestHeaderURI),
                                 IncludeHeader("\"the/good/header.h\""))));
}

TEST_F(SymbolCollectorTest, IWYUPragmaWithDoubleQuotes) {
  CollectorOpts.CollectIncludePath = true;
  CanonicalIncludes Includes;
  PragmaHandler = collectIWYUHeaderMaps(&Includes);
  CollectorOpts.Includes = &Includes;
  const std::string Header = R"(
    // IWYU pragma: private, include "the/good/header.h"
    class Foo {};
  )";
  runSymbolCollector(Header, /*Main=*/"");
  EXPECT_THAT(Symbols, UnorderedElementsAre(
                           AllOf(QName("Foo"), DeclURI(TestHeaderURI),
                                 IncludeHeader("\"the/good/header.h\""))));
}

TEST_F(SymbolCollectorTest, SkipIncFileWhenCanonicalizeHeaders) {
  CollectorOpts.CollectIncludePath = true;
  CanonicalIncludes Includes;
  Includes.addMapping(TestHeaderName, "<canonical>");
  CollectorOpts.Includes = &Includes;
  auto IncFile = testPath("test.inc");
  auto IncURI = URI::createFile(IncFile).toString();
  InMemoryFileSystem->addFile(IncFile, 0,
                              llvm::MemoryBuffer::getMemBuffer("class X {};"));
  runSymbolCollector("#include \"test.inc\"\nclass Y {};", /*Main=*/"",
                     /*ExtraArgs=*/{"-I", testRoot()});
  EXPECT_THAT(Symbols,
              UnorderedElementsAre(AllOf(QName("X"), DeclURI(IncURI),
                                         IncludeHeader("<canonical>")),
                                   AllOf(QName("Y"), DeclURI(TestHeaderURI),
                                         IncludeHeader("<canonical>"))));
}

TEST_F(SymbolCollectorTest, MainFileIsHeaderWhenSkipIncFile) {
  CollectorOpts.CollectIncludePath = true;
  CanonicalIncludes Includes;
  CollectorOpts.Includes = &Includes;
  TestFileName = testPath("main.h");
  TestFileURI = URI::createFile(TestFileName).toString();
  auto IncFile = testPath("test.inc");
  auto IncURI = URI::createFile(IncFile).toString();
  InMemoryFileSystem->addFile(IncFile, 0,
                              llvm::MemoryBuffer::getMemBuffer("class X {};"));
  runSymbolCollector("", /*Main=*/"#include \"test.inc\"",
                     /*ExtraArgs=*/{"-I", testRoot()});
  EXPECT_THAT(Symbols, UnorderedElementsAre(AllOf(QName("X"), DeclURI(IncURI),
                                                  IncludeHeader(TestFileURI))));
}

TEST_F(SymbolCollectorTest, MainFileIsHeaderWithoutExtensionWhenSkipIncFile) {
  CollectorOpts.CollectIncludePath = true;
  CanonicalIncludes Includes;
  CollectorOpts.Includes = &Includes;
  TestFileName = testPath("no_ext_main");
  TestFileURI = URI::createFile(TestFileName).toString();
  auto IncFile = testPath("test.inc");
  auto IncURI = URI::createFile(IncFile).toString();
  InMemoryFileSystem->addFile(IncFile, 0,
                              llvm::MemoryBuffer::getMemBuffer("class X {};"));
  runSymbolCollector("", /*Main=*/"#include \"test.inc\"",
                     /*ExtraArgs=*/{"-I", testRoot()});
  EXPECT_THAT(Symbols, UnorderedElementsAre(AllOf(QName("X"), DeclURI(IncURI),
                                                  IncludeHeader(TestFileURI))));
}

TEST_F(SymbolCollectorTest, FallbackToIncFileWhenIncludingFileIsCC) {
  CollectorOpts.CollectIncludePath = true;
  CanonicalIncludes Includes;
  CollectorOpts.Includes = &Includes;
  auto IncFile = testPath("test.inc");
  auto IncURI = URI::createFile(IncFile).toString();
  InMemoryFileSystem->addFile(IncFile, 0,
                              llvm::MemoryBuffer::getMemBuffer("class X {};"));
  runSymbolCollector("", /*Main=*/"#include \"test.inc\"",
                     /*ExtraArgs=*/{"-I", testRoot()});
  EXPECT_THAT(Symbols, UnorderedElementsAre(AllOf(QName("X"), DeclURI(IncURI),
                                                  IncludeHeader(IncURI))));
}

TEST_F(SymbolCollectorTest, AvoidUsingFwdDeclsAsCanonicalDecls) {
  CollectorOpts.CollectIncludePath = true;
  Annotations Header(R"(
    // Forward declarations of TagDecls.
    class C;
    struct S;
    union U;

    // Canonical declarations.
    class $cdecl[[C]] {};
    struct $sdecl[[S]] {};
    union $udecl[[U]] {int $xdecl[[x]]; bool $ydecl[[y]];};
  )");
  runSymbolCollector(Header.code(), /*Main=*/"");
  EXPECT_THAT(
      Symbols,
      UnorderedElementsAre(
          AllOf(QName("C"), DeclURI(TestHeaderURI),
                DeclRange(Header.range("cdecl")), IncludeHeader(TestHeaderURI),
                DefURI(TestHeaderURI), DefRange(Header.range("cdecl"))),
          AllOf(QName("S"), DeclURI(TestHeaderURI),
                DeclRange(Header.range("sdecl")), IncludeHeader(TestHeaderURI),
                DefURI(TestHeaderURI), DefRange(Header.range("sdecl"))),
          AllOf(QName("U"), DeclURI(TestHeaderURI),
                DeclRange(Header.range("udecl")), IncludeHeader(TestHeaderURI),
                DefURI(TestHeaderURI), DefRange(Header.range("udecl"))),
          AllOf(QName("U::x"), DeclURI(TestHeaderURI),
                DeclRange(Header.range("xdecl")), DefURI(TestHeaderURI),
                DefRange(Header.range("xdecl"))),
          AllOf(QName("U::y"), DeclURI(TestHeaderURI),
                DeclRange(Header.range("ydecl")), DefURI(TestHeaderURI),
                DefRange(Header.range("ydecl")))));
}

TEST_F(SymbolCollectorTest, ClassForwardDeclarationIsCanonical) {
  CollectorOpts.CollectIncludePath = true;
  runSymbolCollector(/*Header=*/"class X;", /*Main=*/"class X {};");
  EXPECT_THAT(Symbols, UnorderedElementsAre(AllOf(
                           QName("X"), DeclURI(TestHeaderURI),
                           IncludeHeader(TestHeaderURI), DefURI(TestFileURI))));
}

TEST_F(SymbolCollectorTest, UTF16Character) {
  // ö is 2-bytes.
  Annotations Header(/*Header=*/"class [[pörk]] {};");
  runSymbolCollector(Header.code(), /*Main=*/"");
  EXPECT_THAT(Symbols, UnorderedElementsAre(
                           AllOf(QName("pörk"), DeclRange(Header.range()))));
}

TEST_F(SymbolCollectorTest, FilterPrivateProtoSymbols) {
  TestHeaderName = testPath("x.proto.h");
  const std::string Header =
      R"(// Generated by the protocol buffer compiler.  DO NOT EDIT!
         namespace nx {
           class Top_Level {};
           class TopLevel {};
           enum Kind {
             KIND_OK,
             Kind_Not_Ok,
           };
           bool operator<(const TopLevel &, const TopLevel &);
         })";
  runSymbolCollector(Header, /*Main=*/"");
  EXPECT_THAT(Symbols,
              UnorderedElementsAre(QName("nx"), QName("nx::TopLevel"),
                                   QName("nx::Kind"), QName("nx::KIND_OK"),
                                   QName("nx::operator<")));
}

TEST_F(SymbolCollectorTest, DoubleCheckProtoHeaderComment) {
  TestHeaderName = testPath("x.proto.h");
  const std::string Header = R"(
  namespace nx {
    class Top_Level {};
    enum Kind {
      Kind_Fine
    };
  }
  )";
  runSymbolCollector(Header, /*Main=*/"");
  EXPECT_THAT(Symbols,
              UnorderedElementsAre(QName("nx"), QName("nx::Top_Level"),
                                   QName("nx::Kind"), QName("nx::Kind_Fine")));
}

TEST_F(SymbolCollectorTest, DoNotIndexSymbolsInFriendDecl) {
  Annotations Header(R"(
    namespace nx {
      class $z[[Z]] {};
      class X {
        friend class Y;
        friend class Z;
        friend void foo();
        friend void $bar[[bar]]() {}
      };
      class $y[[Y]] {};
      void $foo[[foo]]();
    }
  )");
  runSymbolCollector(Header.code(), /*Main=*/"");

  EXPECT_THAT(Symbols,
              UnorderedElementsAre(
                  QName("nx"), QName("nx::X"),
                  AllOf(QName("nx::Y"), DeclRange(Header.range("y"))),
                  AllOf(QName("nx::Z"), DeclRange(Header.range("z"))),
                  AllOf(QName("nx::foo"), DeclRange(Header.range("foo"))),
                  AllOf(QName("nx::bar"), DeclRange(Header.range("bar")))));
}

TEST_F(SymbolCollectorTest, ReferencesInFriendDecl) {
  const std::string Header = R"(
    class X;
    class Y;
  )";
  const std::string Main = R"(
    class C {
      friend ::X;
      friend class Y;
    };
  )";
  CollectorOpts.CountReferences = true;
  runSymbolCollector(Header, Main);
  EXPECT_THAT(Symbols, UnorderedElementsAre(AllOf(QName("X"), Refs(1)),
                                            AllOf(QName("Y"), Refs(1))));
}

} // namespace
} // namespace clangd
} // namespace clang
