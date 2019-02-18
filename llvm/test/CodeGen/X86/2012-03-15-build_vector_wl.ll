; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py

; RUN: llc < %s -mtriple=x86_64-apple-darwin -mcpu=corei7-avx -mattr=+avx | FileCheck %s
define <4 x i8> @build_vector_again(<16 x i8> %in) nounwind readnone {
; CHECK-LABEL: build_vector_again:
; CHECK:       ## %bb.0: ## %entry
; CHECK-NEXT:    vpmovzxbd {{.*#+}} xmm0 = xmm0[0],zero,zero,zero,xmm0[1],zero,zero,zero,xmm0[2],zero,zero,zero,xmm0[3],zero,zero,zero
; CHECK-NEXT:    retq
entry:
  %out = shufflevector <16 x i8> %in, <16 x i8> undef, <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  ret <4 x i8> %out
}
