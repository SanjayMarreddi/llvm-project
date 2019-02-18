; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc < %s -mtriple=mips -mcpu=mips2 -relocation-model=pic \
; RUN:   | FileCheck %s -check-prefixes=GP32,GP32R0R1
; RUN: llc < %s -mtriple=mips -mcpu=mips32 -relocation-model=pic \
; RUN:   | FileCheck %s -check-prefixes=GP32,GP32R0R1
; RUN: llc < %s -mtriple=mips -mcpu=mips32r2 -relocation-model=pic \
; RUN:   | FileCheck %s -check-prefixes=GP32,GP32R2R5
; RUN: llc < %s -mtriple=mips -mcpu=mips32r3 -relocation-model=pic \
; RUN:   | FileCheck %s -check-prefixes=GP32,GP32R2R5
; RUN: llc < %s -mtriple=mips -mcpu=mips32r5 -relocation-model=pic \
; RUN:   | FileCheck %s -check-prefixes=GP32,GP32R2R5
; RUN: llc < %s -mtriple=mips -mcpu=mips32r6 -relocation-model=pic \
; RUN:   | FileCheck %s -check-prefix=GP32R6

; RUN: llc < %s -mtriple=mips64 -mcpu=mips3 -relocation-model=pic \
; RUN:   | FileCheck %s -check-prefixes=GP64,GP64R0R1
; RUN: llc < %s -mtriple=mips64 -mcpu=mips4 -relocation-model=pic \
; RUN:   | FileCheck %s -check-prefixes=GP64,GP64R0R1
; RUN: llc < %s -mtriple=mips64 -mcpu=mips64 -relocation-model=pic \
; RUN:   | FileCheck %s -check-prefixes=GP64,GP64R0R2
; RUN: llc < %s -mtriple=mips64 -mcpu=mips64r2 -relocation-model=pic \
; RUN:   | FileCheck %s -check-prefixes=GP64,GP64R2R5
; RUN: llc < %s -mtriple=mips64 -mcpu=mips64r3 -relocation-model=pic \
; RUN:   | FileCheck %s -check-prefixes=GP64,GP64R2R5
; RUN: llc < %s -mtriple=mips64 -mcpu=mips64r5 -relocation-model=pic \
; RUN:   | FileCheck %s -check-prefixes=GP64,GP64R2R5
; RUN: llc < %s -mtriple=mips64 -mcpu=mips64r6 -relocation-model=pic \
; RUN:   | FileCheck %s -check-prefix=GP64R6

; RUN: llc < %s -mtriple=mips -mcpu=mips32r3 -mattr=+micromips -relocation-model=pic \
; RUN:   | FileCheck %s -check-prefix=MMR3
; RUN: llc < %s -mtriple=mips -mcpu=mips32r6 -mattr=+micromips -relocation-model=pic \
; RUN:   | FileCheck %s -check-prefix=MMR6

define zeroext i1 @udiv_i1(i1 zeroext %a, i1 zeroext %b) {
; GP32-LABEL: udiv_i1:
; GP32:       # %bb.0: # %entry
; GP32-NEXT:    jr $ra
; GP32-NEXT:    move $2, $4
;
; GP32R6-LABEL: udiv_i1:
; GP32R6:       # %bb.0: # %entry
; GP32R6-NEXT:    jr $ra
; GP32R6-NEXT:    move $2, $4
;
; GP64-LABEL: udiv_i1:
; GP64:       # %bb.0: # %entry
; GP64-NEXT:    jr $ra
; GP64-NEXT:    move $2, $4
;
; GP64R6-LABEL: udiv_i1:
; GP64R6:       # %bb.0: # %entry
; GP64R6-NEXT:    jr $ra
; GP64R6-NEXT:    move $2, $4
;
; MMR3-LABEL: udiv_i1:
; MMR3:       # %bb.0: # %entry
; MMR3-NEXT:    move $2, $4
; MMR3-NEXT:    jrc $ra
;
; MMR6-LABEL: udiv_i1:
; MMR6:       # %bb.0: # %entry
; MMR6-NEXT:    move $2, $4
; MMR6-NEXT:    jrc $ra
entry:
  %r = udiv i1 %a, %b
  ret i1 %r
}

