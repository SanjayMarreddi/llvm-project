; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc -verify-machineinstrs -mtriple=powerpc64le-unknown-linux-gnu \
; RUN:   -mcpu=pwr10 -ppc-asm-full-reg-names \
; RUN:   -ppc-vsr-nums-as-vr < %s | FileCheck %s
; RUN: llc -verify-machineinstrs -mtriple=powerpc64-unknown-linux-gnu \
; RUN:   -mcpu=pwr10 -ppc-asm-full-reg-names \
; RUN:   -ppc-vsr-nums-as-vr < %s | FileCheck %s --check-prefix=CHECK-BE

; assemble_acc
declare <512 x i1> @llvm.ppc.mma.assemble.acc(<16 x i8>, <16 x i8>, <16 x i8>, <16 x i8>)
define void @ass_acc(<512 x i1>* %ptr, <16 x i8> %vc) {
; CHECK-LABEL: ass_acc:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    vmr v3, v2
; CHECK-NEXT:    xxlor vs0, v2, v2
; CHECK-NEXT:    xxlor vs1, v3, v3
; CHECK-NEXT:    xxlor vs2, v2, v2
; CHECK-NEXT:    xxlor vs3, v3, v3
; CHECK-NEXT:    stxv vs0, 48(r3)
; CHECK-NEXT:    stxv vs1, 32(r3)
; CHECK-NEXT:    stxv vs2, 16(r3)
; CHECK-NEXT:    stxv vs3, 0(r3)
; CHECK-NEXT:    blr
;
; CHECK-BE-LABEL: ass_acc:
; CHECK-BE:       # %bb.0: # %entry
; CHECK-BE-NEXT:    vmr v3, v2
; CHECK-BE-NEXT:    xxlor vs0, v2, v2
; CHECK-BE-NEXT:    xxlor vs1, v3, v3
; CHECK-BE-NEXT:    xxlor vs2, v2, v2
; CHECK-BE-NEXT:    xxlor vs3, v3, v3
; CHECK-BE-NEXT:    stxv vs1, 16(r3)
; CHECK-BE-NEXT:    stxv vs0, 0(r3)
; CHECK-BE-NEXT:    stxv vs3, 48(r3)
; CHECK-BE-NEXT:    stxv vs2, 32(r3)
; CHECK-BE-NEXT:    blr
entry:
  %0 = tail call <512 x i1> @llvm.ppc.mma.assemble.acc(<16 x i8> %vc, <16 x i8> %vc, <16 x i8> %vc, <16 x i8> %vc)
  store <512 x i1> %0, <512 x i1>* %ptr, align 64
  ret void
}

; assemble_pair
declare <256 x i1> @llvm.ppc.mma.assemble.pair(<16 x i8>, <16 x i8>)
define void @ass_pair(<256 x i1>* %ptr, <16 x i8> %vc) {
; CHECK-LABEL: ass_pair:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    vmr v3, v2
; CHECK-NEXT:    stxv v2, 16(r3)
; CHECK-NEXT:    stxv v3, 0(r3)
; CHECK-NEXT:    blr
;
; CHECK-BE-LABEL: ass_pair:
; CHECK-BE:       # %bb.0: # %entry
; CHECK-BE-NEXT:    vmr v3, v2
; CHECK-BE-NEXT:    stxv v2, 16(r3)
; CHECK-BE-NEXT:    stxv v2, 0(r3)
; CHECK-BE-NEXT:    blr
entry:
  %0 = tail call <256 x i1> @llvm.ppc.mma.assemble.pair(<16 x i8> %vc, <16 x i8> %vc)
  store <256 x i1> %0, <256 x i1>* %ptr, align 32
  ret void
}

; xxmtacc
declare <512 x i1> @llvm.ppc.mma.xxmtacc(<512 x i1>)
define void @int_xxmtacc(<512 x i1>* %ptr, <16 x i8> %vc) {
; CHECK-LABEL: int_xxmtacc:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    vmr v3, v2
; CHECK-NEXT:    xxlor vs0, v2, v2
; CHECK-NEXT:    xxlor vs1, v3, v3
; CHECK-NEXT:    xxlor vs2, v2, v2
; CHECK-NEXT:    xxlor vs3, v3, v3
; CHECK-NEXT:    xxmtacc acc0
; CHECK-NEXT:    stxv vs0, 48(r3)
; CHECK-NEXT:    stxv vs1, 32(r3)
; CHECK-NEXT:    stxv vs2, 16(r3)
; CHECK-NEXT:    stxv vs3, 0(r3)
; CHECK-NEXT:    blr
;
; CHECK-BE-LABEL: int_xxmtacc:
; CHECK-BE:       # %bb.0: # %entry
; CHECK-BE-NEXT:    vmr v3, v2
; CHECK-BE-NEXT:    xxlor vs0, v2, v2
; CHECK-BE-NEXT:    xxlor vs1, v3, v3
; CHECK-BE-NEXT:    xxlor vs2, v2, v2
; CHECK-BE-NEXT:    xxlor vs3, v3, v3
; CHECK-BE-NEXT:    xxmtacc acc0
; CHECK-BE-NEXT:    stxv vs1, 16(r3)
; CHECK-BE-NEXT:    stxv vs0, 0(r3)
; CHECK-BE-NEXT:    stxv vs3, 48(r3)
; CHECK-BE-NEXT:    stxv vs2, 32(r3)
; CHECK-BE-NEXT:    blr
entry:
; One xxmtacc is generated from the call to assemble.acc then one xxmtacc is
; generated from the call to xxmtacc then one xxmfacc is generated for the store
  %0 = tail call <512 x i1> @llvm.ppc.mma.assemble.acc(<16 x i8> %vc, <16 x i8> %vc, <16 x i8> %vc, <16 x i8> %vc)
  %1 = tail call <512 x i1> @llvm.ppc.mma.xxmtacc(<512 x i1> %0)
  store <512 x i1> %1, <512 x i1>* %ptr, align 64
  ret void
}

; xxmfacc
declare <512 x i1> @llvm.ppc.mma.xxmfacc(<512 x i1>)
define void @int_xxmfacc(<512 x i1>* %ptr, <16 x i8> %vc) {
; CHECK-LABEL: int_xxmfacc:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    vmr v3, v2
; CHECK-NEXT:    xxlor vs0, v2, v2
; CHECK-NEXT:    xxlor vs1, v3, v3
; CHECK-NEXT:    xxlor vs2, v2, v2
; CHECK-NEXT:    xxlor vs3, v3, v3
; CHECK-NEXT:    stxv vs0, 48(r3)
; CHECK-NEXT:    stxv vs1, 32(r3)
; CHECK-NEXT:    stxv vs2, 16(r3)
; CHECK-NEXT:    stxv vs3, 0(r3)
; CHECK-NEXT:    blr
;
; CHECK-BE-LABEL: int_xxmfacc:
; CHECK-BE:       # %bb.0: # %entry
; CHECK-BE-NEXT:    vmr v3, v2
; CHECK-BE-NEXT:    xxlor vs0, v2, v2
; CHECK-BE-NEXT:    xxlor vs1, v3, v3
; CHECK-BE-NEXT:    xxlor vs2, v2, v2
; CHECK-BE-NEXT:    xxlor vs3, v3, v3
; CHECK-BE-NEXT:    stxv vs1, 16(r3)
; CHECK-BE-NEXT:    stxv vs0, 0(r3)
; CHECK-BE-NEXT:    stxv vs3, 48(r3)
; CHECK-BE-NEXT:    stxv vs2, 32(r3)
; CHECK-BE-NEXT:    blr
entry:
; One xxmtacc is generated from the call to assemble.acc then one xxmfacc is
; generated from the call to xxmfacc then one xxmfacc is generated for the store
  %0 = tail call <512 x i1> @llvm.ppc.mma.assemble.acc(<16 x i8> %vc, <16 x i8> %vc, <16 x i8> %vc, <16 x i8> %vc)
  %1 = tail call <512 x i1> @llvm.ppc.mma.xxmfacc(<512 x i1> %0)
  store <512 x i1> %1, <512 x i1>* %ptr, align 64
  ret void
}

