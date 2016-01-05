; RUN: opt -S -reassociate < %s | FileCheck %s

; CHECK-LABEL: main
; CHECK: %2 = fsub
; CHECK: %3 = fsub
; CHECK: fadd fast float %3, %2
define void @main(float, float) {
wrapper_entry:
  %2 = fsub float undef, %0
  %3 = fsub float undef, %1
  %4 = call float @llvm.rsqrt.f32(float undef)
  %5 = fmul fast float undef, %4
  %6 = fmul fast float %2, %4
  %7 = fmul fast float %3, %4
  %8 = fmul fast float %5, undef
  %9 = fmul fast float %6, undef
  %10 = fmul fast float %7, undef
  %11 = fadd fast float %8, %9
  %12 = fadd fast float %11, %10
  %13 = call float @foo2(float %12, float 0.000000e+00)
  %mul36 = fmul fast float %13, 1.500000e+00
  call void @foo1(i32 4, float %mul36)
  ret void
}

declare void @foo1(i32, float)

declare float @foo2(float, float) #1

declare float @llvm.rsqrt.f32(float) #1

attributes #0 = { argmemonly nounwind }
attributes #1 = { nounwind readnone }