define zeroext i8 @udiv_i8(i8 zeroext %a, i8 zeroext %b) {
; GP32-LABEL: udiv_i8:
; GP32:       # %bb.0: # %entry
; GP32-NEXT:    divu $zero, $4, $5
; GP32-NEXT:    teq $5, $zero, 7
; GP32-NEXT:    jr $ra
; GP32-NEXT:    mflo $2
;
; GP32R6-LABEL: udiv_i8:
; GP32R6:       # %bb.0: # %entry
; GP32R6-NEXT:    divu $2, $4, $5
; GP32R6-NEXT:    teq $5, $zero, 7
; GP32R6-NEXT:    jrc $ra
;
; GP64-LABEL: udiv_i8:
; GP64:       # %bb.0: # %entry
; GP64-NEXT:    divu $zero, $4, $5
; GP64-NEXT:    teq $5, $zero, 7
; GP64-NEXT:    jr $ra
; GP64-NEXT:    mflo $2
;
; GP64R6-LABEL: udiv_i8:
; GP64R6:       # %bb.0: # %entry
; GP64R6-NEXT:    divu $2, $4, $5
; GP64R6-NEXT:    teq $5, $zero, 7
; GP64R6-NEXT:    jrc $ra
;
; MMR3-LABEL: udiv_i8:
; MMR3:       # %bb.0: # %entry
; MMR3-NEXT:    divu $zero, $4, $5
; MMR3-NEXT:    teq $5, $zero, 7
; MMR3-NEXT:    mflo16 $2
; MMR3-NEXT:    jrc $ra
;
; MMR6-LABEL: udiv_i8:
; MMR6:       # %bb.0: # %entry
; MMR6-NEXT:    divu $2, $4, $5
; MMR6-NEXT:    teq $5, $zero, 7
; MMR6-NEXT:    jrc $ra
entry:
  %r = udiv i8 %a, %b
  ret i8 %r
}

define zeroext i16 @udiv_i16(i16 zeroext %a, i16 zeroext %b) {
; GP32-LABEL: udiv_i16:
; GP32:       # %bb.0: # %entry
; GP32-NEXT:    divu $zero, $4, $5
; GP32-NEXT:    teq $5, $zero, 7
; GP32-NEXT:    jr $ra
; GP32-NEXT:    mflo $2
;
; GP32R6-LABEL: udiv_i16:
; GP32R6:       # %bb.0: # %entry
; GP32R6-NEXT:    divu $2, $4, $5
; GP32R6-NEXT:    teq $5, $zero, 7
; GP32R6-NEXT:    jrc $ra
;
; GP64-LABEL: udiv_i16:
; GP64:       # %bb.0: # %entry
; GP64-NEXT:    divu $zero, $4, $5
; GP64-NEXT:    teq $5, $zero, 7
; GP64-NEXT:    jr $ra
; GP64-NEXT:    mflo $2
;
; GP64R6-LABEL: udiv_i16:
; GP64R6:       # %bb.0: # %entry
; GP64R6-NEXT:    divu $2, $4, $5
; GP64R6-NEXT:    teq $5, $zero, 7
; GP64R6-NEXT:    jrc $ra
;
; MMR3-LABEL: udiv_i16:
; MMR3:       # %bb.0: # %entry
; MMR3-NEXT:    divu $zero, $4, $5
; MMR3-NEXT:    teq $5, $zero, 7
; MMR3-NEXT:    mflo16 $2
; MMR3-NEXT:    jrc $ra
;
; MMR6-LABEL: udiv_i16:
; MMR6:       # %bb.0: # %entry
; MMR6-NEXT:    divu $2, $4, $5
; MMR6-NEXT:    teq $5, $zero, 7
; MMR6-NEXT:    jrc $ra
entry:
  %r = udiv i16 %a, %b
  ret i16 %r
}

