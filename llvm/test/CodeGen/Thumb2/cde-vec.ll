; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc -mtriple=thumbv8.1m.main -mattr=+cdecp0 -mattr=+cdecp1 -mattr=+mve -verify-machineinstrs -o - %s | FileCheck %s

declare <16 x i8> @llvm.arm.cde.vcx1q(i32 immarg, i32 immarg)
declare <16 x i8> @llvm.arm.cde.vcx1qa(i32 immarg, <16 x i8>, i32 immarg)
declare <16 x i8> @llvm.arm.cde.vcx2q(i32 immarg, <16 x i8>, i32 immarg)
declare <16 x i8> @llvm.arm.cde.vcx2qa(i32 immarg, <16 x i8>, <16 x i8>, i32 immarg)
declare <16 x i8> @llvm.arm.cde.vcx3q(i32 immarg, <16 x i8>, <16 x i8>, i32 immarg)
declare <16 x i8> @llvm.arm.cde.vcx3qa(i32 immarg, <16 x i8>, <16 x i8>, <16 x i8>, i32 immarg)

define arm_aapcs_vfpcc <16 x i8> @test_vcx1q_u8() {
; CHECK-LABEL: test_vcx1q_u8:
; CHECK:       @ %bb.0: @ %entry
; CHECK-NEXT:    vcx1 p0, q0, #1111
; CHECK-NEXT:    bx lr
entry:
  %0 = call <16 x i8> @llvm.arm.cde.vcx1q(i32 0, i32 1111)
  ret <16 x i8> %0
}

define arm_aapcs_vfpcc <16 x i8> @test_vcx1qa_1(<16 x i8> %acc) {
; CHECK-LABEL: test_vcx1qa_1:
; CHECK:       @ %bb.0: @ %entry
; CHECK-NEXT:    vcx1a p1, q0, #1112
; CHECK-NEXT:    bx lr
entry:
  %0 = call <16 x i8> @llvm.arm.cde.vcx1qa(i32 1, <16 x i8> %acc, i32 1112)
  ret <16 x i8> %0
}

define arm_aapcs_vfpcc <4 x i32> @test_vcx1qa_2(<4 x i32> %acc) {
; CHECK-LABEL: test_vcx1qa_2:
; CHECK:       @ %bb.0: @ %entry
; CHECK-NEXT:    vcx1a p0, q0, #1113
; CHECK-NEXT:    bx lr
entry:
  %0 = bitcast <4 x i32> %acc to <16 x i8>
  %1 = call <16 x i8> @llvm.arm.cde.vcx1qa(i32 0, <16 x i8> %0, i32 1113)
  %2 = bitcast <16 x i8> %1 to <4 x i32>
  ret <4 x i32> %2
}

define arm_aapcs_vfpcc <16 x i8> @test_vcx2q_u8(<8 x half> %n) {
; CHECK-LABEL: test_vcx2q_u8:
; CHECK:       @ %bb.0: @ %entry
; CHECK-NEXT:    vcx2 p1, q0, q0, #111
; CHECK-NEXT:    bx lr
entry:
  %0 = bitcast <8 x half> %n to <16 x i8>
  %1 = call <16 x i8> @llvm.arm.cde.vcx2q(i32 1, <16 x i8> %0, i32 111)
  ret <16 x i8> %1
}

define arm_aapcs_vfpcc <4 x float> @test_vcx2q(<4 x float> %n) {
; CHECK-LABEL: test_vcx2q:
; CHECK:       @ %bb.0: @ %entry
; CHECK-NEXT:    vcx2 p1, q0, q0, #112
; CHECK-NEXT:    bx lr
entry:
  %0 = bitcast <4 x float> %n to <16 x i8>
  %1 = call <16 x i8> @llvm.arm.cde.vcx2q(i32 1, <16 x i8> %0, i32 112)
  %2 = bitcast <16 x i8> %1 to <4 x float>
  ret <4 x float> %2
}

define arm_aapcs_vfpcc <4 x float> @test_vcx2qa(<4 x float> %acc, <2 x i64> %n) {
; CHECK-LABEL: test_vcx2qa:
; CHECK:       @ %bb.0: @ %entry
; CHECK-NEXT:    vcx2a p0, q0, q1, #113
; CHECK-NEXT:    bx lr
entry:
  %0 = bitcast <4 x float> %acc to <16 x i8>
  %1 = bitcast <2 x i64> %n to <16 x i8>
  %2 = call <16 x i8> @llvm.arm.cde.vcx2qa(i32 0, <16 x i8> %0, <16 x i8> %1, i32 113)
  %3 = bitcast <16 x i8> %2 to <4 x float>
  ret <4 x float> %3
}

define arm_aapcs_vfpcc <16 x i8> @test_vcx3q_u8(<8 x i16> %n, <4 x i32> %m) {
; CHECK-LABEL: test_vcx3q_u8:
; CHECK:       @ %bb.0: @ %entry
; CHECK-NEXT:    vcx3 p0, q0, q0, q1, #11
; CHECK-NEXT:    bx lr
entry:
  %0 = bitcast <8 x i16> %n to <16 x i8>
  %1 = bitcast <4 x i32> %m to <16 x i8>
  %2 = call <16 x i8> @llvm.arm.cde.vcx3q(i32 0, <16 x i8> %0, <16 x i8> %1, i32 11)
  ret <16 x i8> %2
}

define arm_aapcs_vfpcc <2 x i64> @test_vcx3q(<2 x i64> %n, <4 x float> %m) {
; CHECK-LABEL: test_vcx3q:
; CHECK:       @ %bb.0: @ %entry
; CHECK-NEXT:    vcx3 p1, q0, q0, q1, #12
; CHECK-NEXT:    bx lr
entry:
  %0 = bitcast <2 x i64> %n to <16 x i8>
  %1 = bitcast <4 x float> %m to <16 x i8>
  %2 = call <16 x i8> @llvm.arm.cde.vcx3q(i32 1, <16 x i8> %0, <16 x i8> %1, i32 12)
  %3 = bitcast <16 x i8> %2 to <2 x i64>
  ret <2 x i64> %3
}

define arm_aapcs_vfpcc <16 x i8> @test_vcx3qa(<16 x i8> %acc, <8 x i16> %n, <4 x float> %m) {
; CHECK-LABEL: test_vcx3qa:
; CHECK:       @ %bb.0: @ %entry
; CHECK-NEXT:    vcx3a p1, q0, q1, q2, #13
; CHECK-NEXT:    bx lr
entry:
  %0 = bitcast <8 x i16> %n to <16 x i8>
  %1 = bitcast <4 x float> %m to <16 x i8>
  %2 = call <16 x i8> @llvm.arm.cde.vcx3qa(i32 1, <16 x i8> %acc, <16 x i8> %0, <16 x i8> %1, i32 13)
  ret <16 x i8> %2
}
