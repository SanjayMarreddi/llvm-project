; NOTE: Assertions have been autogenerated by utils/update_test_checks.py
; RUN: opt -S -basic-aa -licm < %s | FileCheck %s
; RUN: opt -aa-pipeline=basic-aa -passes='require<opt-remark-emit>,loop(licm)' -S %s | FileCheck %s

; Make sure we don't hoist the unsafe division to some executable block.
define void @test_impossible_exit_in_untaken_block(i32 %a, i32 %b, i32* %p) {
; CHECK-LABEL: @test_impossible_exit_in_untaken_block(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    br label [[LOOP:%.*]]
; CHECK:       loop:
; CHECK-NEXT:    [[IV:%.*]] = phi i32 [ 0, [[ENTRY:%.*]] ], [ [[IV_NEXT:%.*]], [[BACKEDGE:%.*]] ]
; CHECK-NEXT:    br i1 false, label [[NEVER_TAKEN:%.*]], label [[BACKEDGE]]
; CHECK:       never_taken:
; CHECK-NEXT:    [[DIV:%.*]] = sdiv i32 [[A:%.*]], [[B:%.*]]
; CHECK-NEXT:    store i32 [[DIV]], i32* [[P:%.*]]
; CHECK-NEXT:    br i1 true, label [[BACKEDGE]], label [[EXIT:%.*]]
; CHECK:       backedge:
; CHECK-NEXT:    [[IV_NEXT]] = add i32 [[IV]], 1
; CHECK-NEXT:    br label [[LOOP]]
; CHECK:       exit:
; CHECK-NEXT:    ret void
;
entry:
  br label %loop

loop:
  %iv = phi i32 [ 0, %entry ], [ %iv.next, %backedge ]
  br i1 false, label %never_taken, label %backedge

never_taken:
  %div = sdiv i32 %a, %b
  store i32 %div, i32* %p
  br i1 true, label %backedge, label %exit

backedge:
  %iv.next = add i32 %iv, 1
  br label %loop

exit:
  ret void
}

; The test above is UB in C++, because there is a requirement that any
; thead should eventually terminate, execute volatile access operation, call IO
; or synchronize. In spite of that, the behavior in the test above *might* be
; correct. This one is equivalent to the test above, but it has a volatile
; memory access in the loop's mustexec block, so the compiler no longer has a
; right to assume that it must terminate. Show that the same problem persists,
; and that it was a bug and not a cool optimization based on loop infinity.
; By the moment when this test was added, it was accidentally correct due to
; reasons not directly related to this piece of logic. Make sure that it keeps
; correct in the future.
define void @test_impossible_exit_in_untaken_block_no_ub(i32 %a, i32 %b, i32* noalias %p, i32* noalias %vp) {
; CHECK-LABEL: @test_impossible_exit_in_untaken_block_no_ub(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    br label [[LOOP:%.*]]
; CHECK:       loop:
; CHECK-NEXT:    [[IV:%.*]] = phi i32 [ 0, [[ENTRY:%.*]] ], [ [[IV_NEXT:%.*]], [[BACKEDGE:%.*]] ]
; CHECK-NEXT:    [[TMP0:%.*]] = load volatile i32, i32* [[VP:%.*]]
; CHECK-NEXT:    br i1 false, label [[NEVER_TAKEN:%.*]], label [[BACKEDGE]]
; CHECK:       never_taken:
; CHECK-NEXT:    [[DIV:%.*]] = sdiv i32 [[A:%.*]], [[B:%.*]]
; CHECK-NEXT:    store i32 [[DIV]], i32* [[P:%.*]]
; CHECK-NEXT:    br i1 true, label [[BACKEDGE]], label [[EXIT:%.*]]
; CHECK:       backedge:
; CHECK-NEXT:    [[IV_NEXT]] = add i32 [[IV]], 1
; CHECK-NEXT:    br label [[LOOP]]
; CHECK:       exit:
; CHECK-NEXT:    ret void
;
entry:
  br label %loop

loop:
  %iv = phi i32 [ 0, %entry ], [ %iv.next, %backedge ]
  load volatile i32, i32* %vp
  br i1 false, label %never_taken, label %backedge

never_taken:
  %div = sdiv i32 %a, %b
  store i32 %div, i32* %p
  br i1 true, label %backedge, label %exit

backedge:
  %iv.next = add i32 %iv, 1
  br label %loop

exit:
  ret void
}

; Same as above, but the volatile access is in mustexecute backedge block. The
; loop is no longer "finite by specification", make sure we don't hoist sdiv
; from it no matter how general the MustThrow analysis is.
define void @test_impossible_exit_in_untaken_block_no_ub_2(i32 %a, i32 %b, i32* noalias %p, i32* noalias %vp) {
; CHECK-LABEL: @test_impossible_exit_in_untaken_block_no_ub_2(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    br label [[LOOP:%.*]]
; CHECK:       loop:
; CHECK-NEXT:    [[IV:%.*]] = phi i32 [ 0, [[ENTRY:%.*]] ], [ [[IV_NEXT:%.*]], [[BACKEDGE:%.*]] ]
; CHECK-NEXT:    br i1 false, label [[NEVER_TAKEN:%.*]], label [[BACKEDGE]]
; CHECK:       never_taken:
; CHECK-NEXT:    [[DIV:%.*]] = sdiv i32 [[A:%.*]], [[B:%.*]]
; CHECK-NEXT:    store i32 [[DIV]], i32* [[P:%.*]]
; CHECK-NEXT:    br i1 true, label [[BACKEDGE]], label [[EXIT:%.*]]
; CHECK:       backedge:
; CHECK-NEXT:    [[IV_NEXT]] = add i32 [[IV]], 1
; CHECK-NEXT:    [[TMP0:%.*]] = load volatile i32, i32* [[VP:%.*]]
; CHECK-NEXT:    br label [[LOOP]]
; CHECK:       exit:
; CHECK-NEXT:    ret void
;
entry:
  br label %loop

loop:
  %iv = phi i32 [ 0, %entry ], [ %iv.next, %backedge ]
  br i1 false, label %never_taken, label %backedge

never_taken:
  %div = sdiv i32 %a, %b
  store i32 %div, i32* %p
  br i1 true, label %backedge, label %exit

backedge:
  %iv.next = add i32 %iv, 1
  load volatile i32, i32* %vp
  br label %loop

exit:
  ret void
}