define signext i32 @udiv_i32(i32 signext %a, i32 signext %b) {
; GP32-LABEL: udiv_i32:
; GP32:       # %bb.0: # %entry
; GP32-NEXT:    divu $zero, $4, $5
; GP32-NEXT:    teq $5, $zero, 7
; GP32-NEXT:    jr $ra
; GP32-NEXT:    mflo $2
;
; GP32R6-LABEL: udiv_i32:
; GP32R6:       # %bb.0: # %entry
; GP32R6-NEXT:    divu $2, $4, $5
; GP32R6-NEXT:    teq $5, $zero, 7
; GP32R6-NEXT:    jrc $ra
;
; GP64-LABEL: udiv_i32:
; GP64:       # %bb.0: # %entry
; GP64-NEXT:    divu $zero, $4, $5
; GP64-NEXT:    teq $5, $zero, 7
; GP64-NEXT:    jr $ra
; GP64-NEXT:    mflo $2
;
; GP64R6-LABEL: udiv_i32:
; GP64R6:       # %bb.0: # %entry
; GP64R6-NEXT:    divu $2, $4, $5
; GP64R6-NEXT:    teq $5, $zero, 7
; GP64R6-NEXT:    jrc $ra
;
; MMR3-LABEL: udiv_i32:
; MMR3:       # %bb.0: # %entry
; MMR3-NEXT:    divu $zero, $4, $5
; MMR3-NEXT:    teq $5, $zero, 7
; MMR3-NEXT:    mflo16 $2
; MMR3-NEXT:    jrc $ra
;
; MMR6-LABEL: udiv_i32:
; MMR6:       # %bb.0: # %entry
; MMR6-NEXT:    divu $2, $4, $5
; MMR6-NEXT:    teq $5, $zero, 7
; MMR6-NEXT:    jrc $ra
entry:
  %r = udiv i32 %a, %b
  ret i32 %r
}