; xxsetaccz
declare <512 x i1> @llvm.ppc.mma.xxsetaccz()
define void @int_xxsetaccz(<512 x i1>* %ptr) {
; CHECK-LABEL: int_xxsetaccz:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    xxsetaccz acc0
; CHECK-NEXT:    xxmfacc acc0
; CHECK-NEXT:    stxv vs0, 48(r3)
; CHECK-NEXT:    stxv vs1, 32(r3)
; CHECK-NEXT:    stxv vs2, 16(r3)
; CHECK-NEXT:    stxv vs3, 0(r3)
; CHECK-NEXT:    blr
;
; CHECK-BE-LABEL: int_xxsetaccz:
; CHECK-BE:       # %bb.0: # %entry
; CHECK-BE-NEXT:    xxsetaccz acc0
; CHECK-BE-NEXT:    xxmfacc acc0
; CHECK-BE-NEXT:    stxv vs1, 16(r3)
; CHECK-BE-NEXT:    stxv vs0, 0(r3)
; CHECK-BE-NEXT:    stxv vs3, 48(r3)
; CHECK-BE-NEXT:    stxv vs2, 32(r3)
; CHECK-BE-NEXT:    blr
entry:
  %0 = tail call <512 x i1> @llvm.ppc.mma.xxsetaccz()
  store <512 x i1> %0, <512 x i1>* %ptr, align 64
  ret void
}

; disassemble_acc
declare { <16 x i8>, <16 x i8>, <16 x i8>, <16 x i8> } @llvm.ppc.mma.disassemble.acc(<512 x i1>)
define void @disass_acc(<16 x i8>* %ptr1, <16 x i8>* %ptr2, <16 x i8>* %ptr3, <16 x i8>* %ptr4) {
; CHECK-LABEL: disass_acc:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    xxsetaccz acc0
; CHECK-NEXT:    xxmfacc acc0
; CHECK-NEXT:    stxv vs3, 0(r3)
; CHECK-NEXT:    stxv vs2, 0(r4)
; CHECK-NEXT:    stxv vs1, 0(r5)
; CHECK-NEXT:    stxv vs0, 0(r6)
; CHECK-NEXT:    blr
;
; CHECK-BE-LABEL: disass_acc:
; CHECK-BE:       # %bb.0: # %entry
; CHECK-BE-NEXT:    xxsetaccz acc0
; CHECK-BE-NEXT:    xxmfacc acc0
; CHECK-BE-NEXT:    stxv vs0, 0(r3)
; CHECK-BE-NEXT:    stxv vs1, 0(r4)
; CHECK-BE-NEXT:    stxv vs2, 0(r5)
; CHECK-BE-NEXT:    stxv vs3, 0(r6)
; CHECK-BE-NEXT:    blr
entry:
  %0 = tail call <512 x i1> @llvm.ppc.mma.xxsetaccz()
  %1 = tail call { <16 x i8>, <16 x i8>, <16 x i8>, <16 x i8> } @llvm.ppc.mma.disassemble.acc(<512 x i1> %0)
  %2 = extractvalue { <16 x i8>, <16 x i8>, <16 x i8>, <16 x i8> } %1, 0
  %3 = extractvalue { <16 x i8>, <16 x i8>, <16 x i8>, <16 x i8> } %1, 1
  %4 = extractvalue { <16 x i8>, <16 x i8>, <16 x i8>, <16 x i8> } %1, 2
  %5 = extractvalue { <16 x i8>, <16 x i8>, <16 x i8>, <16 x i8> } %1, 3
  store <16 x i8> %2, <16 x i8>* %ptr1, align 16
  store <16 x i8> %3, <16 x i8>* %ptr2, align 16
  store <16 x i8> %4, <16 x i8>* %ptr3, align 16
  store <16 x i8> %5, <16 x i8>* %ptr4, align 16
  ret void
}

; disassemble_pair
declare { <16 x i8>, <16 x i8> } @llvm.ppc.mma.disassemble.pair(<256 x i1>)
define void @disass_pair(<256 x i1>* %ptr1, <16 x i8>* %ptr2, <16 x i8>* %ptr3) {
; CHECK-LABEL: disass_pair:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    lxv vs1, 0(r3)
; CHECK-NEXT:    lxv vs0, 16(r3)
; CHECK-NEXT:    stxv vs1, 0(r4)
; CHECK-NEXT:    stxv vs0, 0(r5)
; CHECK-NEXT:    blr
;
; CHECK-BE-LABEL: disass_pair:
; CHECK-BE:       # %bb.0: # %entry
; CHECK-BE-NEXT:    lxv vs1, 16(r3)
; CHECK-BE-NEXT:    lxv vs0, 0(r3)
; CHECK-BE-NEXT:    stxv vs0, 0(r4)
; CHECK-BE-NEXT:    stxv vs1, 0(r5)
; CHECK-BE-NEXT:    blr
entry:
  %0 = load <256 x i1>, <256 x i1>* %ptr1, align 32
  %1 = tail call { <16 x i8>, <16 x i8> } @llvm.ppc.mma.disassemble.pair(<256 x i1> %0)
  %2 = extractvalue { <16 x i8>, <16 x i8> } %1, 0
  %3 = extractvalue { <16 x i8>, <16 x i8> } %1, 1
  store <16 x i8> %2, <16 x i8>* %ptr2, align 16
  store <16 x i8> %3, <16 x i8>* %ptr3, align 16
  ret void
}

