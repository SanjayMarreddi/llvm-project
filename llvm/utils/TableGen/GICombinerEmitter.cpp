//===- GlobalCombinerEmitter.cpp - Generate a combiner --------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
/// \file Generate a combiner implementation for GlobalISel from a declarative
/// syntax
///
//===----------------------------------------------------------------------===//

#include "llvm/ADT/Statistic.h"
#include "llvm/ADT/StringSet.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/ScopedPrinter.h"
#include "llvm/Support/Timer.h"
#include "llvm/TableGen/Error.h"
#include "llvm/TableGen/StringMatcher.h"
#include "llvm/TableGen/TableGenBackend.h"
#include "CodeGenTarget.h"
#include "GlobalISel/CodeExpander.h"
#include "GlobalISel/CodeExpansions.h"
#include "GlobalISel/GIMatchDag.h"

using namespace llvm;

#define DEBUG_TYPE "gicombiner-emitter"

// FIXME: Use ALWAYS_ENABLED_STATISTIC once it's available.
unsigned NumPatternTotal = 0;
STATISTIC(NumPatternTotalStatistic, "Total number of patterns");

cl::OptionCategory
    GICombinerEmitterCat("Options for -gen-global-isel-combiner");
static cl::list<std::string>
    SelectedCombiners("combiners", cl::desc("Emit the specified combiners"),
                      cl::cat(GICombinerEmitterCat), cl::CommaSeparated);
static cl::opt<bool> ShowExpansions(
    "gicombiner-show-expansions",
    cl::desc("Use C++ comments to indicate occurence of code expansion"),
    cl::cat(GICombinerEmitterCat));
static cl::opt<bool> StopAfterParse(
    "gicombiner-stop-after-parse",
    cl::desc("Stop processing after parsing rules and dump state"),
    cl::cat(GICombinerEmitterCat));

namespace {
typedef uint64_t RuleID;

// We're going to be referencing the same small strings quite a lot for operand
// names and the like. Make their lifetime management simple with a global
// string table.
StringSet<> StrTab;

StringRef insertStrTab(StringRef S) {
  if (S.empty())
    return S;
  return StrTab.insert(S).first->first();
}

class RootInfo {
  StringRef PatternSymbol;

public:
  RootInfo(StringRef PatternSymbol) : PatternSymbol(PatternSymbol) {}

  StringRef getPatternSymbol() const { return PatternSymbol; }
};

class CombineRule {
  struct VarInfo {
    const GIMatchDagInstr *N;
    const GIMatchDagOperand *Op;
    const DagInit *Matcher;

  public:
    VarInfo(const GIMatchDagInstr *N, const GIMatchDagOperand *Op,
            const DagInit *Matcher)
        : N(N), Op(Op), Matcher(Matcher) {}
  };

protected:
  /// A unique ID for this rule
  /// ID's are used for debugging and run-time disabling of rules among other
  /// things.
  RuleID ID;

  /// A unique ID that can be used for anonymous objects belonging to this rule.
  /// Used to create unique names in makeNameForAnon*() without making tests
  /// overly fragile.
  unsigned UID = 0;

  /// The record defining this rule.
  const Record &TheDef;

  /// The roots of a match. These are the leaves of the DAG that are closest to
  /// the end of the function. I.e. the nodes that are encountered without
  /// following any edges of the DAG described by the pattern as we work our way
  /// from the bottom of the function to the top.
  std::vector<RootInfo> Roots;

  GIMatchDag MatchDag;

  /// A block of arbitrary C++ to finish testing the match.
  /// FIXME: This is a temporary measure until we have actual pattern matching
  const CodeInit *MatchingFixupCode = nullptr;

  bool parseInstructionMatcher(const CodeGenTarget &Target, StringInit *ArgName,
                               const Init &Arg,
                               StringMap<std::vector<VarInfo>> &NamedEdgeDefs,
                               StringMap<std::vector<VarInfo>> &NamedEdgeUses);

public:
  CombineRule(const CodeGenTarget &Target, GIMatchDagContext &Ctx, RuleID ID,
              const Record &R)
      : ID(ID), TheDef(R), MatchDag(Ctx) {}
  CombineRule(const CombineRule &) = delete;