define signext i64 @udiv_i64(i64 signext %a, i64 signext %b) {
; GP32-LABEL: udiv_i64:
; GP32:       # %bb.0: # %entry
; GP32-NEXT:    lui $2, %hi(_gp_disp)
; GP32-NEXT:    addiu $2, $2, %lo(_gp_disp)
; GP32-NEXT:    addiu $sp, $sp, -24
; GP32-NEXT:    .cfi_def_cfa_offset 24
; GP32-NEXT:    sw $ra, 20($sp) # 4-byte Folded Spill
; GP32-NEXT:    .cfi_offset 31, -4
; GP32-NEXT:    addu $gp, $2, $25
; GP32-NEXT:    lw $25, %call16(__udivdi3)($gp)
; GP32-NEXT:    jalr $25
; GP32-NEXT:    nop
; GP32-NEXT:    lw $ra, 20($sp) # 4-byte Folded Reload
; GP32-NEXT:    jr $ra
; GP32-NEXT:    addiu $sp, $sp, 24
;
; GP32R6-LABEL: udiv_i64:
; GP32R6:       # %bb.0: # %entry
; GP32R6-NEXT:    lui $2, %hi(_gp_disp)
; GP32R6-NEXT:    addiu $2, $2, %lo(_gp_disp)
; GP32R6-NEXT:    addiu $sp, $sp, -24
; GP32R6-NEXT:    .cfi_def_cfa_offset 24
; GP32R6-NEXT:    sw $ra, 20($sp) # 4-byte Folded Spill
; GP32R6-NEXT:    .cfi_offset 31, -4
; GP32R6-NEXT:    addu $gp, $2, $25
; GP32R6-NEXT:    lw $25, %call16(__udivdi3)($gp)
; GP32R6-NEXT:    jalrc $25
; GP32R6-NEXT:    lw $ra, 20($sp) # 4-byte Folded Reload
; GP32R6-NEXT:    jr $ra
; GP32R6-NEXT:    addiu $sp, $sp, 24
;
; GP64-LABEL: udiv_i64:
; GP64:       # %bb.0: # %entry
; GP64-NEXT:    ddivu $zero, $4, $5
; GP64-NEXT:    teq $5, $zero, 7
; GP64-NEXT:    jr $ra
; GP64-NEXT:    mflo $2
;
; GP64R6-LABEL: udiv_i64:
; GP64R6:       # %bb.0: # %entry
; GP64R6-NEXT:    ddivu $2, $4, $5
; GP64R6-NEXT:    teq $5, $zero, 7
; GP64R6-NEXT:    jrc $ra
;
; MMR3-LABEL: udiv_i64:
; MMR3:       # %bb.0: # %entry
; MMR3-NEXT:    lui $2, %hi(_gp_disp)
; MMR3-NEXT:    addiu $2, $2, %lo(_gp_disp)
; MMR3-NEXT:    addiusp -24
; MMR3-NEXT:    .cfi_def_cfa_offset 24
; MMR3-NEXT:    sw $ra, 20($sp) # 4-byte Folded Spill
; MMR3-NEXT:    .cfi_offset 31, -4
; MMR3-NEXT:    addu $2, $2, $25
; MMR3-NEXT:    lw $25, %call16(__udivdi3)($2)
; MMR3-NEXT:    move $gp, $2
; MMR3-NEXT:    jalr $25
; MMR3-NEXT:    nop
; MMR3-NEXT:    lw $ra, 20($sp) # 4-byte Folded Reload
; MMR3-NEXT:    addiusp 24
; MMR3-NEXT:    jrc $ra
;
; MMR6-LABEL: udiv_i64:
; MMR6:       # %bb.0: # %entry
; MMR6-NEXT:    lui $2, %hi(_gp_disp)
; MMR6-NEXT:    addiu $2, $2, %lo(_gp_disp)
; MMR6-NEXT:    addiu $sp, $sp, -24
; MMR6-NEXT:    .cfi_def_cfa_offset 24
; MMR6-NEXT:    sw $ra, 20($sp) # 4-byte Folded Spill
; MMR6-NEXT:    .cfi_offset 31, -4
; MMR6-NEXT:    addu $2, $2, $25
; MMR6-NEXT:    lw $25, %call16(__udivdi3)($2)
; MMR6-NEXT:    move $gp, $2
; MMR6-NEXT:    jalr $25
; MMR6-NEXT:    lw $ra, 20($sp) # 4-byte Folded Reload
; MMR6-NEXT:    addiu $sp, $sp, 24
; MMR6-NEXT:    jrc $ra
entry:
  %r = udiv i64 %a, %b
  ret i64 %r
}