declare <512 x i1> @llvm.ppc.mma.xvi4ger8pp(<512 x i1>, <16 x i8>, <16 x i8>)
define void @testBranch(<512 x i1>* %ptr, <16 x i8> %vc, i32 %val) {
; CHECK-LABEL: testBranch:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    cmplwi r7, 0
; CHECK-NEXT:    beq cr0, .LBB7_2
; CHECK-NEXT:  # %bb.1: # %if.then
; CHECK-NEXT:    xxsetaccz acc0
; CHECK-NEXT:    b .LBB7_3
; CHECK-NEXT:  .LBB7_2: # %if.else
; CHECK-NEXT:    lxv vs1, 32(r3)
; CHECK-NEXT:    lxv vs0, 48(r3)
; CHECK-NEXT:    lxv vs3, 0(r3)
; CHECK-NEXT:    lxv vs2, 16(r3)
; CHECK-NEXT:    xxmtacc acc0
; CHECK-NEXT:    xvi4ger8pp acc0, v2, v2
; CHECK-NEXT:  .LBB7_3: # %if.end
; CHECK-NEXT:    xxmfacc acc0
; CHECK-NEXT:    stxv vs0, 48(r3)
; CHECK-NEXT:    stxv vs1, 32(r3)
; CHECK-NEXT:    stxv vs2, 16(r3)
; CHECK-NEXT:    stxv vs3, 0(r3)
; CHECK-NEXT:    blr
;
; CHECK-BE-LABEL: testBranch:
; CHECK-BE:       # %bb.0: # %entry
; CHECK-BE-NEXT:    cmplwi r7, 0
; CHECK-BE-NEXT:    beq cr0, .LBB7_2
; CHECK-BE-NEXT:  # %bb.1: # %if.then
; CHECK-BE-NEXT:    xxsetaccz acc0
; CHECK-BE-NEXT:    b .LBB7_3
; CHECK-BE-NEXT:  .LBB7_2: # %if.else
; CHECK-BE-NEXT:    lxv vs1, 16(r3)
; CHECK-BE-NEXT:    lxv vs0, 0(r3)
; CHECK-BE-NEXT:    lxv vs3, 48(r3)
; CHECK-BE-NEXT:    lxv vs2, 32(r3)
; CHECK-BE-NEXT:    xxmtacc acc0
; CHECK-BE-NEXT:    xvi4ger8pp acc0, v2, v2
; CHECK-BE-NEXT:  .LBB7_3: # %if.end
; CHECK-BE-NEXT:    xxmfacc acc0
; CHECK-BE-NEXT:    stxv vs1, 16(r3)
; CHECK-BE-NEXT:    stxv vs0, 0(r3)
; CHECK-BE-NEXT:    stxv vs3, 48(r3)
; CHECK-BE-NEXT:    stxv vs2, 32(r3)
; CHECK-BE-NEXT:    blr
entry:
  %tobool = icmp eq i32 %val, 0
  br i1 %tobool, label %if.else, label %if.then

if.then:
  %0 = tail call <512 x i1> @llvm.ppc.mma.xxsetaccz()
  br label %if.end

if.else:
  %1 = load <512 x i1>, <512 x i1>* %ptr, align 64
  %2 = tail call <512 x i1> @llvm.ppc.mma.xvi4ger8pp(<512 x i1> %1, <16 x i8> %vc, <16 x i8> %vc)
  br label %if.end

if.end:
  %vq1.0 = phi <512 x i1> [ %0, %if.then ], [ %2, %if.else ]
  store <512 x i1> %vq1.0, <512 x i1>* %ptr, align 64
  ret void
}

; The following test cases check that the xxsetaccz instruction is correctly rematerialized
declare <512 x i1> @llvm.ppc.mma.xvf32gerpp(<512 x i1>, <16 x i8>, <16 x i8>)
declare <512 x i1> @llvm.ppc.mma.xvf32gerpn(<512 x i1>, <16 x i8>, <16 x i8>)
declare <512 x i1> @llvm.ppc.mma.xvf32gernp(<512 x i1>, <16 x i8>, <16 x i8>)

define void @testcse(<512 x i1>* %res, <16 x i8> %vc) {
; CHECK-LABEL: testcse:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    xxsetaccz acc0
; CHECK-NEXT:    xvf32gerpp acc0, v2, v2
; CHECK-NEXT:    xxmfacc acc0
; CHECK-NEXT:    stxv vs0, 48(r3)
; CHECK-NEXT:    stxv vs1, 32(r3)
; CHECK-NEXT:    stxv vs2, 16(r3)
; CHECK-NEXT:    stxv vs3, 0(r3)
; CHECK-NEXT:    stxv vs0, 112(r3)
; CHECK-NEXT:    stxv vs1, 96(r3)
; CHECK-NEXT:    stxv vs2, 80(r3)
; CHECK-NEXT:    stxv vs3, 64(r3)
; CHECK-NEXT:    blr
;
; CHECK-BE-LABEL: testcse:
; CHECK-BE:       # %bb.0: # %entry
; CHECK-BE-NEXT:    xxsetaccz acc0
; CHECK-BE-NEXT:    xvf32gerpp acc0, v2, v2
; CHECK-BE-NEXT:    xxmfacc acc0
; CHECK-BE-NEXT:    stxv vs1, 16(r3)
; CHECK-BE-NEXT:    stxv vs0, 0(r3)
; CHECK-BE-NEXT:    stxv vs3, 48(r3)
; CHECK-BE-NEXT:    stxv vs2, 32(r3)
; CHECK-BE-NEXT:    stxv vs1, 80(r3)
; CHECK-BE-NEXT:    stxv vs0, 64(r3)
; CHECK-BE-NEXT:    stxv vs3, 112(r3)
; CHECK-BE-NEXT:    stxv vs2, 96(r3)
; CHECK-BE-NEXT:    blr
entry:
  %0 = call <512 x i1> @llvm.ppc.mma.xxsetaccz()
  %1 = call <512 x i1> @llvm.ppc.mma.xxsetaccz()
  %2 = call <512 x i1> @llvm.ppc.mma.xvf32gerpp(<512 x i1> %0, <16 x i8> %vc, <16 x i8> %vc)
  %3 = call <512 x i1> @llvm.ppc.mma.xvf32gerpp(<512 x i1> %1, <16 x i8> %vc, <16 x i8> %vc)
  %4 = getelementptr inbounds <512 x i1>, <512 x i1>* %res, i64 0
  %5 = getelementptr inbounds <512 x i1>, <512 x i1>* %res, i64 1
  store <512 x i1> %2, <512 x i1>* %4, align 64
  store <512 x i1> %3, <512 x i1>* %5, align 64
  ret void
}

define void @testcse2(<512 x i1>* %res, <16 x i8> %vc) {
; CHECK-LABEL: testcse2:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    xxsetaccz acc0
; CHECK-NEXT:    xxsetaccz acc1
; CHECK-NEXT:    xvf32gerpp acc1, v2, v2
; CHECK-NEXT:    xvf32gerpn acc0, v2, v2
; CHECK-NEXT:    xxmfacc acc1
; CHECK-NEXT:    xxmfacc acc0
; CHECK-NEXT:    stxv vs4, 48(r3)
; CHECK-NEXT:    stxv vs5, 32(r3)
; CHECK-NEXT:    stxv vs6, 16(r3)
; CHECK-NEXT:    stxv vs7, 0(r3)
; CHECK-NEXT:    stxv vs0, 112(r3)
; CHECK-NEXT:    stxv vs1, 96(r3)
; CHECK-NEXT:    stxv vs2, 80(r3)
; CHECK-NEXT:    stxv vs3, 64(r3)
; CHECK-NEXT:    blr
;
; CHECK-BE-LABEL: testcse2:
; CHECK-BE:       # %bb.0: # %entry
; CHECK-BE-NEXT:    xxsetaccz acc0
; CHECK-BE-NEXT:    xxsetaccz acc1
; CHECK-BE-NEXT:    xvf32gerpp acc1, v2, v2
; CHECK-BE-NEXT:    xvf32gerpn acc0, v2, v2
; CHECK-BE-NEXT:    xxmfacc acc1
; CHECK-BE-NEXT:    xxmfacc acc0
; CHECK-BE-NEXT:    stxv vs5, 16(r3)
; CHECK-BE-NEXT:    stxv vs4, 0(r3)
; CHECK-BE-NEXT:    stxv vs7, 48(r3)
; CHECK-BE-NEXT:    stxv vs6, 32(r3)
; CHECK-BE-NEXT:    stxv vs1, 80(r3)
; CHECK-BE-NEXT:    stxv vs0, 64(r3)
; CHECK-BE-NEXT:    stxv vs3, 112(r3)
; CHECK-BE-NEXT:    stxv vs2, 96(r3)
; CHECK-BE-NEXT:    blr
entry:
  %0 = call <512 x i1> @llvm.ppc.mma.xxsetaccz()
  %1 = call <512 x i1> @llvm.ppc.mma.xxsetaccz()
  %2 = call <512 x i1> @llvm.ppc.mma.xvf32gerpp(<512 x i1> %0, <16 x i8> %vc, <16 x i8> %vc)
  %3 = call <512 x i1> @llvm.ppc.mma.xvf32gerpn(<512 x i1> %1, <16 x i8> %vc, <16 x i8> %vc)
  %4 = getelementptr inbounds <512 x i1>, <512 x i1>* %res, i64 0
  %5 = getelementptr inbounds <512 x i1>, <512 x i1>* %res, i64 1
  store <512 x i1> %2, <512 x i1>* %4, align 64
  store <512 x i1> %3, <512 x i1>* %5, align 64
  ret void
}

