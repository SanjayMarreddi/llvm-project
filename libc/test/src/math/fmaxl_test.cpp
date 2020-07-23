//===-- Unittests for fmaxl -----------------------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===---------------------------------------------------------------------===//

#include "include/math.h"
#include "src/math/fmaxl.h"
#include "utils/FPUtil/FPBits.h"
#include "utils/UnitTest/Test.h"

using FPBits = __llvm_libc::fputil::FPBits<long double>;

long double nan = FPBits::buildNaN(1);
long double inf = FPBits::inf();
long double negInf = FPBits::negInf();

TEST(FmaxlTest, NaNArg) {
  EXPECT_EQ(inf, __llvm_libc::fmaxl(nan, inf));
  EXPECT_EQ(negInf, __llvm_libc::fmaxl(negInf, nan));
  EXPECT_EQ(0.0L, __llvm_libc::fmaxl(nan, 0.0L));
  EXPECT_EQ(-0.0L, __llvm_libc::fmaxl(-0.0L, nan));
  EXPECT_EQ(-1.2345L, __llvm_libc::fmaxl(nan, -1.2345L));
  EXPECT_EQ(1.2345L, __llvm_libc::fmaxl(1.2345L, nan));
  EXPECT_NE(isnan(__llvm_libc::fmaxl(nan, nan)), 0);
}

TEST(FmaxlTest, InfArg) {
  EXPECT_EQ(inf, __llvm_libc::fmaxl(negInf, inf));
  EXPECT_EQ(inf, __llvm_libc::fmaxl(inf, 0.0L));
  EXPECT_EQ(inf, __llvm_libc::fmaxl(-0.0L, inf));
  EXPECT_EQ(inf, __llvm_libc::fmaxl(inf, 1.2345L));
  EXPECT_EQ(inf, __llvm_libc::fmaxl(-1.2345L, inf));
}

TEST(FmaxlTest, NegInfArg) {
  EXPECT_EQ(inf, __llvm_libc::fmaxl(inf, negInf));
  EXPECT_EQ(0.0L, __llvm_libc::fmaxl(negInf, 0.0L));
  EXPECT_EQ(-0.0L, __llvm_libc::fmaxl(-0.0L, negInf));
  EXPECT_EQ(-1.2345L, __llvm_libc::fmaxl(negInf, -1.2345L));
  EXPECT_EQ(1.2345L, __llvm_libc::fmaxl(1.2345L, negInf));
}

TEST(FmaxlTest, BothZero) {
  EXPECT_EQ(0.0L, __llvm_libc::fmaxl(0.0L, 0.0L));
  EXPECT_EQ(0.0L, __llvm_libc::fmaxl(-0.0L, 0.0L));
  EXPECT_EQ(0.0L, __llvm_libc::fmaxl(0.0L, -0.0L));
  EXPECT_EQ(-0.0L, __llvm_libc::fmaxl(-0.0L, -0.0L));
}

TEST(FmaxlTest, InLongDoubleRange) {
  using UIntType = FPBits::UIntType;
  constexpr UIntType count = 10000001;
  constexpr UIntType step = UIntType(-1) / count;
  for (UIntType i = 0, v = 0, w = UIntType(-1); i <= count;
       ++i, v += step, w -= step) {
    long double x = FPBits(v), y = FPBits(w);
    if (isnan(x) || isinf(x))
      continue;
    if (isnan(y) || isinf(y))
      continue;
    if ((x == 0) && (y == 0))
      continue;

    if (x > y) {
      ASSERT_EQ(x, __llvm_libc::fmaxl(x, y));
    } else {
      ASSERT_EQ(y, __llvm_libc::fmaxl(x, y));
    }
  }
}