define signext i128 @udiv_i128(i128 signext %a, i128 signext %b) {
; GP32-LABEL: udiv_i128:
; GP32:       # %bb.0: # %entry
; GP32-NEXT:    lui $2, %hi(_gp_disp)
; GP32-NEXT:    addiu $2, $2, %lo(_gp_disp)
; GP32-NEXT:    addiu $sp, $sp, -40
; GP32-NEXT:    .cfi_def_cfa_offset 40
; GP32-NEXT:    sw $ra, 36($sp) # 4-byte Folded Spill
; GP32-NEXT:    .cfi_offset 31, -4
; GP32-NEXT:    addu $gp, $2, $25
; GP32-NEXT:    lw $1, 60($sp)
; GP32-NEXT:    lw $2, 64($sp)
; GP32-NEXT:    lw $3, 68($sp)
; GP32-NEXT:    sw $3, 28($sp)
; GP32-NEXT:    sw $2, 24($sp)
; GP32-NEXT:    sw $1, 20($sp)
; GP32-NEXT:    lw $1, 56($sp)
; GP32-NEXT:    sw $1, 16($sp)
; GP32-NEXT:    lw $25, %call16(__udivti3)($gp)
; GP32-NEXT:    jalr $25
; GP32-NEXT:    nop
; GP32-NEXT:    lw $ra, 36($sp) # 4-byte Folded Reload
; GP32-NEXT:    jr $ra
; GP32-NEXT:    addiu $sp, $sp, 40
;
; GP32R6-LABEL: udiv_i128:
; GP32R6:       # %bb.0: # %entry
; GP32R6-NEXT:    lui $2, %hi(_gp_disp)
; GP32R6-NEXT:    addiu $2, $2, %lo(_gp_disp)
; GP32R6-NEXT:    addiu $sp, $sp, -40
; GP32R6-NEXT:    .cfi_def_cfa_offset 40
; GP32R6-NEXT:    sw $ra, 36($sp) # 4-byte Folded Spill
; GP32R6-NEXT:    .cfi_offset 31, -4
; GP32R6-NEXT:    addu $gp, $2, $25
; GP32R6-NEXT:    lw $1, 60($sp)
; GP32R6-NEXT:    lw $2, 64($sp)
; GP32R6-NEXT:    lw $3, 68($sp)
; GP32R6-NEXT:    sw $3, 28($sp)
; GP32R6-NEXT:    sw $2, 24($sp)
; GP32R6-NEXT:    sw $1, 20($sp)
; GP32R6-NEXT:    lw $1, 56($sp)
; GP32R6-NEXT:    sw $1, 16($sp)
; GP32R6-NEXT:    lw $25, %call16(__udivti3)($gp)
; GP32R6-NEXT:    jalrc $25
; GP32R6-NEXT:    lw $ra, 36($sp) # 4-byte Folded Reload
; GP32R6-NEXT:    jr $ra
; GP32R6-NEXT:    addiu $sp, $sp, 40
;
; GP64-LABEL: udiv_i128:
; GP64:       # %bb.0: # %entry
; GP64-NEXT:    daddiu $sp, $sp, -16
; GP64-NEXT:    .cfi_def_cfa_offset 16
; GP64-NEXT:    sd $ra, 8($sp) # 8-byte Folded Spill
; GP64-NEXT:    sd $gp, 0($sp) # 8-byte Folded Spill
; GP64-NEXT:    .cfi_offset 31, -8
; GP64-NEXT:    .cfi_offset 28, -16
; GP64-NEXT:    lui $1, %hi(%neg(%gp_rel(udiv_i128)))
; GP64-NEXT:    daddu $1, $1, $25
; GP64-NEXT:    daddiu $gp, $1, %lo(%neg(%gp_rel(udiv_i128)))
; GP64-NEXT:    ld $25, %call16(__udivti3)($gp)
; GP64-NEXT:    jalr $25
; GP64-NEXT:    nop
; GP64-NEXT:    ld $gp, 0($sp) # 8-byte Folded Reload
; GP64-NEXT:    ld $ra, 8($sp) # 8-byte Folded Reload
; GP64-NEXT:    jr $ra
; GP64-NEXT:    daddiu $sp, $sp, 16
;
; GP64R6-LABEL: udiv_i128:
; GP64R6:       # %bb.0: # %entry
; GP64R6-NEXT:    daddiu $sp, $sp, -16
; GP64R6-NEXT:    .cfi_def_cfa_offset 16
; GP64R6-NEXT:    sd $ra, 8($sp) # 8-byte Folded Spill
; GP64R6-NEXT:    sd $gp, 0($sp) # 8-byte Folded Spill
; GP64R6-NEXT:    .cfi_offset 31, -8
; GP64R6-NEXT:    .cfi_offset 28, -16
; GP64R6-NEXT:    lui $1, %hi(%neg(%gp_rel(udiv_i128)))
; GP64R6-NEXT:    daddu $1, $1, $25
; GP64R6-NEXT:    daddiu $gp, $1, %lo(%neg(%gp_rel(udiv_i128)))
; GP64R6-NEXT:    ld $25, %call16(__udivti3)($gp)
; GP64R6-NEXT:    jalrc $25
; GP64R6-NEXT:    ld $gp, 0($sp) # 8-byte Folded Reload
; GP64R6-NEXT:    ld $ra, 8($sp) # 8-byte Folded Reload
; GP64R6-NEXT:    jr $ra
; GP64R6-NEXT:    daddiu $sp, $sp, 16
;
; MMR3-LABEL: udiv_i128:
; MMR3:       # %bb.0: # %entry
; MMR3-NEXT:    lui $2, %hi(_gp_disp)
; MMR3-NEXT:    addiu $2, $2, %lo(_gp_disp)
; MMR3-NEXT:    addiusp -48
; MMR3-NEXT:    .cfi_def_cfa_offset 48
; MMR3-NEXT:    sw $ra, 44($sp) # 4-byte Folded Spill
; MMR3-NEXT:    swp $16, 36($sp)
; MMR3-NEXT:    .cfi_offset 31, -4
; MMR3-NEXT:    .cfi_offset 17, -8
; MMR3-NEXT:    .cfi_offset 16, -12
; MMR3-NEXT:    addu $16, $2, $25
; MMR3-NEXT:    move $1, $7
; MMR3-NEXT:    lw $7, 68($sp)
; MMR3-NEXT:    lw $17, 72($sp)
; MMR3-NEXT:    lw $3, 76($sp)
; MMR3-NEXT:    move $2, $sp
; MMR3-NEXT:    sw16 $3, 28($2)
; MMR3-NEXT:    sw16 $17, 24($2)
; MMR3-NEXT:    sw16 $7, 20($2)
; MMR3-NEXT:    lw $3, 64($sp)
; MMR3-NEXT:    sw16 $3, 16($2)
; MMR3-NEXT:    lw $25, %call16(__udivti3)($16)
; MMR3-NEXT:    move $7, $1
; MMR3-NEXT:    move $gp, $16
; MMR3-NEXT:    jalr $25
; MMR3-NEXT:    nop
; MMR3-NEXT:    lwp $16, 36($sp)
; MMR3-NEXT:    lw $ra, 44($sp) # 4-byte Folded Reload
; MMR3-NEXT:    addiusp 48
; MMR3-NEXT:    jrc $ra
;
; MMR6-LABEL: udiv_i128:
; MMR6:       # %bb.0: # %entry
; MMR6-NEXT:    lui $2, %hi(_gp_disp)
; MMR6-NEXT:    addiu $2, $2, %lo(_gp_disp)
; MMR6-NEXT:    addiu $sp, $sp, -48
; MMR6-NEXT:    .cfi_def_cfa_offset 48
; MMR6-NEXT:    sw $ra, 44($sp) # 4-byte Folded Spill
; MMR6-NEXT:    sw $17, 40($sp) # 4-byte Folded Spill
; MMR6-NEXT:    sw $16, 36($sp) # 4-byte Folded Spill
; MMR6-NEXT:    .cfi_offset 31, -4
; MMR6-NEXT:    .cfi_offset 17, -8
; MMR6-NEXT:    .cfi_offset 16, -12
; MMR6-NEXT:    addu $16, $2, $25
; MMR6-NEXT:    move $1, $7
; MMR6-NEXT:    lw $7, 68($sp)
; MMR6-NEXT:    lw $17, 72($sp)
; MMR6-NEXT:    lw $3, 76($sp)
; MMR6-NEXT:    move $2, $sp
; MMR6-NEXT:    sw16 $3, 28($2)
; MMR6-NEXT:    sw16 $17, 24($2)
; MMR6-NEXT:    sw16 $7, 20($2)
; MMR6-NEXT:    lw $3, 64($sp)
; MMR6-NEXT:    sw16 $3, 16($2)
; MMR6-NEXT:    lw $25, %call16(__udivti3)($16)
; MMR6-NEXT:    move $7, $1
; MMR6-NEXT:    move $gp, $16
; MMR6-NEXT:    jalr $25
; MMR6-NEXT:    lw $16, 36($sp) # 4-byte Folded Reload
; MMR6-NEXT:    lw $17, 40($sp) # 4-byte Folded Reload
; MMR6-NEXT:    lw $ra, 44($sp) # 4-byte Folded Reload
; MMR6-NEXT:    addiu $sp, $sp, 48
; MMR6-NEXT:    jrc $ra
entry:
  %r = udiv i128 %a, %b
  ret i128 %r
}