define void @testcse3(<512 x i1>* %res, <16 x i8> %vc) {
; CHECK-LABEL: testcse3:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    xxsetaccz acc0
; CHECK-NEXT:    xxsetaccz acc1
; CHECK-NEXT:    xvf32gerpp acc1, v2, v2
; CHECK-NEXT:    xvf32gerpn acc0, v2, v2
; CHECK-NEXT:    xxmfacc acc1
; CHECK-NEXT:    xxmfacc acc0
; CHECK-NEXT:    stxv vs4, 48(r3)
; CHECK-NEXT:    stxv vs5, 32(r3)
; CHECK-NEXT:    stxv vs6, 16(r3)
; CHECK-NEXT:    stxv vs7, 0(r3)
; CHECK-NEXT:    stxv vs0, 112(r3)
; CHECK-NEXT:    stxv vs1, 96(r3)
; CHECK-NEXT:    stxv vs2, 80(r3)
; CHECK-NEXT:    stxv vs3, 64(r3)
; CHECK-NEXT:    blr
;
; CHECK-BE-LABEL: testcse3:
; CHECK-BE:       # %bb.0: # %entry
; CHECK-BE-NEXT:    xxsetaccz acc0
; CHECK-BE-NEXT:    xxsetaccz acc1
; CHECK-BE-NEXT:    xvf32gerpp acc1, v2, v2
; CHECK-BE-NEXT:    xvf32gerpn acc0, v2, v2
; CHECK-BE-NEXT:    xxmfacc acc1
; CHECK-BE-NEXT:    xxmfacc acc0
; CHECK-BE-NEXT:    stxv vs5, 16(r3)
; CHECK-BE-NEXT:    stxv vs4, 0(r3)
; CHECK-BE-NEXT:    stxv vs7, 48(r3)
; CHECK-BE-NEXT:    stxv vs6, 32(r3)
; CHECK-BE-NEXT:    stxv vs1, 80(r3)
; CHECK-BE-NEXT:    stxv vs0, 64(r3)
; CHECK-BE-NEXT:    stxv vs3, 112(r3)
; CHECK-BE-NEXT:    stxv vs2, 96(r3)
; CHECK-BE-NEXT:    blr
entry:
  %0 = call <512 x i1> @llvm.ppc.mma.xxsetaccz()
  %1 = call <512 x i1> @llvm.ppc.mma.xvf32gerpp(<512 x i1> %0, <16 x i8> %vc, <16 x i8> %vc)
  %2 = call <512 x i1> @llvm.ppc.mma.xvf32gerpn(<512 x i1> %0, <16 x i8> %vc, <16 x i8> %vc)
  %3 = getelementptr inbounds <512 x i1>, <512 x i1>* %res, i64 0
  %4 = getelementptr inbounds <512 x i1>, <512 x i1>* %res, i64 1
  store <512 x i1> %1, <512 x i1>* %3, align 64
  store <512 x i1> %2, <512 x i1>* %4, align 64
  ret void
}

