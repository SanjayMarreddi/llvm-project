; NOTE: Assertions have been autogenerated by utils/update_test_checks.py
; RUN: opt -S -codegenprepare -mtriple=amdgcn--amdhsa < %s | FileCheck %s

define amdgpu_kernel void @test_sink_as999_small_max_mubuf_offset(i32 addrspace(999)* %out, i8 addrspace(999)* %in) {
; CHECK-LABEL: @test_sink_as999_small_max_mubuf_offset(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[OUT_GEP:%.*]] = getelementptr i32, i32 addrspace(999)* [[OUT:%.*]], i32 1024
; CHECK-NEXT:    [[IN_GEP:%.*]] = getelementptr i8, i8 addrspace(999)* [[IN:%.*]], i64 4095
; CHECK-NEXT:    [[TID:%.*]] = call i32 @llvm.amdgcn.mbcnt.lo(i32 -1, i32 0) #1
; CHECK-NEXT:    [[TMP0:%.*]] = icmp eq i32 [[TID]], 0
; CHECK-NEXT:    br i1 [[TMP0]], label [[ENDIF:%.*]], label [[IF:%.*]]
; CHECK:       if:
; CHECK-NEXT:    [[TMP1:%.*]] = load i8, i8 addrspace(999)* [[IN_GEP]], align 1
; CHECK-NEXT:    [[TMP2:%.*]] = sext i8 [[TMP1]] to i32
; CHECK-NEXT:    br label [[ENDIF]]
; CHECK:       endif:
; CHECK-NEXT:    [[X:%.*]] = phi i32 [ [[TMP2]], [[IF]] ], [ 0, [[ENTRY:%.*]] ]
; CHECK-NEXT:    store i32 [[X]], i32 addrspace(999)* [[OUT_GEP]], align 4
; CHECK-NEXT:    br label [[DONE:%.*]]
; CHECK:       done:
; CHECK-NEXT:    ret void
;
entry:
  %out.gep = getelementptr i32, i32 addrspace(999)* %out, i32 1024
  %in.gep = getelementptr i8, i8 addrspace(999)* %in, i64 4095
  %tid = call i32 @llvm.amdgcn.mbcnt.lo(i32 -1, i32 0) #0
  %tmp0 = icmp eq i32 %tid, 0
  br i1 %tmp0, label %endif, label %if

if:
  %tmp1 = load i8, i8 addrspace(999)* %in.gep
  %tmp2 = sext i8 %tmp1 to i32
  br label %endif

endif:
  %x = phi i32 [ %tmp2, %if ], [ 0, %entry ]
  store i32 %x, i32 addrspace(999)* %out.gep
  br label %done

done:
  ret void
}

declare i32 @llvm.amdgcn.mbcnt.lo(i32, i32) #0

attributes #0 = { nounwind readnone }
attributes #1 = { nounwind }
attributes #2 = { nounwind argmemonly }
