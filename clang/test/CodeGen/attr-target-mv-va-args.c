// RUN: %clang_cc1 -triple x86_64-linux-gnu -emit-llvm %s -o - | FileCheck %s --check-prefix=LINUX
// RUN: %clang_cc1 -triple x86_64-windows-pc -emit-llvm %s -o - | FileCheck %s --check-prefix=WINDOWS
int __attribute__((target("sse4.2"))) foo(int i, ...) { return 0; }
int __attribute__((target("arch=sandybridge"))) foo(int i, ...);
int __attribute__((target("arch=ivybridge"))) foo(int i, ...) {return 1;}
int __attribute__((target("default"))) foo(int i, ...) { return 2; }

int bar() {
  return foo(1, 'a', 1.1) + foo(2, 2.2, "asdf");
}

// LINUX: @foo.ifunc = ifunc i32 (i32, ...), i32 (i32, ...)* ()* @foo.resolver
// LINUX: define i32 @foo.sse4.2(i32 %i, ...)
// LINUX: ret i32 0
// LINUX: define i32 @foo.arch_ivybridge(i32 %i, ...)
// LINUX: ret i32 1
// LINUX: define i32 @foo(i32 %i, ...)
// LINUX: ret i32 2
// LINUX: define i32 @bar()
// LINUX: call i32 (i32, ...) @foo.ifunc(i32 1, i32 97, double
// LINUX: call i32 (i32, ...) @foo.ifunc(i32 2, double 2.2{{[0-9Ee+]+}}, i8* getelementptr inbounds

// LINUX: define i32 (i32, ...)* @foo.resolver() comdat
// LINUX: ret i32 (i32, ...)* @foo.arch_sandybridge
// LINUX: ret i32 (i32, ...)* @foo.arch_ivybridge
// LINUX: ret i32 (i32, ...)* @foo.sse4.2
// LINUX: ret i32 (i32, ...)* @foo
// LINUX: declare i32 @foo.arch_sandybridge(i32, ...)

// WINDOWS: define dso_local i32 @foo.sse4.2(i32 %i, ...)
// WINDOWS: ret i32 0
// WINDOWS: define dso_local i32 @foo.arch_ivybridge(i32 %i, ...)
// WINDOWS: ret i32 1
// WINDOWS: define dso_local i32 @foo(i32 %i, ...)
// WINDOWS: ret i32 2
// WINDOWS: define dso_local i32 @bar()
// WINDOWS: call i32 (i32, ...) @foo.resolver(i32 1, i32 97, double
// WINDOWS: call i32 (i32, ...) @foo.resolver(i32 2, double 2.2{{[0-9Ee+]+}}, i8* getelementptr inbounds

// WINDOWS: define dso_local i32 @foo.resolver(i32, ...) comdat
// WINDOWS: musttail call i32 (i32, ...) @foo.arch_sandybridge
// WINDOWS: musttail call i32 (i32, ...) @foo.arch_ivybridge
// WINDOWS: musttail call i32 (i32, ...) @foo.sse4.2
// WINDOWS: musttail call i32 (i32, ...) @foo
// WINDOWS: declare dso_local i32 @foo.arch_sandybridge(i32, ...)