define void @testcse4(<512 x i1>* %res, i32 %lim, <16 x i8>* %vc) {
; CHECK-LABEL: testcse4:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    cmpwi r4, 1
; CHECK-NEXT:    bltlr cr0
; CHECK-NEXT:  # %bb.1: # %for.body.preheader
; CHECK-NEXT:    clrldi r4, r4, 32
; CHECK-NEXT:    li r6, 0
; CHECK-NEXT:    mtctr r4
; CHECK-NEXT:    li r4, 0
; CHECK-NEXT:    .p2align 4
; CHECK-NEXT:  .LBB11_2: # %for.body
; CHECK-NEXT:    #
; CHECK-NEXT:    rldic r7, r6, 4, 28
; CHECK-NEXT:    addi r6, r6, 6
; CHECK-NEXT:    xxsetaccz acc2
; CHECK-NEXT:    xxsetaccz acc1
; CHECK-NEXT:    lxvx vs0, r5, r7
; CHECK-NEXT:    add r7, r5, r7
; CHECK-NEXT:    lxv vs1, 16(r7)
; CHECK-NEXT:    xvf32gerpp acc2, vs0, vs1
; CHECK-NEXT:    lxv vs0, 32(r7)
; CHECK-NEXT:    lxv vs1, 48(r7)
; CHECK-NEXT:    xxmfacc acc2
; CHECK-NEXT:    xvf32gerpn acc1, vs0, vs1
; CHECK-NEXT:    lxv vs12, 64(r7)
; CHECK-NEXT:    lxv vs13, 80(r7)
; CHECK-NEXT:    rldic r7, r4, 6, 26
; CHECK-NEXT:    addi r4, r4, 3
; CHECK-NEXT:    xxsetaccz acc0
; CHECK-NEXT:    xxmfacc acc1
; CHECK-NEXT:    xvf32gernp acc0, vs12, vs13
; CHECK-NEXT:    stxvx vs11, r3, r7
; CHECK-NEXT:    add r7, r3, r7
; CHECK-NEXT:    xxmfacc acc0
; CHECK-NEXT:    stxv vs8, 48(r7)
; CHECK-NEXT:    stxv vs9, 32(r7)
; CHECK-NEXT:    stxv vs10, 16(r7)
; CHECK-NEXT:    stxv vs4, 112(r7)
; CHECK-NEXT:    stxv vs5, 96(r7)
; CHECK-NEXT:    stxv vs6, 80(r7)
; CHECK-NEXT:    stxv vs7, 64(r7)
; CHECK-NEXT:    stxv vs0, 176(r7)
; CHECK-NEXT:    stxv vs1, 160(r7)
; CHECK-NEXT:    stxv vs2, 144(r7)
; CHECK-NEXT:    stxv vs3, 128(r7)
; CHECK-NEXT:    bdnz .LBB11_2
; CHECK-NEXT:  # %bb.3: # %for.cond.cleanup
; CHECK-NEXT:    blr
;
; CHECK-BE-LABEL: testcse4:
; CHECK-BE:       # %bb.0: # %entry
; CHECK-BE-NEXT:    cmpwi r4, 1
; CHECK-BE-NEXT:    bltlr cr0
; CHECK-BE-NEXT:  # %bb.1: # %for.body.preheader
; CHECK-BE-NEXT:    clrldi r4, r4, 32
; CHECK-BE-NEXT:    li r6, 0
; CHECK-BE-NEXT:    mtctr r4
; CHECK-BE-NEXT:    li r4, 0
; CHECK-BE-NEXT:    .p2align 4
; CHECK-BE-NEXT:  .LBB11_2: # %for.body
; CHECK-BE-NEXT:    #
; CHECK-BE-NEXT:    rldic r7, r6, 4, 28
; CHECK-BE-NEXT:    addi r6, r6, 6
; CHECK-BE-NEXT:    xxsetaccz acc2
; CHECK-BE-NEXT:    xxsetaccz acc1
; CHECK-BE-NEXT:    lxvx vs0, r5, r7
; CHECK-BE-NEXT:    add r7, r5, r7
; CHECK-BE-NEXT:    lxv vs1, 16(r7)
; CHECK-BE-NEXT:    xvf32gerpp acc2, vs0, vs1
; CHECK-BE-NEXT:    lxv vs0, 32(r7)
; CHECK-BE-NEXT:    lxv vs1, 48(r7)
; CHECK-BE-NEXT:    xxmfacc acc2
; CHECK-BE-NEXT:    xvf32gerpn acc1, vs0, vs1
; CHECK-BE-NEXT:    lxv vs12, 64(r7)
; CHECK-BE-NEXT:    lxv vs13, 80(r7)
; CHECK-BE-NEXT:    rldic r7, r4, 6, 26
; CHECK-BE-NEXT:    addi r4, r4, 3
; CHECK-BE-NEXT:    xxsetaccz acc0
; CHECK-BE-NEXT:    xxmfacc acc1
; CHECK-BE-NEXT:    xvf32gernp acc0, vs12, vs13
; CHECK-BE-NEXT:    stxvx vs8, r3, r7
; CHECK-BE-NEXT:    add r7, r3, r7
; CHECK-BE-NEXT:    xxmfacc acc0
; CHECK-BE-NEXT:    stxv vs9, 16(r7)
; CHECK-BE-NEXT:    stxv vs11, 48(r7)
; CHECK-BE-NEXT:    stxv vs10, 32(r7)
; CHECK-BE-NEXT:    stxv vs5, 80(r7)
; CHECK-BE-NEXT:    stxv vs4, 64(r7)
; CHECK-BE-NEXT:    stxv vs7, 112(r7)
; CHECK-BE-NEXT:    stxv vs6, 96(r7)
; CHECK-BE-NEXT:    stxv vs1, 144(r7)
; CHECK-BE-NEXT:    stxv vs0, 128(r7)
; CHECK-BE-NEXT:    stxv vs3, 176(r7)
; CHECK-BE-NEXT:    stxv vs2, 160(r7)
; CHECK-BE-NEXT:    bdnz .LBB11_2
; CHECK-BE-NEXT:  # %bb.3: # %for.cond.cleanup
; CHECK-BE-NEXT:    blr
entry:
  %cmp55 = icmp sgt i32 %lim, 0
  br i1 %cmp55, label %for.body.preheader, label %for.cond.cleanup

for.body.preheader:                               ; preds = %entry
  %wide.trip.count = zext i32 %lim to i64
  br label %for.body

for.cond.cleanup:                                 ; preds = %for.body, %entry
  ret void

for.body:                                         ; preds = %for.body, %for.body.preheader
  %indvars.iv = phi i64 [ 0, %for.body.preheader ], [ %indvars.iv.next, %for.body ]
  %0 = tail call <512 x i1> @llvm.ppc.mma.xxsetaccz()
  %1 = tail call <512 x i1> @llvm.ppc.mma.xxsetaccz()
  %2 = tail call <512 x i1> @llvm.ppc.mma.xxsetaccz()
  %3 = trunc i64 %indvars.iv to i32
  %mul = mul nsw i32 %3, 6
  %idxprom = zext i32 %mul to i64
  %arrayidx = getelementptr inbounds <16 x i8>, <16 x i8>* %vc, i64 %idxprom
  %4 = load <16 x i8>, <16 x i8>* %arrayidx, align 16
  %add2 = or i32 %mul, 1
  %idxprom3 = zext i32 %add2 to i64
  %arrayidx4 = getelementptr inbounds <16 x i8>, <16 x i8>* %vc, i64 %idxprom3
  %5 = load <16 x i8>, <16 x i8>* %arrayidx4, align 16
  %6 = tail call <512 x i1> @llvm.ppc.mma.xvf32gerpp(<512 x i1> %0, <16 x i8> %4, <16 x i8> %5)
  %add6 = add nuw nsw i32 %mul, 2
  %idxprom7 = zext i32 %add6 to i64
  %arrayidx8 = getelementptr inbounds <16 x i8>, <16 x i8>* %vc, i64 %idxprom7
  %7 = load <16 x i8>, <16 x i8>* %arrayidx8, align 16
  %add10 = add nuw nsw i32 %mul, 3
  %idxprom11 = zext i32 %add10 to i64
  %arrayidx12 = getelementptr inbounds <16 x i8>, <16 x i8>* %vc, i64 %idxprom11
  %8 = load <16 x i8>, <16 x i8>* %arrayidx12, align 16
  %9 = tail call <512 x i1> @llvm.ppc.mma.xvf32gerpn(<512 x i1> %1, <16 x i8> %7, <16 x i8> %8)
  %add14 = add nuw nsw i32 %mul, 4
  %idxprom15 = zext i32 %add14 to i64
  %arrayidx16 = getelementptr inbounds <16 x i8>, <16 x i8>* %vc, i64 %idxprom15
  %10 = load <16 x i8>, <16 x i8>* %arrayidx16, align 16
  %add18 = add nuw nsw i32 %mul, 5
  %idxprom19 = zext i32 %add18 to i64
  %arrayidx20 = getelementptr inbounds <16 x i8>, <16 x i8>* %vc, i64 %idxprom19
  %11 = load <16 x i8>, <16 x i8>* %arrayidx20, align 16
  %12 = tail call <512 x i1> @llvm.ppc.mma.xvf32gernp(<512 x i1> %2, <16 x i8> %10, <16 x i8> %11)
  %mul21 = mul i64 %indvars.iv, 3
  %idx.ext = and i64 %mul21, 4294967295
  %add.ptr = getelementptr inbounds <512 x i1>, <512 x i1>* %res, i64 %idx.ext
  store <512 x i1> %6, <512 x i1>* %add.ptr, align 64
  %add.ptr26 = getelementptr inbounds <512 x i1>, <512 x i1>* %add.ptr, i64 1
  store <512 x i1> %9, <512 x i1>* %add.ptr26, align 64
  %add.ptr30 = getelementptr inbounds <512 x i1>, <512 x i1>* %add.ptr, i64 2
  store <512 x i1> %12, <512 x i1>* %add.ptr30, align 64
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  %exitcond.not = icmp eq i64 %indvars.iv.next, %wide.trip.count
  br i1 %exitcond.not, label %for.cond.cleanup, label %for.body
}

