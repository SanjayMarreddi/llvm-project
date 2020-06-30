// RUN: %clang_cc1 -D__ARM_FEATURE_BF16_SCALAR_ARITHMETIC -D__ARM_FEATURE_SVE_BF16 -triple aarch64-none-linux-gnu -target-feature +sve -target-feature +bf16 -fallow-half-arguments-and-returns -S -O1 -Werror -Wall -emit-llvm -o - %s | FileCheck %s
// RUN: %clang_cc1 -D__ARM_FEATURE_BF16_SCALAR_ARITHMETIC -D__ARM_FEATURE_SVE_BF16 -DSVE_OVERLOADED_FORMS -triple aarch64-none-linux-gnu -target-feature +sve -target-feature +bf16 -fallow-half-arguments-and-returns -S -O1 -Werror -Wall -emit-llvm -o - %s | FileCheck %s
// RUN: %clang_cc1 -D__ARM_FEATURE_BF16_SCALAR_ARITHMETIC -triple aarch64-none-linux-gnu -target-feature +sve -target-feature +bf16 -fallow-half-arguments-and-returns -fsyntax-only -verify -verify-ignore-unexpected=error -verify-ignore-unexpected=note %s

#include <arm_sve.h>

#ifdef SVE_OVERLOADED_FORMS
// A simple used,unused... macro, long enough to represent any SVE builtin.
#define SVE_ACLE_FUNC(A1,A2_UNUSED,A3,A4_UNUSED) A1##A3
#else
#define SVE_ACLE_FUNC(A1,A2,A3,A4) A1##A2##A3##A4
#endif


svbfloat16x3_t test_svset3_bf16_0(svbfloat16x3_t tuple, svbfloat16_t x)
{
  // CHECK-LABEL: test_svset3_bf16_0
  // CHECK: %[[INSERT:.*]] = call <vscale x 24 x bfloat> @llvm.aarch64.sve.tuple.set.nxv24bf16.nxv8bf16(<vscale x 24 x bfloat> %tuple, i32 0, <vscale x 8 x bfloat> %x)
  // CHECK-NEXT: ret <vscale x 24 x bfloat> %[[INSERT]]
  // expected-warning@+1 {{implicit declaration of function 'svset3_bf16'}}
  return SVE_ACLE_FUNC(svset3,_bf16,,)(tuple, 0, x);
}

svbfloat16x3_t test_svset3_bf16_1(svbfloat16x3_t tuple, svbfloat16_t x)
{
  // CHECK-LABEL: test_svset3_bf16_1
  // CHECK: %[[INSERT:.*]] = call <vscale x 24 x bfloat> @llvm.aarch64.sve.tuple.set.nxv24bf16.nxv8bf16(<vscale x 24 x bfloat> %tuple, i32 1, <vscale x 8 x bfloat> %x)
  // CHECK-NEXT: ret <vscale x 24 x bfloat> %[[INSERT]]
  // expected-warning@+1 {{implicit declaration of function 'svset3_bf16'}}
  return SVE_ACLE_FUNC(svset3,_bf16,,)(tuple, 1, x);
}

svbfloat16x3_t test_svset3_bf16_2(svbfloat16x3_t tuple, svbfloat16_t x)
{
  // CHECK-LABEL: test_svset3_bf16_2
  // CHECK: %[[INSERT:.*]] = call <vscale x 24 x bfloat> @llvm.aarch64.sve.tuple.set.nxv24bf16.nxv8bf16(<vscale x 24 x bfloat> %tuple, i32 2, <vscale x 8 x bfloat> %x)
  // CHECK-NEXT: ret <vscale x 24 x bfloat> %[[INSERT]]
  // expected-warning@+1 {{implicit declaration of function 'svset3_bf16'}}
  return SVE_ACLE_FUNC(svset3,_bf16,,)(tuple, 2, x);
}
