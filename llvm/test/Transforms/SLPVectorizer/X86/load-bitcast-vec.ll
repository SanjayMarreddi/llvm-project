; NOTE: Assertions have been autogenerated by utils/update_test_checks.py
; RUN: opt < %s -slp-vectorizer -S -mtriple=x86_64-- -mattr=+avx  | FileCheck %s
; RUN: opt < %s -slp-vectorizer -S -mtriple=x86_64-- -mattr=+avx2 | FileCheck %s

define float @matching_scalar(<4 x float>* dereferenceable(16) %p) {
; CHECK-LABEL: @matching_scalar(
; CHECK-NEXT:    [[BC:%.*]] = bitcast <4 x float>* [[P:%.*]] to float*
; CHECK-NEXT:    [[R:%.*]] = load float, float* [[BC]], align 16
; CHECK-NEXT:    ret float [[R]]
;
  %bc = bitcast <4 x float>* %p to float*
  %r = load float, float* %bc, align 16
  ret float %r
}

define i32 @nonmatching_scalar(<4 x float>* dereferenceable(16) %p) {
; CHECK-LABEL: @nonmatching_scalar(
; CHECK-NEXT:    [[BC:%.*]] = bitcast <4 x float>* [[P:%.*]] to i32*
; CHECK-NEXT:    [[R:%.*]] = load i32, i32* [[BC]], align 16
; CHECK-NEXT:    ret i32 [[R]]
;
  %bc = bitcast <4 x float>* %p to i32*
  %r = load i32, i32* %bc, align 16
  ret i32 %r
}

define i64 @larger_scalar(<4 x float>* dereferenceable(16) %p) {
; CHECK-LABEL: @larger_scalar(
; CHECK-NEXT:    [[BC:%.*]] = bitcast <4 x float>* [[P:%.*]] to i64*
; CHECK-NEXT:    [[R:%.*]] = load i64, i64* [[BC]], align 16
; CHECK-NEXT:    ret i64 [[R]]
;
  %bc = bitcast <4 x float>* %p to i64*
  %r = load i64, i64* %bc, align 16
  ret i64 %r
}

define i8 @smaller_scalar(<4 x float>* dereferenceable(16) %p) {
; CHECK-LABEL: @smaller_scalar(
; CHECK-NEXT:    [[BC:%.*]] = bitcast <4 x float>* [[P:%.*]] to i8*
; CHECK-NEXT:    [[R:%.*]] = load i8, i8* [[BC]], align 16
; CHECK-NEXT:    ret i8 [[R]]
;
  %bc = bitcast <4 x float>* %p to i8*
  %r = load i8, i8* %bc, align 16
  ret i8 %r
}

define i8 @smaller_scalar_256bit_vec(<8 x float>* dereferenceable(32) %p) {
; CHECK-LABEL: @smaller_scalar_256bit_vec(
; CHECK-NEXT:    [[BC:%.*]] = bitcast <8 x float>* [[P:%.*]] to i8*
; CHECK-NEXT:    [[R:%.*]] = load i8, i8* [[BC]], align 32
; CHECK-NEXT:    ret i8 [[R]]
;
  %bc = bitcast <8 x float>* %p to i8*
  %r = load i8, i8* %bc, align 32
  ret i8 %r
}

define i8 @smaller_scalar_less_aligned(<4 x float>* dereferenceable(16) %p) {
; CHECK-LABEL: @smaller_scalar_less_aligned(
; CHECK-NEXT:    [[BC:%.*]] = bitcast <4 x float>* [[P:%.*]] to i8*
; CHECK-NEXT:    [[R:%.*]] = load i8, i8* [[BC]], align 4
; CHECK-NEXT:    ret i8 [[R]]
;
  %bc = bitcast <4 x float>* %p to i8*
  %r = load i8, i8* %bc, align 4
  ret i8 %r
}

define float @matching_scalar_small_deref(<4 x float>* dereferenceable(15) %p) {
; CHECK-LABEL: @matching_scalar_small_deref(
; CHECK-NEXT:    [[BC:%.*]] = bitcast <4 x float>* [[P:%.*]] to float*
; CHECK-NEXT:    [[R:%.*]] = load float, float* [[BC]], align 16
; CHECK-NEXT:    ret float [[R]]
;
  %bc = bitcast <4 x float>* %p to float*
  %r = load float, float* %bc, align 16
  ret float %r
}

define float @matching_scalar_volatile(<4 x float>* dereferenceable(16) %p) {
; CHECK-LABEL: @matching_scalar_volatile(
; CHECK-NEXT:    [[BC:%.*]] = bitcast <4 x float>* [[P:%.*]] to float*
; CHECK-NEXT:    [[R:%.*]] = load volatile float, float* [[BC]], align 16
; CHECK-NEXT:    ret float [[R]]
;
  %bc = bitcast <4 x float>* %p to float*
  %r = load volatile float, float* %bc, align 16
  ret float %r
}

define float @nonvector(double* dereferenceable(16) %p) {
; CHECK-LABEL: @nonvector(
; CHECK-NEXT:    [[BC:%.*]] = bitcast double* [[P:%.*]] to float*
; CHECK-NEXT:    [[R:%.*]] = load float, float* [[BC]], align 16
; CHECK-NEXT:    ret float [[R]]
;
  %bc = bitcast double* %p to float*
  %r = load float, float* %bc, align 16
  ret float %r
}