declare i32 @testRedundantPrimeUnprimeF()
define void @testRedundantPrimeUnprime(<512 x i1>* %dst, <16 x i8> %vc) nounwind {
; CHECK-LABEL: testRedundantPrimeUnprime:
; CHECK:         .localentry testRedundantPrimeUnprime, 1
; CHECK-NEXT:  # %bb.0: # %entry
; CHECK-NEXT:    mflr r0
; CHECK-NEXT:    std r30, -16(r1) # 8-byte Folded Spill
; CHECK-NEXT:    std r0, 16(r1)
; CHECK-NEXT:    stdu r1, -112(r1)
; CHECK-NEXT:    xxsetaccz acc0
; CHECK-NEXT:    xxsetaccz acc1
; CHECK-NEXT:    mr r30, r3
; CHECK-NEXT:    xxmfacc acc0
; CHECK-NEXT:    stxv vs0, 48(r3)
; CHECK-NEXT:    stxv vs1, 32(r3)
; CHECK-NEXT:    stxv vs2, 16(r3)
; CHECK-NEXT:    stxv vs3, 0(r3)
; CHECK-NEXT:    xvf32gerpp acc1, v2, v2
; CHECK-NEXT:    li r3, 64
; CHECK-NEXT:    xxmfacc acc1
; CHECK-NEXT:    stxvp vsp4, r1(r3)
; CHECK-NEXT:    li r3, 32
; CHECK-NEXT:    stxvp vsp6, r1(r3)
; CHECK-NEXT:    bl testRedundantPrimeUnprimeF@notoc
; CHECK-NEXT:    li r3, 64
; CHECK-NEXT:    lxvp vsp0, r1(r3)
; CHECK-NEXT:    li r3, 32
; CHECK-NEXT:    lxvp vsp2, r1(r3)
; CHECK-NEXT:    stxv vs0, 112(r30)
; CHECK-NEXT:    stxv vs1, 96(r30)
; CHECK-NEXT:    stxv vs2, 80(r30)
; CHECK-NEXT:    stxv vs3, 64(r30)
; CHECK-NEXT:    addi r1, r1, 112
; CHECK-NEXT:    ld r0, 16(r1)
; CHECK-NEXT:    ld r30, -16(r1) # 8-byte Folded Reload
; CHECK-NEXT:    mtlr r0
; CHECK-NEXT:    blr
;
; CHECK-BE-LABEL: testRedundantPrimeUnprime:
; CHECK-BE:       # %bb.0: # %entry
; CHECK-BE-NEXT:    mflr r0
; CHECK-BE-NEXT:    std r0, 16(r1)
; CHECK-BE-NEXT:    stdu r1, -192(r1)
; CHECK-BE-NEXT:    xxsetaccz acc0
; CHECK-BE-NEXT:    xxsetaccz acc1
; CHECK-BE-NEXT:    std r30, 176(r1) # 8-byte Folded Spill
; CHECK-BE-NEXT:    mr r30, r3
; CHECK-BE-NEXT:    xxmfacc acc0
; CHECK-BE-NEXT:    stxv vs1, 16(r3)
; CHECK-BE-NEXT:    stxv vs0, 0(r3)
; CHECK-BE-NEXT:    stxv vs3, 48(r3)
; CHECK-BE-NEXT:    stxv vs2, 32(r3)
; CHECK-BE-NEXT:    xvf32gerpp acc1, v2, v2
; CHECK-BE-NEXT:    li r3, 112
; CHECK-BE-NEXT:    xxmfacc acc1
; CHECK-BE-NEXT:    stxvp vsp4, r1(r3)
; CHECK-BE-NEXT:    li r3, 144
; CHECK-BE-NEXT:    stxvp vsp6, r1(r3)
; CHECK-BE-NEXT:    bl testRedundantPrimeUnprimeF
; CHECK-BE-NEXT:    nop
; CHECK-BE-NEXT:    li r3, 112
; CHECK-BE-NEXT:    lxvp vsp0, r1(r3)
; CHECK-BE-NEXT:    li r3, 144
; CHECK-BE-NEXT:    lxvp vsp2, r1(r3)
; CHECK-BE-NEXT:    stxv vs3, 112(r30)
; CHECK-BE-NEXT:    stxv vs2, 96(r30)
; CHECK-BE-NEXT:    stxv vs1, 80(r30)
; CHECK-BE-NEXT:    stxv vs0, 64(r30)
; CHECK-BE-NEXT:    ld r30, 176(r1) # 8-byte Folded Reload
; CHECK-BE-NEXT:    addi r1, r1, 192
; CHECK-BE-NEXT:    ld r0, 16(r1)
; CHECK-BE-NEXT:    mtlr r0
; CHECK-BE-NEXT:    blr
entry:
  %0 = tail call <512 x i1> @llvm.ppc.mma.xxsetaccz()
  store <512 x i1> %0, <512 x i1>* %dst, align 64
  %1 = tail call <512 x i1> @llvm.ppc.mma.xvf32gerpp(<512 x i1> %0, <16 x i8> %vc, <16 x i8> %vc)
  %call = tail call signext i32 bitcast (i32 ()* @testRedundantPrimeUnprimeF to i32 ()*)()
  %add.ptr1 = getelementptr inbounds <512 x i1>, <512 x i1>* %dst, i64 1
  store <512 x i1> %1, <512 x i1>* %add.ptr1, align 64
  ret void
}

declare <512 x i1> @llvm.ppc.mma.pmxvf64gernn(<512 x i1>, <256 x i1>, <16 x i8>, i32, i32)
declare <512 x i1> @llvm.ppc.mma.xvf64gernp(<512 x i1>, <256 x i1>, <16 x i8>)

; Function Attrs: nounwind
define void @test_ldst_1(<256 x i1>* %vpp, <256 x i1>* %vp2) {
; CHECK-LABEL: test_ldst_1:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    lxvp vsp0, 0(r3)
; CHECK-NEXT:    stxvp vsp0, 0(r4)
; CHECK-NEXT:    blr
;
; CHECK-BE-LABEL: test_ldst_1:
; CHECK-BE:       # %bb.0: # %entry
; CHECK-BE-NEXT:    lxvp vsp0, 0(r3)
; CHECK-BE-NEXT:    stxvp vsp0, 0(r4)
; CHECK-BE-NEXT:    blr
entry:
  %0 = bitcast <256 x i1>* %vpp to i8*
  %1 = tail call <256 x i1> @llvm.ppc.mma.lxvp(i8* %0)
  %2 = bitcast <256 x i1>* %vp2 to i8*
  tail call void @llvm.ppc.mma.stxvp(<256 x i1> %1, i8* %2)
  ret void
}

; Function Attrs: argmemonly nounwind readonly
declare <256 x i1> @llvm.ppc.mma.lxvp(i8*)

; Function Attrs: argmemonly nounwind writeonly
declare void @llvm.ppc.mma.stxvp(<256 x i1>, i8*)

; Function Attrs: nounwind
define void @test_ldst_2(<256 x i1>* %vpp, i64 %offset, <256 x i1>* %vp2)  {
; CHECK-LABEL: test_ldst_2:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    lxvpx vsp0, r3, r4
; CHECK-NEXT:    stxvpx vsp0, r5, r4
; CHECK-NEXT:    blr
;
; CHECK-BE-LABEL: test_ldst_2:
; CHECK-BE:       # %bb.0: # %entry
; CHECK-BE-NEXT:    lxvpx vsp0, r3, r4
; CHECK-BE-NEXT:    stxvpx vsp0, r5, r4
; CHECK-BE-NEXT:    blr
entry:
  %0 = bitcast <256 x i1>* %vpp to i8*
  %1 = getelementptr i8, i8* %0, i64 %offset
  %2 = tail call <256 x i1> @llvm.ppc.mma.lxvp(i8* %1)
  %3 = bitcast <256 x i1>* %vp2 to i8*
  %4 = getelementptr i8, i8* %3, i64 %offset
  tail call void @llvm.ppc.mma.stxvp(<256 x i1> %2, i8* %4)
  ret void
}