  bool parseDefs();
  bool parseMatcher(const CodeGenTarget &Target);

  RuleID getID() const { return ID; }
  unsigned allocUID() { return UID++; }
  StringRef getName() const { return TheDef.getName(); }
  const Record &getDef() const { return TheDef; }
  const CodeInit *getMatchingFixupCode() const { return MatchingFixupCode; }
  size_t getNumRoots() const { return Roots.size(); }

  GIMatchDag &getMatchDag() { return MatchDag; }
  const GIMatchDag &getMatchDag() const { return MatchDag; }

  using const_root_iterator = std::vector<RootInfo>::const_iterator;
  const_root_iterator roots_begin() const { return Roots.begin(); }
  const_root_iterator roots_end() const { return Roots.end(); }
  iterator_range<const_root_iterator> roots() const {
    return llvm::make_range(Roots.begin(), Roots.end());
  }
};

/// A convenience function to check that an Init refers to a specific def. This
/// is primarily useful for testing for defs and similar in DagInit's since
/// DagInit's support any type inside them.
static bool isSpecificDef(const Init &N, StringRef Def) {
  if (const DefInit *OpI = dyn_cast<DefInit>(&N))
    if (OpI->getDef()->getName() == Def)
      return true;
  return false;
}

/// A convenience function to check that an Init refers to a def that is a
/// subclass of the given class and coerce it to a def if it is. This is
/// primarily useful for testing for subclasses of GIMatchKind and similar in
/// DagInit's since DagInit's support any type inside them.
static Record *getDefOfSubClass(const Init &N, StringRef Cls) {
  if (const DefInit *OpI = dyn_cast<DefInit>(&N))
    if (OpI->getDef()->isSubClassOf(Cls))
      return OpI->getDef();
  return nullptr;
}

/// A convenience function to check that an Init refers to a dag whose operator
/// is a def that is a subclass of the given class and coerce it to a dag if it
/// is. This is primarily useful for testing for subclasses of GIMatchKind and
/// similar in DagInit's since DagInit's support any type inside them.
static const DagInit *getDagWithOperatorOfSubClass(const Init &N,
                                                   StringRef Cls) {
  if (const DagInit *I = dyn_cast<DagInit>(&N))
    if (I->getNumArgs() > 0)
      if (const DefInit *OpI = dyn_cast<DefInit>(I->getOperator()))
        if (OpI->getDef()->isSubClassOf(Cls))
          return I;
  return nullptr;
}

StringRef makeNameForAnonInstr(CombineRule &Rule) {
  return insertStrTab(
      to_string(format("__anon%d_%d", Rule.getID(), Rule.allocUID())));
}

StringRef makeDebugName(CombineRule &Rule, StringRef Name) {
  return insertStrTab(Name.empty() ? makeNameForAnonInstr(Rule) : StringRef(Name));
}

StringRef makeNameForAnonPredicate(CombineRule &Rule) {
  return insertStrTab(
      to_string(format("__anonpred%d_%d", Rule.getID(), Rule.allocUID())));
}

bool CombineRule::parseDefs() {
  NamedRegionTimer T("parseDefs", "Time spent parsing the defs", "Rule Parsing",
                     "Time spent on rule parsing", TimeRegions);
  DagInit *Defs = TheDef.getValueAsDag("Defs");

  if (Defs->getOperatorAsDef(TheDef.getLoc())->getName() != "defs") {
    PrintError(TheDef.getLoc(), "Expected defs operator");
    return false;
  }

  for (unsigned I = 0, E = Defs->getNumArgs(); I < E; ++I) {
    // Roots should be collected into Roots
    if (isSpecificDef(*Defs->getArg(I), "root")) {
      Roots.emplace_back(Defs->getArgNameStr(I));
      continue;
    }

    // Otherwise emit an appropriate error message.
    if (getDefOfSubClass(*Defs->getArg(I), "GIDefKind"))
      PrintError(TheDef.getLoc(),
                 "This GIDefKind not implemented in tablegen");
    else if (getDefOfSubClass(*Defs->getArg(I), "GIDefKindWithArgs"))
      PrintError(TheDef.getLoc(),
                 "This GIDefKindWithArgs not implemented in tablegen");
    else
      PrintError(TheDef.getLoc(),
                 "Expected a subclass of GIDefKind or a sub-dag whose "
                 "operator is of type GIDefKindWithArgs");
    return false;
  }

  if (Roots.empty()) {
    PrintError(TheDef.getLoc(), "Combine rules must have at least one root");
    return false;
  }
  return true;
}

// Parse an (Instruction $a:Arg1, $b:Arg2, ...) matcher. Edges are formed
// between matching operand names between different matchers.
bool CombineRule::parseInstructionMatcher(
    const CodeGenTarget &Target, StringInit *ArgName, const Init &Arg,
    StringMap<std::vector<VarInfo>> &NamedEdgeDefs,
    StringMap<std::vector<VarInfo>> &NamedEdgeUses) {
  if (const DagInit *Matcher =
          getDagWithOperatorOfSubClass(Arg, "Instruction")) {
    auto &Instr =
        Target.getInstruction(Matcher->getOperatorAsDef(TheDef.getLoc()));

    StringRef Name = ArgName ? ArgName->getValue() : "";

    GIMatchDagInstr *N =
        MatchDag.addInstrNode(makeDebugName(*this, Name), insertStrTab(Name),
                              MatchDag.getContext().makeOperandList(Instr));

    N->setOpcodeAnnotation(&Instr);
    const auto &P = MatchDag.addPredicateNode<GIMatchDagOpcodePredicate>(
        makeNameForAnonPredicate(*this), Instr);
    MatchDag.addPredicateDependency(N, nullptr, P, &P->getOperandInfo()["mi"]);
    unsigned OpIdx = 0;
    for (const auto &NameInit : Matcher->getArgNames()) {
      StringRef Name = insertStrTab(NameInit->getAsUnquotedString());
      if (Name.empty())
        continue;
      N->assignNameToOperand(OpIdx, Name);

      // Record the endpoints of any named edges. We'll add the cartesian
      // product of edges later.
      const auto &InstrOperand = N->getOperandInfo()[OpIdx];
      if (InstrOperand.isDef()) {
        NamedEdgeDefs.try_emplace(Name);
        NamedEdgeDefs[Name].emplace_back(N, &InstrOperand, Matcher);
      } else {
        NamedEdgeUses.try_emplace(Name);
        NamedEdgeUses[Name].emplace_back(N, &InstrOperand, Matcher);
      }

      if (InstrOperand.isDef()) {
        if (find_if(Roots, [&](const RootInfo &X) {
              return X.getPatternSymbol() == Name;
            }) != Roots.end()) {
          N->setMatchRoot();
        }
      }

      OpIdx++;
    }

    return true;
  }
  return false;
}

bool CombineRule::parseMatcher(const CodeGenTarget &Target) {
  NamedRegionTimer T("parseMatcher", "Time spent parsing the matcher",
                     "Rule Parsing", "Time spent on rule parsing", TimeRegions);
  StringMap<std::vector<VarInfo>> NamedEdgeDefs;
  StringMap<std::vector<VarInfo>> NamedEdgeUses;
  DagInit *Matchers = TheDef.getValueAsDag("Match");

  if (Matchers->getOperatorAsDef(TheDef.getLoc())->getName() != "match") {
    PrintError(TheDef.getLoc(), "Expected match operator");
    return false;
  }

  if (Matchers->getNumArgs() == 0) {
    PrintError(TheDef.getLoc(), "Matcher is empty");
    return false;
  }

  // The match section consists of a list of matchers and predicates. Parse each
  // one and add the equivalent GIMatchDag nodes, predicates, and edges.
  for (unsigned I = 0; I < Matchers->getNumArgs(); ++I) {
    if (parseInstructionMatcher(Target, Matchers->getArgName(I),
                                *Matchers->getArg(I), NamedEdgeDefs,
                                NamedEdgeUses))
      continue;


    // Parse arbitrary C++ code we have in lieu of supporting MIR matching
    if (const CodeInit *CodeI = dyn_cast<CodeInit>(Matchers->getArg(I))) {
      assert(!MatchingFixupCode &&
             "Only one block of arbitrary code is currently permitted");
      MatchingFixupCode = CodeI;
      continue;
    }

    PrintError(TheDef.getLoc(),
               "Expected a subclass of GIMatchKind or a sub-dag whose "
               "operator is either of a GIMatchKindWithArgs or Instruction");
    PrintNote("Pattern was `" + Matchers->getArg(I)->getAsString() + "'");
    return false;
  }

  // Add the cartesian product of use -> def edges.
  bool FailedToAddEdges = false;
  for (const auto &NameAndDefs : NamedEdgeDefs) {
    if (NameAndDefs.getValue().size() > 1) {
      PrintError(TheDef.getLoc(),
                 "Two different MachineInstrs cannot def the same vreg");
      for (const auto &NameAndDefOp : NameAndDefs.getValue())
        PrintNote("in " + to_string(*NameAndDefOp.N) + " created from " +
                  to_string(*NameAndDefOp.Matcher) + "");
      FailedToAddEdges = true;
    }
    const auto &Uses = NamedEdgeUses[NameAndDefs.getKey()];
    for (const VarInfo &DefVar : NameAndDefs.getValue()) {
      for (const VarInfo &UseVar : Uses) {
        MatchDag.addEdge(insertStrTab(NameAndDefs.getKey()), UseVar.N, UseVar.Op,
                         DefVar.N, DefVar.Op);
      }
    }
  }
  if (FailedToAddEdges)
    return false;

  // If a variable is referenced in multiple use contexts then we need a
  // predicate to confirm they are the same operand. We can elide this if it's
  // also referenced in a def context and we're traversing the def-use chain
  // from the def to the uses but we can't know which direction we're going
  // until after reorientToRoots().
  for (const auto &NameAndUses : NamedEdgeUses) {
    const auto &Uses = NameAndUses.getValue();
    if (Uses.size() > 1) {
      const auto &LeadingVar = Uses.front();
      for (const auto &Var : ArrayRef<VarInfo>(Uses).drop_front()) {
        // Add a predicate for each pair until we've covered the whole
        // equivalence set. We could test the whole set in a single predicate
        // but that means we can't test any equivalence until all the MO's are
        // available which can lead to wasted work matching the DAG when this
        // predicate can already be seen to have failed.
        //
        // We have a similar problem due to the need to wait for a particular MO
        // before being able to test any of them. However, that is mitigated by
        // the order in which we build the DAG. We build from the roots outwards
        // so by using the first recorded use in all the predicates, we are
        // making the dependency on one of the earliest visited references in
        // the DAG. It's not guaranteed once the generated matcher is optimized
        // (because the factoring the common portions of rules might change the
        // visit order) but this should mean that these predicates depend on the
        // first MO to become available.
        const auto &P = MatchDag.addPredicateNode<GIMatchDagSameMOPredicate>(
            makeNameForAnonPredicate(*this));
        MatchDag.addPredicateDependency(LeadingVar.N, LeadingVar.Op, P,
                                        &P->getOperandInfo()["mi0"]);
        MatchDag.addPredicateDependency(Var.N, Var.Op, P,
                                        &P->getOperandInfo()["mi1"]);
      }
    }
  }
  return true;
}

class GICombinerEmitter {
  StringRef Name;
  const CodeGenTarget &Target;
  Record *Combiner;
  std::vector<std::unique_ptr<CombineRule>> Rules;
  GIMatchDagContext MatchDagCtx;

