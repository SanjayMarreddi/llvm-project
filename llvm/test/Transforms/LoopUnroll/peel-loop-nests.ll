; NOTE: Assertions have been autogenerated by utils/update_test_checks.py
; RUN: opt < %s -S -loop-unroll -unroll-peel-max-count=4 -verify-dom-info | FileCheck %s
; RUN: opt < %s -S -loop-unroll -unroll-peel-max-count=4 -unroll-allow-loop-nests-peeling -verify-dom-info | FileCheck %s --check-prefix PEELED

declare void @f1()
declare void @f2()

; In this case we cannot peel the inner loop, because the condition involves
; the outer induction variable.
; Peel the loop nest if allowed by the flag -unroll-allow-loop-nests-peeling.
define void @test1(i32 %k) {
; CHECK-LABEL: @test1(
; CHECK-NEXT:  for.body.lr.ph:
; CHECK-NEXT:    br label [[OUTER_HEADER:%.*]]
; CHECK:       outer.header:
; CHECK-NEXT:    [[J:%.*]] = phi i32 [ 0, [[FOR_BODY_LR_PH:%.*]] ], [ [[J_INC:%.*]], [[OUTER_INC:%.*]] ]
; CHECK-NEXT:    br label [[FOR_BODY:%.*]]
; CHECK:       for.body:
; CHECK-NEXT:    [[I_05:%.*]] = phi i32 [ 0, [[OUTER_HEADER]] ], [ [[INC:%.*]], [[FOR_INC:%.*]] ]
; CHECK-NEXT:    [[CMP1:%.*]] = icmp ult i32 [[J]], 2
; CHECK-NEXT:    br i1 [[CMP1]], label [[IF_THEN:%.*]], label [[IF_ELSE:%.*]]
; CHECK:       if.then:
; CHECK-NEXT:    call void @f1()
; CHECK-NEXT:    br label [[FOR_INC]]
; CHECK:       if.else:
; CHECK-NEXT:    call void @f2()
; CHECK-NEXT:    br label [[FOR_INC]]
; CHECK:       for.inc:
; CHECK-NEXT:    [[INC]] = add nsw i32 [[I_05]], 1
; CHECK-NEXT:    [[CMP:%.*]] = icmp slt i32 [[INC]], [[K:%.*]]
; CHECK-NEXT:    br i1 [[CMP]], label [[FOR_BODY]], label [[OUTER_INC]]
; CHECK:       outer.inc:
; CHECK-NEXT:    [[J_INC]] = add nsw i32 [[J]], 1
; CHECK-NEXT:    [[OUTER_CMP:%.*]] = icmp slt i32 [[J_INC]], [[K]]
; CHECK-NEXT:    br i1 [[OUTER_CMP]], label [[OUTER_HEADER]], label [[FOR_END:%.*]], !llvm.loop !{{.*}}
; CHECK:       for.end:
; CHECK-NEXT:    ret void
;
; PEELED-LABEL: @test1(
; PEELED-NEXT:  for.body.lr.ph:
; PEELED-NEXT:    br label [[OUTER_HEADER_PEEL_BEGIN:%.*]]
; PEELED:       outer.header.peel.begin:
; PEELED-NEXT:    br label [[OUTER_HEADER_PEEL:%.*]]
; PEELED:       outer.header.peel:
; PEELED-NEXT:    br label [[FOR_BODY_PEEL:%.*]]
; PEELED:       for.body.peel:
; PEELED-NEXT:    [[I_05_PEEL:%.*]] = phi i32 [ 0, [[OUTER_HEADER_PEEL]] ], [ [[INC_PEEL:%.*]], [[FOR_INC_PEEL:%.*]] ]
; PEELED-NEXT:    [[CMP1_PEEL:%.*]] = icmp ult i32 0, 2
; PEELED-NEXT:    br i1 [[CMP1_PEEL]], label [[IF_THEN_PEEL:%.*]], label [[IF_ELSE_PEEL:%.*]]
; PEELED:       if.else.peel:
; PEELED-NEXT:    call void @f2()
; PEELED-NEXT:    br label [[FOR_INC_PEEL]]
; PEELED:       if.then.peel:
; PEELED-NEXT:    call void @f1()
; PEELED-NEXT:    br label [[FOR_INC_PEEL]]
; PEELED:       for.inc.peel:
; PEELED-NEXT:    [[INC_PEEL]] = add nsw i32 [[I_05_PEEL]], 1
; PEELED-NEXT:    [[CMP_PEEL:%.*]] = icmp slt i32 [[INC_PEEL]], [[K:%.*]]
; PEELED-NEXT:    br i1 [[CMP_PEEL]], label [[FOR_BODY_PEEL]], label [[OUTER_INC_PEEL:%.*]]
; PEELED:       outer.inc.peel:
; PEELED-NEXT:    [[J_INC_PEEL:%.*]] = add nsw i32 0, 1
; PEELED-NEXT:    [[OUTER_CMP_PEEL:%.*]] = icmp slt i32 [[J_INC_PEEL]], [[K]]
; PEELED-NEXT:    br i1 [[OUTER_CMP_PEEL]], label [[OUTER_HEADER_PEEL_NEXT:%.*]], label [[FOR_END:%[^,]*]]
; Verify that MD_loop metadata is dropped.
; PEELED-NOT:   , !llvm.loop !{{[0-9]*}}
; PEELED:       outer.header.peel.next:
; PEELED-NEXT:    br label [[OUTER_HEADER_PEEL2:%.*]]
; PEELED:       outer.header.peel2:
; PEELED-NEXT:    br label [[FOR_BODY_PEEL3:%.*]]
; PEELED:       for.body.peel3:
; PEELED-NEXT:    [[I_05_PEEL4:%.*]] = phi i32 [ 0, [[OUTER_HEADER_PEEL2]] ], [ [[INC_PEEL9:%.*]], [[FOR_INC_PEEL8:%.*]] ]
; PEELED-NEXT:    [[CMP1_PEEL5:%.*]] = icmp ult i32 [[J_INC_PEEL]], 2
; PEELED-NEXT:    br i1 [[CMP1_PEEL5]], label [[IF_THEN_PEEL7:%.*]], label [[IF_ELSE_PEEL6:%.*]]
; PEELED:       if.else.peel6:
; PEELED-NEXT:    call void @f2()
; PEELED-NEXT:    br label [[FOR_INC_PEEL8]]
; PEELED:       if.then.peel7:
; PEELED-NEXT:    call void @f1()
; PEELED-NEXT:    br label [[FOR_INC_PEEL8]]
; PEELED:       for.inc.peel8:
; PEELED-NEXT:    [[INC_PEEL9]] = add nsw i32 [[I_05_PEEL4]], 1
; PEELED-NEXT:    [[CMP_PEEL10:%.*]] = icmp slt i32 [[INC_PEEL9]], [[K]]
; PEELED-NEXT:    br i1 [[CMP_PEEL10]], label [[FOR_BODY_PEEL3]], label [[OUTER_INC_PEEL11:%.*]]
; PEELED:       outer.inc.peel11:
; PEELED-NEXT:    [[J_INC_PEEL12:%.*]] = add nsw i32 [[J_INC_PEEL]], 1
; PEELED-NEXT:    [[OUTER_CMP_PEEL13:%.*]] = icmp slt i32 [[J_INC_PEEL12]], [[K]]
; PEELED-NEXT:    br i1 [[OUTER_CMP_PEEL13]], label [[OUTER_HEADER_PEEL_NEXT1:%.*]], label [[FOR_END]]
; Verify that MD_loop metadata is dropped.
; PEELED-NOT:   , !llvm.loop !{{[0-9]*}}
; PEELED:       outer.header.peel.next1:
; PEELED-NEXT:    br label [[OUTER_HEADER_PEEL_NEXT14:%.*]]
; PEELED:       outer.header.peel.next14:
; PEELED-NEXT:    br label [[FOR_BODY_LR_PH_PEEL_NEWPH:%.*]]
; PEELED:       for.body.lr.ph.peel.newph:
; PEELED-NEXT:    br label [[OUTER_HEADER:%.*]]
; PEELED:       outer.header:
; PEELED-NEXT:    [[J:%.*]] = phi i32 [ [[J_INC_PEEL12]], [[FOR_BODY_LR_PH_PEEL_NEWPH]] ], [ [[J_INC:%.*]], [[OUTER_INC:%.*]] ]
; PEELED-NEXT:    br label [[FOR_BODY:%.*]]
; PEELED:       for.body:
; PEELED-NEXT:    [[I_05:%.*]] = phi i32 [ 0, [[OUTER_HEADER]] ], [ [[INC:%.*]], [[FOR_INC:%.*]] ]
; PEELED-NEXT:    br i1 false, label [[IF_THEN:%.*]], label [[IF_ELSE:%.*]]
; PEELED:       if.then:
; PEELED-NEXT:    call void @f1()
; PEELED-NEXT:    br label [[FOR_INC]]
; PEELED:       if.else:
; PEELED-NEXT:    call void @f2()
; PEELED-NEXT:    br label [[FOR_INC]]
; PEELED:       for.inc:
; PEELED-NEXT:    [[INC]] = add nsw i32 [[I_05]], 1
; PEELED-NEXT:    [[CMP:%.*]] = icmp slt i32 [[INC]], [[K]]
; PEELED-NEXT:    br i1 [[CMP]], label [[FOR_BODY]], label [[OUTER_INC]]
; PEELED:       outer.inc:
; PEELED-NEXT:    [[J_INC]] = add nuw nsw i32 [[J]], 1
; PEELED-NEXT:    [[OUTER_CMP:%.*]] = icmp slt i32 [[J_INC]], [[K]]
; PEELED-NEXT:    br i1 [[OUTER_CMP]], label [[OUTER_HEADER]], label [[FOR_END_LOOPEXIT:%.*]], !llvm.loop !{{.*}}
; PEELED:       for.end.loopexit:
; PEELED-NEXT:    br label [[FOR_END]]
; PEELED:       for.end:
; PEELED-NEXT:    ret void
;
for.body.lr.ph:
  br label %outer.header

outer.header:
  %j = phi i32 [ 0, %for.body.lr.ph ], [ %j.inc, %outer.inc ]
  br label %for.body

for.body:
  %i.05 = phi i32 [ 0, %outer.header ], [ %inc, %for.inc ]
  %cmp1 = icmp ult i32 %j, 2
  br i1 %cmp1, label %if.then, label %if.else

if.then:
  call void @f1()
  br label %for.inc

if.else:
  call void @f2()
  br label %for.inc

for.inc:
  %inc = add nsw i32 %i.05, 1
  %cmp = icmp slt i32 %inc, %k
  br i1 %cmp, label %for.body, label %outer.inc

outer.inc:
  %j.inc = add nsw i32 %j, 1
  %outer.cmp = icmp slt i32 %j.inc, %k
  br i1 %outer.cmp, label %outer.header, label %for.end, !llvm.loop !0

for.end:
  ret void
}

!0 = distinct !{!0}