; Function Attrs: nounwind
define void @test_ldst_3(<256 x i1>* %vpp, <256 x i1>* %vp2)  {
; CHECK-LABEL: test_ldst_3:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    li r5, 18
; CHECK-NEXT:    lxvpx vsp0, r3, r5
; CHECK-NEXT:    stxvpx vsp0, r4, r5
; CHECK-NEXT:    blr
;
; CHECK-BE-LABEL: test_ldst_3:
; CHECK-BE:       # %bb.0: # %entry
; CHECK-BE-NEXT:    li r5, 18
; CHECK-BE-NEXT:    lxvpx vsp0, r3, r5
; CHECK-BE-NEXT:    stxvpx vsp0, r4, r5
; CHECK-BE-NEXT:    blr
entry:
  %0 = bitcast <256 x i1>* %vpp to i8*
  %1 = getelementptr i8, i8* %0, i64 18
  %2 = tail call <256 x i1> @llvm.ppc.mma.lxvp(i8* %1)
  %3 = bitcast <256 x i1>* %vp2 to i8*
  %4 = getelementptr i8, i8* %3, i64 18
  tail call void @llvm.ppc.mma.stxvp(<256 x i1> %2, i8* %4)
  ret void
}

; Function Attrs: nounwind
define void @test_ldst_4(<256 x i1>* %vpp, <256 x i1>* %vp2)  {
; CHECK-LABEL: test_ldst_4:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    li r5, 1
; CHECK-NEXT:    lxvpx vsp0, r3, r5
; CHECK-NEXT:    stxvpx vsp0, r4, r5
; CHECK-NEXT:    blr
;
; CHECK-BE-LABEL: test_ldst_4:
; CHECK-BE:       # %bb.0: # %entry
; CHECK-BE-NEXT:    li r5, 1
; CHECK-BE-NEXT:    lxvpx vsp0, r3, r5
; CHECK-BE-NEXT:    stxvpx vsp0, r4, r5
; CHECK-BE-NEXT:    blr
entry:
  %0 = bitcast <256 x i1>* %vpp to i8*
  %1 = getelementptr i8, i8* %0, i64 1
  %2 = tail call <256 x i1> @llvm.ppc.mma.lxvp(i8* %1)
  %3 = bitcast <256 x i1>* %vp2 to i8*
  %4 = getelementptr i8, i8* %3, i64 1
  tail call void @llvm.ppc.mma.stxvp(<256 x i1> %2, i8* %4)
  ret void
}

; Function Attrs: nounwind
define void @test_ldst_5(<256 x i1>* %vpp, <256 x i1>* %vp2)  {
; CHECK-LABEL: test_ldst_5:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    li r5, 42
; CHECK-NEXT:    lxvpx vsp0, r3, r5
; CHECK-NEXT:    stxvpx vsp0, r4, r5
; CHECK-NEXT:    blr
;
; CHECK-BE-LABEL: test_ldst_5:
; CHECK-BE:       # %bb.0: # %entry
; CHECK-BE-NEXT:    li r5, 42
; CHECK-BE-NEXT:    lxvpx vsp0, r3, r5
; CHECK-BE-NEXT:    stxvpx vsp0, r4, r5
; CHECK-BE-NEXT:    blr
entry:
  %0 = bitcast <256 x i1>* %vpp to i8*
  %1 = getelementptr i8, i8* %0, i64 42
  %2 = tail call <256 x i1> @llvm.ppc.mma.lxvp(i8* %1)
  %3 = bitcast <256 x i1>* %vp2 to i8*
  %4 = getelementptr i8, i8* %3, i64 42
  tail call void @llvm.ppc.mma.stxvp(<256 x i1> %2, i8* %4)
  ret void
}

; Function Attrs: nounwind
define void @test_ldst_6(<256 x i1>* %vpp, <256 x i1>* %vp2)  {
; CHECK-LABEL: test_ldst_6:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    lxvp vsp0, 4096(r3)
; CHECK-NEXT:    stxvp vsp0, 4096(r4)
; CHECK-NEXT:    blr
;
; CHECK-BE-LABEL: test_ldst_6:
; CHECK-BE:       # %bb.0: # %entry
; CHECK-BE-NEXT:    lxvp vsp0, 4096(r3)
; CHECK-BE-NEXT:    stxvp vsp0, 4096(r4)
; CHECK-BE-NEXT:    blr
entry:
  %0 = getelementptr <256 x i1>, <256 x i1>* %vpp, i64 128
  %1 = bitcast <256 x i1>* %0 to i8*
  %2 = tail call <256 x i1> @llvm.ppc.mma.lxvp(i8* %1)
  %3 = getelementptr <256 x i1>, <256 x i1>* %vp2, i64 128
  %4 = bitcast <256 x i1>* %3 to i8*
  tail call void @llvm.ppc.mma.stxvp(<256 x i1> %2, i8* %4)
  ret void
}

; Function Attrs: nounwind
define void @test_ldst_7(<256 x i1>* %vpp, <256 x i1>* %vp2)  {
; FIXME: A prefixed load (plxvp) is expected here as the offset in this
; test case is a constant that fits within 34-bits.
; CHECK-LABEL: test_ldst_7:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    li r5, 0
; CHECK-NEXT:    ori r5, r5, 32799
; CHECK-NEXT:    lxvpx vsp0, r3, r5
; CHECK-NEXT:    stxvpx vsp0, r4, r5
; CHECK-NEXT:    blr
;
; CHECK-BE-LABEL: test_ldst_7:
; CHECK-BE:       # %bb.0: # %entry
; CHECK-BE-NEXT:    li r5, 0
; CHECK-BE-NEXT:    ori r5, r5, 32799
; CHECK-BE-NEXT:    lxvpx vsp0, r3, r5
; CHECK-BE-NEXT:    stxvpx vsp0, r4, r5
; CHECK-BE-NEXT:    blr
entry:
  %0 = bitcast <256 x i1>* %vpp to i8*
  %1 = getelementptr i8, i8* %0, i64 32799
  %2 = tail call <256 x i1> @llvm.ppc.mma.lxvp(i8* %1)
  %3 = bitcast <256 x i1>* %vp2 to i8*
  %4 = getelementptr i8, i8* %3, i64 32799
  tail call void @llvm.ppc.mma.stxvp(<256 x i1> %2, i8* %4)
  ret void
}