  std::unique_ptr<CombineRule> makeCombineRule(const Record &R);

  void gatherRules(std::vector<std::unique_ptr<CombineRule>> &ActiveRules,
                   const std::vector<Record *> &&RulesAndGroups);

public:
  explicit GICombinerEmitter(RecordKeeper &RK, const CodeGenTarget &Target,
                             StringRef Name, Record *Combiner);
  ~GICombinerEmitter() {}

  StringRef getClassName() const {
    return Combiner->getValueAsString("Classname");
  }
  void run(raw_ostream &OS);

  /// Emit the name matcher (guarded by #ifndef NDEBUG) used to disable rules in
  /// response to the generated cl::opt.
  void emitNameMatcher(raw_ostream &OS) const;
  void generateCodeForRule(raw_ostream &OS, const CombineRule *Rule,
                           StringRef Indent) const;
};

GICombinerEmitter::GICombinerEmitter(RecordKeeper &RK,
                                     const CodeGenTarget &Target,
                                     StringRef Name, Record *Combiner)
    : Name(Name), Target(Target), Combiner(Combiner) {}

void GICombinerEmitter::emitNameMatcher(raw_ostream &OS) const {
  std::vector<std::pair<std::string, std::string>> Cases;
  Cases.reserve(Rules.size());

  for (const CombineRule &EnumeratedRule : make_pointee_range(Rules)) {
    std::string Code;
    raw_string_ostream SS(Code);
    SS << "return " << EnumeratedRule.getID() << ";\n";
    Cases.push_back(std::make_pair(EnumeratedRule.getName(), SS.str()));
  }

  OS << "static Optional<uint64_t> getRuleIdxForIdentifier(StringRef "
        "RuleIdentifier) {\n"
     << "  uint64_t I;\n"
     << "  // getAtInteger(...) returns false on success\n"
     << "  bool Parsed = !RuleIdentifier.getAsInteger(0, I);\n"
     << "  if (Parsed)\n"
     << "    return I;\n\n"
     << "#ifndef NDEBUG\n";
  StringMatcher Matcher("RuleIdentifier", Cases, OS);
  Matcher.Emit();
  OS << "#endif // ifndef NDEBUG\n\n"
     << "  return None;\n"
     << "}\n";
}

std::unique_ptr<CombineRule>
GICombinerEmitter::makeCombineRule(const Record &TheDef) {
  std::unique_ptr<CombineRule> Rule =
      std::make_unique<CombineRule>(Target, MatchDagCtx, NumPatternTotal, TheDef);

  if (!Rule->parseDefs())
    return nullptr;
  if (!Rule->parseMatcher(Target))
    return nullptr;
  LLVM_DEBUG({
    dbgs() << "Parsed rule defs/match for '" << Rule->getName() << "'\n";
    Rule->getMatchDag().dump();
    Rule->getMatchDag().writeDOTGraph(dbgs(), Rule->getName());
  });
  if (StopAfterParse)
    return Rule;

  // For now, don't support multi-root rules. We'll come back to this later
  // once we have the algorithm changes to support it.
  if (Rule->getNumRoots() > 1) {
    PrintError(TheDef.getLoc(), "Multi-root matches are not supported (yet)");
    return nullptr;
  }
  return Rule;
}

/// Recurse into GICombineGroup's and flatten the ruleset into a simple list.
void GICombinerEmitter::gatherRules(
    std::vector<std::unique_ptr<CombineRule>> &ActiveRules,
    const std::vector<Record *> &&RulesAndGroups) {
  for (Record *R : RulesAndGroups) {
    if (R->isValueUnset("Rules")) {
      std::unique_ptr<CombineRule> Rule = makeCombineRule(*R);
      if (Rule == nullptr) {
        PrintError(R->getLoc(), "Failed to parse rule");
        continue;
      }
      ActiveRules.emplace_back(std::move(Rule));
      ++NumPatternTotal;
    } else
      gatherRules(ActiveRules, R->getValueAsListOfDefs("Rules"));
  }
}

void GICombinerEmitter::generateCodeForRule(raw_ostream &OS,
                                            const CombineRule *Rule,
                                            StringRef Indent) const {
  {
    const Record &RuleDef = Rule->getDef();

    OS << Indent << "// Rule: " << RuleDef.getName() << "\n"
       << Indent << "if (!isRuleDisabled(" << Rule->getID() << ")) {\n";

    CodeExpansions Expansions;
    for (const RootInfo &Root : Rule->roots()) {
      Expansions.declare(Root.getPatternSymbol(), "MI");
    }
    DagInit *Applyer = RuleDef.getValueAsDag("Apply");
    if (Applyer->getOperatorAsDef(RuleDef.getLoc())->getName() !=
        "apply") {
      PrintError(RuleDef.getLoc(), "Expected apply operator");
      return;
    }

    OS << Indent << "  if (1\n";

    if (Rule->getMatchingFixupCode() &&
        !Rule->getMatchingFixupCode()->getValue().empty()) {
      // FIXME: Single-use lambda's like this are a serious compile-time
      // performance and memory issue. It's convenient for this early stage to
      // defer some work to successive patches but we need to eliminate this
      // before the ruleset grows to small-moderate size. Last time, it became
      // a big problem for low-mem systems around the 500 rule mark but by the
      // time we grow that large we should have merged the ISel match table
      // mechanism with the Combiner.
      OS << Indent << "      && [&]() {\n"
         << Indent << "      "
         << CodeExpander(Rule->getMatchingFixupCode()->getValue(), Expansions,
                         Rule->getMatchingFixupCode()->getLoc(), ShowExpansions)
         << "\n"
         << Indent << "      return true;\n"
         << Indent << "  }()";
    }
    OS << ") {\n" << Indent << "   ";

    if (const CodeInit *Code = dyn_cast<CodeInit>(Applyer->getArg(0))) {
      OS << CodeExpander(Code->getAsUnquotedString(), Expansions,
                         Code->getLoc(), ShowExpansions)
         << "\n"
         << Indent << "    return true;\n"
         << Indent << "  }\n";
    } else {
      PrintError(RuleDef.getLoc(), "Expected apply code block");
      return;
    }

    OS << Indent << "}\n";
  }
}

void GICombinerEmitter::run(raw_ostream &OS) {
  gatherRules(Rules, Combiner->getValueAsListOfDefs("Rules"));
  if (StopAfterParse) {
    MatchDagCtx.print(errs());
    PrintNote(Combiner->getLoc(),
              "Terminating due to -gicombiner-stop-after-parse");
    return;
  }
  if (ErrorsPrinted)
    PrintFatalError(Combiner->getLoc(), "Failed to parse one or more rules");

  NamedRegionTimer T("Emit", "Time spent emitting the combiner",
                     "Code Generation", "Time spent generating code",
                     TimeRegions);
  OS << "#ifdef " << Name.upper() << "_GENCOMBINERHELPER_DEPS\n"
     << "#include \"llvm/ADT/SparseBitVector.h\"\n"
     << "namespace llvm {\n"
     << "extern cl::OptionCategory GICombinerOptionCategory;\n"
     << "} // end namespace llvm\n"
     << "#endif // ifdef " << Name.upper() << "_GENCOMBINERHELPER_DEPS\n\n";

  OS << "#ifdef " << Name.upper() << "_GENCOMBINERHELPER_H\n"
     << "class " << getClassName() << " {\n"
     << "  SparseBitVector<> DisabledRules;\n"
     << "\n"
     << "public:\n"
     << "  bool parseCommandLineOption();\n"
     << "  bool isRuleDisabled(unsigned ID) const;\n"
     << "  bool setRuleDisabled(StringRef RuleIdentifier);\n"
     << "\n"
     << "  bool tryCombineAll(\n"
     << "    GISelChangeObserver &Observer,\n"
     << "    MachineInstr &MI,\n"
     << "    MachineIRBuilder &B) const;\n"
     << "};\n\n";

  emitNameMatcher(OS);

  OS << "bool " << getClassName()
     << "::setRuleDisabled(StringRef RuleIdentifier) {\n"
     << "  std::pair<StringRef, StringRef> RangePair = "
        "RuleIdentifier.split('-');\n"
     << "  if (!RangePair.second.empty()) {\n"
     << "    const auto First = getRuleIdxForIdentifier(RangePair.first);\n"
     << "    const auto Last = getRuleIdxForIdentifier(RangePair.second);\n"
     << "    if (!First.hasValue() || !Last.hasValue())\n"
     << "      return false;\n"
     << "    if (First >= Last)\n"
     << "      report_fatal_error(\"Beginning of range should be before end of "
        "range\");\n"
     << "    for (auto I = First.getValue(); I < Last.getValue(); ++I)\n"
     << "      DisabledRules.set(I);\n"
     << "    return true;\n"
     << "  } else {\n"
     << "    const auto I = getRuleIdxForIdentifier(RangePair.first);\n"
     << "    if (!I.hasValue())\n"
     << "      return false;\n"
     << "    DisabledRules.set(I.getValue());\n"
     << "    return true;\n"
     << "  }\n"
     << "  return false;\n"
     << "}\n";

  OS << "bool " << getClassName()
     << "::isRuleDisabled(unsigned RuleID) const {\n"
     << "  return DisabledRules.test(RuleID);\n"
     << "}\n";
  OS << "#endif // ifdef " << Name.upper() << "_GENCOMBINERHELPER_H\n\n";

  OS << "#ifdef " << Name.upper() << "_GENCOMBINERHELPER_CPP\n"
     << "\n"
     << "cl::list<std::string> " << Name << "Option(\n"
     << "    \"" << Name.lower() << "-disable-rule\",\n"
     << "    cl::desc(\"Disable one or more combiner rules temporarily in "
     << "the " << Name << " pass\"),\n"
     << "    cl::CommaSeparated,\n"
     << "    cl::Hidden,\n"
     << "    cl::cat(GICombinerOptionCategory));\n"
     << "\n"
     << "bool " << getClassName() << "::parseCommandLineOption() {\n"
     << "  for (const auto &Identifier : " << Name << "Option)\n"
     << "    if (!setRuleDisabled(Identifier))\n"
     << "      return false;\n"
     << "  return true;\n"
     << "}\n\n";

  OS << "bool " << getClassName() << "::tryCombineAll(\n"
     << "    GISelChangeObserver &Observer,\n"
     << "    MachineInstr &MI,\n"
     << "    MachineIRBuilder &B) const {\n"
     << "  CombinerHelper Helper(Observer, B);\n"
     << "  MachineBasicBlock *MBB = MI.getParent();\n"
     << "  MachineFunction *MF = MBB->getParent();\n"
     << "  MachineRegisterInfo &MRI = MF->getRegInfo();\n"
     << "  (void)MBB; (void)MF; (void)MRI;\n\n";

  for (const auto &Rule : Rules)
    generateCodeForRule(OS, Rule.get(), "  ");
  OS << "\n  return false;\n"
     << "}\n"
     << "#endif // ifdef " << Name.upper() << "_GENCOMBINERHELPER_CPP\n";
}

} // end anonymous namespace

//===----------------------------------------------------------------------===//

namespace llvm {
void EmitGICombiner(RecordKeeper &RK, raw_ostream &OS) {
  CodeGenTarget Target(RK);
  emitSourceFileHeader("Global Combiner", OS);

  if (SelectedCombiners.empty())
    PrintFatalError("No combiners selected with -combiners");
  for (const auto &Combiner : SelectedCombiners) {
    Record *CombinerDef = RK.getDef(Combiner);
    if (!CombinerDef)
      PrintFatalError("Could not find " + Combiner);
    GICombinerEmitter(RK, Target, Combiner, CombinerDef).run(OS);
  }
  NumPatternTotalStatistic = NumPatternTotal;
}

} // namespace llvm