; Function Attrs: nofree nounwind
define void @test_ldst_8(i8* nocapture readonly %vqp, <256 x i1>* %vpp, <16 x i8> %vc, i8* nocapture %resp)  {
; CHECK-LABEL: test_ldst_8:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    lxv vs1, 32(r3)
; CHECK-NEXT:    lxv vs0, 48(r3)
; CHECK-NEXT:    lxv vs3, 0(r3)
; CHECK-NEXT:    lxv vs2, 16(r3)
; CHECK-NEXT:    li r3, 8
; CHECK-NEXT:    lxvpx vsp4, r4, r3
; CHECK-NEXT:    xxmtacc acc0
; CHECK-NEXT:    pmxvf64gernn acc0, vsp4, v2, 0, 0
; CHECK-NEXT:    xxmfacc acc0
; CHECK-NEXT:    stxv vs0, 48(r7)
; CHECK-NEXT:    stxv vs1, 32(r7)
; CHECK-NEXT:    stxv vs2, 16(r7)
; CHECK-NEXT:    stxv vs3, 0(r7)
; CHECK-NEXT:    blr
;
; CHECK-BE-LABEL: test_ldst_8:
; CHECK-BE:       # %bb.0: # %entry
; CHECK-BE-NEXT:    lxv vs1, 16(r3)
; CHECK-BE-NEXT:    lxv vs0, 0(r3)
; CHECK-BE-NEXT:    lxv vs3, 48(r3)
; CHECK-BE-NEXT:    lxv vs2, 32(r3)
; CHECK-BE-NEXT:    li r3, 8
; CHECK-BE-NEXT:    lxvpx vsp4, r4, r3
; CHECK-BE-NEXT:    xxmtacc acc0
; CHECK-BE-NEXT:    pmxvf64gernn acc0, vsp4, v2, 0, 0
; CHECK-BE-NEXT:    xxmfacc acc0
; CHECK-BE-NEXT:    stxv vs1, 16(r7)
; CHECK-BE-NEXT:    stxv vs0, 0(r7)
; CHECK-BE-NEXT:    stxv vs3, 48(r7)
; CHECK-BE-NEXT:    stxv vs2, 32(r7)
; CHECK-BE-NEXT:    blr
entry:
  %0 = bitcast i8* %vqp to <512 x i1>*
  %1 = load <512 x i1>, <512 x i1>* %0, align 64
  %2 = bitcast <256 x i1>* %vpp to i8*
  %3 = getelementptr i8, i8* %2, i64 8
  %4 = tail call <256 x i1> @llvm.ppc.mma.lxvp(i8* %3)
  %5 = tail call <512 x i1> @llvm.ppc.mma.pmxvf64gernn(<512 x i1> %1, <256 x i1> %4, <16 x i8> %vc, i32 0, i32 0)
  %6 = bitcast i8* %resp to <512 x i1>*
  store <512 x i1> %5, <512 x i1>* %6, align 64
  ret void
}

; Function Attrs: nofree nounwind
define void @test_ldst_9(i8* nocapture readonly %vqp, <256 x i1>* %vpp, <16 x i8> %vc, i8* nocapture %resp)  {
; CHECK-LABEL: test_ldst_9:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    lxv vs1, 32(r3)
; CHECK-NEXT:    lxv vs0, 48(r3)
; CHECK-NEXT:    lxv vs3, 0(r3)
; CHECK-NEXT:    lxv vs2, 16(r3)
; CHECK-NEXT:    lxvp vsp4, 0(r4)
; CHECK-NEXT:    xxmtacc acc0
; CHECK-NEXT:    xvf64gernp acc0, vsp4, v2
; CHECK-NEXT:    xxmfacc acc0
; CHECK-NEXT:    stxv vs0, 48(r7)
; CHECK-NEXT:    stxv vs1, 32(r7)
; CHECK-NEXT:    stxv vs2, 16(r7)
; CHECK-NEXT:    stxv vs3, 0(r7)
; CHECK-NEXT:    blr
;
; CHECK-BE-LABEL: test_ldst_9:
; CHECK-BE:       # %bb.0: # %entry
; CHECK-BE-NEXT:    lxv vs1, 16(r3)
; CHECK-BE-NEXT:    lxv vs0, 0(r3)
; CHECK-BE-NEXT:    lxv vs3, 48(r3)
; CHECK-BE-NEXT:    lxv vs2, 32(r3)
; CHECK-BE-NEXT:    lxvp vsp4, 0(r4)
; CHECK-BE-NEXT:    xxmtacc acc0
; CHECK-BE-NEXT:    xvf64gernp acc0, vsp4, v2
; CHECK-BE-NEXT:    xxmfacc acc0
; CHECK-BE-NEXT:    stxv vs1, 16(r7)
; CHECK-BE-NEXT:    stxv vs0, 0(r7)
; CHECK-BE-NEXT:    stxv vs3, 48(r7)
; CHECK-BE-NEXT:    stxv vs2, 32(r7)
; CHECK-BE-NEXT:    blr
entry:
  %0 = bitcast i8* %vqp to <512 x i1>*
  %1 = load <512 x i1>, <512 x i1>* %0, align 64
  %2 = bitcast <256 x i1>* %vpp to i8*
  %3 = tail call <256 x i1> @llvm.ppc.mma.lxvp(i8* %2)
  %4 = tail call <512 x i1> @llvm.ppc.mma.xvf64gernp(<512 x i1> %1, <256 x i1> %3, <16 x i8> %vc)
  %5 = bitcast i8* %resp to <512 x i1>*
  store <512 x i1> %4, <512 x i1>* %5, align 64
  ret void
}

; Function Attrs: nofree nounwind
define void @test_ldst_10(i8* nocapture readonly %vqp, i64 %offs, <256 x i1>* %vpp, <16 x i8> %vc, i8* nocapture %resp)  {
; CHECK-LABEL: test_ldst_10:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    lxv vs1, 32(r3)
; CHECK-NEXT:    lxv vs0, 48(r3)
; CHECK-NEXT:    lxv vs3, 0(r3)
; CHECK-NEXT:    lxv vs2, 16(r3)
; CHECK-NEXT:    lxvp vsp4, 0(r5)
; CHECK-NEXT:    xxmtacc acc0
; CHECK-NEXT:    xvf64gernp acc0, vsp4, v2
; CHECK-NEXT:    xxmfacc acc0
; CHECK-NEXT:    stxv vs0, 48(r9)
; CHECK-NEXT:    stxv vs1, 32(r9)
; CHECK-NEXT:    stxv vs2, 16(r9)
; CHECK-NEXT:    stxv vs3, 0(r9)
; CHECK-NEXT:    blr
;
; CHECK-BE-LABEL: test_ldst_10:
; CHECK-BE:       # %bb.0: # %entry
; CHECK-BE-NEXT:    lxv vs1, 16(r3)
; CHECK-BE-NEXT:    lxv vs0, 0(r3)
; CHECK-BE-NEXT:    lxv vs3, 48(r3)
; CHECK-BE-NEXT:    lxv vs2, 32(r3)
; CHECK-BE-NEXT:    lxvp vsp4, 0(r5)
; CHECK-BE-NEXT:    xxmtacc acc0
; CHECK-BE-NEXT:    xvf64gernp acc0, vsp4, v2
; CHECK-BE-NEXT:    xxmfacc acc0
; CHECK-BE-NEXT:    stxv vs1, 16(r9)
; CHECK-BE-NEXT:    stxv vs0, 0(r9)
; CHECK-BE-NEXT:    stxv vs3, 48(r9)
; CHECK-BE-NEXT:    stxv vs2, 32(r9)
; CHECK-BE-NEXT:    blr
entry:
  %0 = bitcast i8* %vqp to <512 x i1>*
  %1 = load <512 x i1>, <512 x i1>* %0, align 64
  %2 = bitcast <256 x i1>* %vpp to i8*
  %3 = tail call <256 x i1> @llvm.ppc.mma.lxvp(i8* %2)
  %4 = tail call <512 x i1> @llvm.ppc.mma.xvf64gernp(<512 x i1> %1, <256 x i1> %3, <16 x i8> %vc)
  %5 = bitcast i8* %resp to <512 x i1>*
  store <512 x i1> %4, <512 x i1>* %5, align 64
  ret void
}
