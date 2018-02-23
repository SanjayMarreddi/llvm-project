; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc < %s -mtriple=i686-unknown-unknown -mattr=cmov | FileCheck %s --check-prefix=X86 --check-prefix=X86-NOSSE
; RUN: llc < %s -mtriple=i686-unknown-unknown -mattr=+sse2 | FileCheck %s --check-prefix=X86 --check-prefix=X86-SSE2
; RUN: llc < %s -mtriple=x86_64-unknown-unknown | FileCheck %s --check-prefix=X64 --check-prefix=X64-SSE2
; RUN: llc < %s -mtriple=x86_64-unknown-unknown -mattr=avx2 | FileCheck %s --check-prefix=X64 --check-prefix=X64-AVX2

; This tests codegen time inlining/optimization of memcmp
; rdar://6480398

@.str = private constant [65 x i8] c"0123456789012345678901234567890123456789012345678901234567890123\00", align 1

declare i32 @memcmp(i8*, i8*, i64)

define i32 @length2(i8* %X, i8* %Y) nounwind optsize {
; X86-LABEL: length2:
; X86:       # BB#0:
; X86-NEXT:    pushl %edi
; X86-NEXT:    pushl %esi
; X86-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X86-NEXT:    movl {{[0-9]+}}(%esp), %ecx
; X86-NEXT:    movzwl (%ecx), %ecx
; X86-NEXT:    movzwl (%eax), %edx
; X86-NEXT:    rolw $8, %cx
; X86-NEXT:    rolw $8, %dx
; X86-NEXT:    xorl %esi, %esi
; X86-NEXT:    xorl %edi, %edi
; X86-NEXT:    incl %edi
; X86-NEXT:    xorl %eax, %eax
; X86-NEXT:    decl %eax
; X86-NEXT:    cmpw %dx, %cx
; X86-NEXT:    cmovael %edi, %eax
; X86-NEXT:    cmovel %esi, %eax
; X86-NEXT:    popl %esi
; X86-NEXT:    popl %edi
; X86-NEXT:    retl
;
; X64-LABEL: length2:
; X64:       # BB#0:
; X64-NEXT:    movzwl (%rdi), %eax
; X64-NEXT:    movzwl (%rsi), %ecx
; X64-NEXT:    rolw $8, %ax
; X64-NEXT:    rolw $8, %cx
; X64-NEXT:    xorl %edx, %edx
; X64-NEXT:    cmpw %cx, %ax
; X64-NEXT:    movl $-1, %ecx
; X64-NEXT:    movl $1, %eax
; X64-NEXT:    cmovbl %ecx, %eax
; X64-NEXT:    cmovel %edx, %eax
; X64-NEXT:    retq
  %m = tail call i32 @memcmp(i8* %X, i8* %Y, i64 2) nounwind
  ret i32 %m
}

define i1 @length2_eq(i8* %X, i8* %Y) nounwind optsize {
; X86-LABEL: length2_eq:
; X86:       # BB#0:
; X86-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X86-NEXT:    movl {{[0-9]+}}(%esp), %ecx
; X86-NEXT:    movzwl (%ecx), %ecx
; X86-NEXT:    cmpw (%eax), %cx
; X86-NEXT:    sete %al
; X86-NEXT:    retl
;
; X64-LABEL: length2_eq:
; X64:       # BB#0:
; X64-NEXT:    movzwl (%rdi), %eax
; X64-NEXT:    cmpw (%rsi), %ax
; X64-NEXT:    sete %al
; X64-NEXT:    retq
  %m = tail call i32 @memcmp(i8* %X, i8* %Y, i64 2) nounwind
  %c = icmp eq i32 %m, 0
  ret i1 %c
}

define i1 @length2_eq_const(i8* %X) nounwind optsize {
; X86-LABEL: length2_eq_const:
; X86:       # BB#0:
; X86-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X86-NEXT:    movzwl (%eax), %eax
; X86-NEXT:    cmpl $12849, %eax # imm = 0x3231
; X86-NEXT:    setne %al
; X86-NEXT:    retl
;
; X64-LABEL: length2_eq_const:
; X64:       # BB#0:
; X64-NEXT:    movzwl (%rdi), %eax
; X64-NEXT:    cmpl $12849, %eax # imm = 0x3231
; X64-NEXT:    setne %al
; X64-NEXT:    retq
  %m = tail call i32 @memcmp(i8* %X, i8* getelementptr inbounds ([65 x i8], [65 x i8]* @.str, i32 0, i32 1), i64 2) nounwind
  %c = icmp ne i32 %m, 0
  ret i1 %c
}

define i1 @length2_eq_nobuiltin_attr(i8* %X, i8* %Y) nounwind optsize {
; X86-LABEL: length2_eq_nobuiltin_attr:
; X86:       # BB#0:
; X86-NEXT:    pushl $0
; X86-NEXT:    pushl $2
; X86-NEXT:    pushl {{[0-9]+}}(%esp)
; X86-NEXT:    pushl {{[0-9]+}}(%esp)
; X86-NEXT:    calll memcmp
; X86-NEXT:    addl $16, %esp
; X86-NEXT:    testl %eax, %eax
; X86-NEXT:    sete %al
; X86-NEXT:    retl
;
; X64-LABEL: length2_eq_nobuiltin_attr:
; X64:       # BB#0:
; X64-NEXT:    pushq %rax
; X64-NEXT:    movl $2, %edx
; X64-NEXT:    callq memcmp
; X64-NEXT:    testl %eax, %eax
; X64-NEXT:    sete %al
; X64-NEXT:    popq %rcx
; X64-NEXT:    retq
  %m = tail call i32 @memcmp(i8* %X, i8* %Y, i64 2) nounwind nobuiltin
  %c = icmp eq i32 %m, 0
  ret i1 %c
}

define i32 @length3(i8* %X, i8* %Y) nounwind optsize {
; X86-LABEL: length3:
; X86:       # BB#0: # %loadbb
; X86-NEXT:    pushl %esi
; X86-NEXT:    movl {{[0-9]+}}(%esp), %ecx
; X86-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X86-NEXT:    movzwl (%eax), %edx
; X86-NEXT:    movzwl (%ecx), %esi
; X86-NEXT:    rolw $8, %dx
; X86-NEXT:    rolw $8, %si
; X86-NEXT:    movzwl %dx, %edx
; X86-NEXT:    movzwl %si, %esi
; X86-NEXT:    cmpl %esi, %edx
; X86-NEXT:    jne .LBB4_1
; X86-NEXT:  # BB#2: # %loadbb1
; X86-NEXT:    movzbl 2(%eax), %eax
; X86-NEXT:    movzbl 2(%ecx), %ecx
; X86-NEXT:    subl %ecx, %eax
; X86-NEXT:    jmp .LBB4_3
; X86-NEXT:  .LBB4_1: # %res_block
; X86-NEXT:    xorl %ecx, %ecx
; X86-NEXT:    incl %ecx
; X86-NEXT:    xorl %eax, %eax
; X86-NEXT:    decl %eax
; X86-NEXT:    cmpl %esi, %edx
; X86-NEXT:    cmovael %ecx, %eax
; X86-NEXT:  .LBB4_3: # %endblock
; X86-NEXT:    popl %esi
; X86-NEXT:    retl
;
; X64-LABEL: length3:
; X64:       # BB#0: # %loadbb
; X64-NEXT:    movzwl (%rdi), %eax
; X64-NEXT:    movzwl (%rsi), %ecx
; X64-NEXT:    rolw $8, %ax
; X64-NEXT:    rolw $8, %cx
; X64-NEXT:    movzwl %ax, %eax
; X64-NEXT:    movzwl %cx, %ecx
; X64-NEXT:    cmpq %rcx, %rax
; X64-NEXT:    jne .LBB4_1
; X64-NEXT:  # BB#2: # %loadbb1
; X64-NEXT:    movzbl 2(%rdi), %eax
; X64-NEXT:    movzbl 2(%rsi), %ecx
; X64-NEXT:    subl %ecx, %eax
; X64-NEXT:    retq
; X64-NEXT:  .LBB4_1: # %res_block
; X64-NEXT:    movl $-1, %ecx
; X64-NEXT:    movl $1, %eax
; X64-NEXT:    cmovbl %ecx, %eax
; X64-NEXT:    retq
  %m = tail call i32 @memcmp(i8* %X, i8* %Y, i64 3) nounwind
  ret i32 %m
}

define i1 @length3_eq(i8* %X, i8* %Y) nounwind optsize {
; X86-LABEL: length3_eq:
; X86:       # BB#0: # %loadbb
; X86-NEXT:    movl {{[0-9]+}}(%esp), %ecx
; X86-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X86-NEXT:    movzwl (%eax), %edx
; X86-NEXT:    cmpw (%ecx), %dx
; X86-NEXT:    jne .LBB5_1
; X86-NEXT:  # BB#2: # %loadbb1
; X86-NEXT:    movb 2(%eax), %dl
; X86-NEXT:    xorl %eax, %eax
; X86-NEXT:    cmpb 2(%ecx), %dl
; X86-NEXT:    je .LBB5_3
; X86-NEXT:  .LBB5_1: # %res_block
; X86-NEXT:    xorl %eax, %eax
; X86-NEXT:    incl %eax
; X86-NEXT:  .LBB5_3: # %endblock
; X86-NEXT:    testl %eax, %eax
; X86-NEXT:    setne %al
; X86-NEXT:    retl
;
; X64-LABEL: length3_eq:
; X64:       # BB#0: # %loadbb
; X64-NEXT:    movzwl (%rdi), %eax
; X64-NEXT:    cmpw (%rsi), %ax
; X64-NEXT:    jne .LBB5_1
; X64-NEXT:  # BB#2: # %loadbb1
; X64-NEXT:    movb 2(%rdi), %cl
; X64-NEXT:    xorl %eax, %eax
; X64-NEXT:    cmpb 2(%rsi), %cl
; X64-NEXT:    je .LBB5_3
; X64-NEXT:  .LBB5_1: # %res_block
; X64-NEXT:    movl $1, %eax
; X64-NEXT:  .LBB5_3: # %endblock
; X64-NEXT:    testl %eax, %eax
; X64-NEXT:    setne %al
; X64-NEXT:    retq
  %m = tail call i32 @memcmp(i8* %X, i8* %Y, i64 3) nounwind
  %c = icmp ne i32 %m, 0
  ret i1 %c
}

define i32 @length4(i8* %X, i8* %Y) nounwind optsize {
; X86-LABEL: length4:
; X86:       # BB#0:
; X86-NEXT:    pushl %edi
; X86-NEXT:    pushl %esi
; X86-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X86-NEXT:    movl {{[0-9]+}}(%esp), %ecx
; X86-NEXT:    movl (%ecx), %ecx
; X86-NEXT:    movl (%eax), %edx
; X86-NEXT:    bswapl %ecx
; X86-NEXT:    bswapl %edx
; X86-NEXT:    xorl %esi, %esi
; X86-NEXT:    xorl %edi, %edi
; X86-NEXT:    incl %edi
; X86-NEXT:    xorl %eax, %eax
; X86-NEXT:    decl %eax
; X86-NEXT:    cmpl %edx, %ecx
; X86-NEXT:    cmovael %edi, %eax
; X86-NEXT:    cmovel %esi, %eax
; X86-NEXT:    popl %esi
; X86-NEXT:    popl %edi
; X86-NEXT:    retl
;
; X64-LABEL: length4:
; X64:       # BB#0:
; X64-NEXT:    movl (%rdi), %eax
; X64-NEXT:    movl (%rsi), %ecx
; X64-NEXT:    bswapl %eax
; X64-NEXT:    bswapl %ecx
; X64-NEXT:    xorl %edx, %edx
; X64-NEXT:    cmpl %ecx, %eax
; X64-NEXT:    movl $-1, %ecx
; X64-NEXT:    movl $1, %eax
; X64-NEXT:    cmovbl %ecx, %eax
; X64-NEXT:    cmovel %edx, %eax
; X64-NEXT:    retq
  %m = tail call i32 @memcmp(i8* %X, i8* %Y, i64 4) nounwind
  ret i32 %m
}

define i1 @length4_eq(i8* %X, i8* %Y) nounwind optsize {
; X86-LABEL: length4_eq:
; X86:       # BB#0:
; X86-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X86-NEXT:    movl {{[0-9]+}}(%esp), %ecx
; X86-NEXT:    movl (%ecx), %ecx
; X86-NEXT:    cmpl (%eax), %ecx
; X86-NEXT:    setne %al
; X86-NEXT:    retl
;
; X64-LABEL: length4_eq:
; X64:       # BB#0:
; X64-NEXT:    movl (%rdi), %eax
; X64-NEXT:    cmpl (%rsi), %eax
; X64-NEXT:    setne %al
; X64-NEXT:    retq
  %m = tail call i32 @memcmp(i8* %X, i8* %Y, i64 4) nounwind
  %c = icmp ne i32 %m, 0
  ret i1 %c
}

define i1 @length4_eq_const(i8* %X) nounwind optsize {
; X86-LABEL: length4_eq_const:
; X86:       # BB#0:
; X86-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X86-NEXT:    cmpl $875770417, (%eax) # imm = 0x34333231
; X86-NEXT:    sete %al
; X86-NEXT:    retl
;
; X64-LABEL: length4_eq_const:
; X64:       # BB#0:
; X64-NEXT:    cmpl $875770417, (%rdi) # imm = 0x34333231
; X64-NEXT:    sete %al
; X64-NEXT:    retq
  %m = tail call i32 @memcmp(i8* %X, i8* getelementptr inbounds ([65 x i8], [65 x i8]* @.str, i32 0, i32 1), i64 4) nounwind
  %c = icmp eq i32 %m, 0
  ret i1 %c
}

define i32 @length5(i8* %X, i8* %Y) nounwind optsize {
; X86-LABEL: length5:
; X86:       # BB#0: # %loadbb
; X86-NEXT:    pushl %esi
; X86-NEXT:    movl {{[0-9]+}}(%esp), %ecx
; X86-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X86-NEXT:    movl (%eax), %edx
; X86-NEXT:    movl (%ecx), %esi
; X86-NEXT:    bswapl %edx
; X86-NEXT:    bswapl %esi
; X86-NEXT:    cmpl %esi, %edx
; X86-NEXT:    jne .LBB9_1
; X86-NEXT:  # BB#2: # %loadbb1
; X86-NEXT:    movzbl 4(%eax), %eax
; X86-NEXT:    movzbl 4(%ecx), %ecx
; X86-NEXT:    subl %ecx, %eax
; X86-NEXT:    jmp .LBB9_3
; X86-NEXT:  .LBB9_1: # %res_block
; X86-NEXT:    xorl %ecx, %ecx
; X86-NEXT:    incl %ecx
; X86-NEXT:    xorl %eax, %eax
; X86-NEXT:    decl %eax
; X86-NEXT:    cmpl %esi, %edx
; X86-NEXT:    cmovael %ecx, %eax
; X86-NEXT:  .LBB9_3: # %endblock
; X86-NEXT:    popl %esi
; X86-NEXT:    retl
;
; X64-LABEL: length5:
; X64:       # BB#0: # %loadbb
; X64-NEXT:    movl (%rdi), %eax
; X64-NEXT:    movl (%rsi), %ecx
; X64-NEXT:    bswapl %eax
; X64-NEXT:    bswapl %ecx
; X64-NEXT:    cmpq %rcx, %rax
; X64-NEXT:    jne .LBB9_1
; X64-NEXT:  # BB#2: # %loadbb1
; X64-NEXT:    movzbl 4(%rdi), %eax
; X64-NEXT:    movzbl 4(%rsi), %ecx
; X64-NEXT:    subl %ecx, %eax
; X64-NEXT:    retq
; X64-NEXT:  .LBB9_1: # %res_block
; X64-NEXT:    movl $-1, %ecx
; X64-NEXT:    movl $1, %eax
; X64-NEXT:    cmovbl %ecx, %eax
; X64-NEXT:    retq
  %m = tail call i32 @memcmp(i8* %X, i8* %Y, i64 5) nounwind
  ret i32 %m
}

define i1 @length5_eq(i8* %X, i8* %Y) nounwind optsize {
; X86-LABEL: length5_eq:
; X86:       # BB#0: # %loadbb
; X86-NEXT:    movl {{[0-9]+}}(%esp), %ecx
; X86-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X86-NEXT:    movl (%eax), %edx
; X86-NEXT:    cmpl (%ecx), %edx
; X86-NEXT:    jne .LBB10_1
; X86-NEXT:  # BB#2: # %loadbb1
; X86-NEXT:    movb 4(%eax), %dl
; X86-NEXT:    xorl %eax, %eax
; X86-NEXT:    cmpb 4(%ecx), %dl
; X86-NEXT:    je .LBB10_3
; X86-NEXT:  .LBB10_1: # %res_block
; X86-NEXT:    xorl %eax, %eax
; X86-NEXT:    incl %eax
; X86-NEXT:  .LBB10_3: # %endblock
; X86-NEXT:    testl %eax, %eax
; X86-NEXT:    setne %al
; X86-NEXT:    retl
;
; X64-LABEL: length5_eq:
; X64:       # BB#0: # %loadbb
; X64-NEXT:    movl (%rdi), %eax
; X64-NEXT:    cmpl (%rsi), %eax
; X64-NEXT:    jne .LBB10_1
; X64-NEXT:  # BB#2: # %loadbb1
; X64-NEXT:    movb 4(%rdi), %cl
; X64-NEXT:    xorl %eax, %eax
; X64-NEXT:    cmpb 4(%rsi), %cl
; X64-NEXT:    je .LBB10_3
; X64-NEXT:  .LBB10_1: # %res_block
; X64-NEXT:    movl $1, %eax
; X64-NEXT:  .LBB10_3: # %endblock
; X64-NEXT:    testl %eax, %eax
; X64-NEXT:    setne %al
; X64-NEXT:    retq
  %m = tail call i32 @memcmp(i8* %X, i8* %Y, i64 5) nounwind
  %c = icmp ne i32 %m, 0
  ret i1 %c
}

define i32 @length8(i8* %X, i8* %Y) nounwind optsize {
; X86-LABEL: length8:
; X86:       # BB#0: # %loadbb
; X86-NEXT:    pushl %esi
; X86-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X86-NEXT:    movl {{[0-9]+}}(%esp), %esi
; X86-NEXT:    movl (%esi), %ecx
; X86-NEXT:    movl (%eax), %edx
; X86-NEXT:    bswapl %ecx
; X86-NEXT:    bswapl %edx
; X86-NEXT:    cmpl %edx, %ecx
; X86-NEXT:    jne .LBB11_1
; X86-NEXT:  # BB#2: # %loadbb1
; X86-NEXT:    movl 4(%esi), %ecx
; X86-NEXT:    movl 4(%eax), %edx
; X86-NEXT:    bswapl %ecx
; X86-NEXT:    bswapl %edx
; X86-NEXT:    xorl %eax, %eax
; X86-NEXT:    cmpl %edx, %ecx
; X86-NEXT:    je .LBB11_3
; X86-NEXT:  .LBB11_1: # %res_block
; X86-NEXT:    xorl %esi, %esi
; X86-NEXT:    incl %esi
; X86-NEXT:    xorl %eax, %eax
; X86-NEXT:    decl %eax
; X86-NEXT:    cmpl %edx, %ecx
; X86-NEXT:    cmovael %esi, %eax
; X86-NEXT:  .LBB11_3: # %endblock
; X86-NEXT:    popl %esi
; X86-NEXT:    retl
;
; X64-LABEL: length8:
; X64:       # BB#0:
; X64-NEXT:    movq (%rdi), %rax
; X64-NEXT:    movq (%rsi), %rcx
; X64-NEXT:    bswapq %rax
; X64-NEXT:    bswapq %rcx
; X64-NEXT:    xorl %edx, %edx
; X64-NEXT:    cmpq %rcx, %rax
; X64-NEXT:    movl $-1, %ecx
; X64-NEXT:    movl $1, %eax
; X64-NEXT:    cmovbl %ecx, %eax
; X64-NEXT:    cmovel %edx, %eax
; X64-NEXT:    retq
  %m = tail call i32 @memcmp(i8* %X, i8* %Y, i64 8) nounwind
  ret i32 %m
}

define i1 @length8_eq(i8* %X, i8* %Y) nounwind optsize {
; X86-LABEL: length8_eq:
; X86:       # BB#0: # %loadbb
; X86-NEXT:    movl {{[0-9]+}}(%esp), %ecx
; X86-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X86-NEXT:    movl (%eax), %edx
; X86-NEXT:    cmpl (%ecx), %edx
; X86-NEXT:    jne .LBB12_1
; X86-NEXT:  # BB#2: # %loadbb1
; X86-NEXT:    movl 4(%eax), %edx
; X86-NEXT:    xorl %eax, %eax
; X86-NEXT:    cmpl 4(%ecx), %edx
; X86-NEXT:    je .LBB12_3
; X86-NEXT:  .LBB12_1: # %res_block
; X86-NEXT:    xorl %eax, %eax
; X86-NEXT:    incl %eax
; X86-NEXT:  .LBB12_3: # %endblock
; X86-NEXT:    testl %eax, %eax
; X86-NEXT:    sete %al
; X86-NEXT:    retl
;
; X64-LABEL: length8_eq:
; X64:       # BB#0:
; X64-NEXT:    movq (%rdi), %rax
; X64-NEXT:    cmpq (%rsi), %rax
; X64-NEXT:    sete %al
; X64-NEXT:    retq
  %m = tail call i32 @memcmp(i8* %X, i8* %Y, i64 8) nounwind
  %c = icmp eq i32 %m, 0
  ret i1 %c
}

define i1 @length8_eq_const(i8* %X) nounwind optsize {
; X86-LABEL: length8_eq_const:
; X86:       # BB#0: # %loadbb
; X86-NEXT:    movl {{[0-9]+}}(%esp), %ecx
; X86-NEXT:    cmpl $858927408, (%ecx) # imm = 0x33323130
; X86-NEXT:    jne .LBB13_1
; X86-NEXT:  # BB#2: # %loadbb1
; X86-NEXT:    xorl %eax, %eax
; X86-NEXT:    cmpl $926299444, 4(%ecx) # imm = 0x37363534
; X86-NEXT:    je .LBB13_3
; X86-NEXT:  .LBB13_1: # %res_block
; X86-NEXT:    xorl %eax, %eax
; X86-NEXT:    incl %eax
; X86-NEXT:  .LBB13_3: # %endblock
; X86-NEXT:    testl %eax, %eax
; X86-NEXT:    setne %al
; X86-NEXT:    retl
;
; X64-LABEL: length8_eq_const:
; X64:       # BB#0:
; X64-NEXT:    movabsq $3978425819141910832, %rax # imm = 0x3736353433323130
; X64-NEXT:    cmpq %rax, (%rdi)
; X64-NEXT:    setne %al
; X64-NEXT:    retq
  %m = tail call i32 @memcmp(i8* %X, i8* getelementptr inbounds ([65 x i8], [65 x i8]* @.str, i32 0, i32 0), i64 8) nounwind
  %c = icmp ne i32 %m, 0
  ret i1 %c
}

define i1 @length12_eq(i8* %X, i8* %Y) nounwind optsize {
; X86-LABEL: length12_eq:
; X86:       # BB#0:
; X86-NEXT:    pushl $0
; X86-NEXT:    pushl $12
; X86-NEXT:    pushl {{[0-9]+}}(%esp)
; X86-NEXT:    pushl {{[0-9]+}}(%esp)
; X86-NEXT:    calll memcmp
; X86-NEXT:    addl $16, %esp
; X86-NEXT:    testl %eax, %eax
; X86-NEXT:    setne %al
; X86-NEXT:    retl
;
; X64-LABEL: length12_eq:
; X64:       # BB#0: # %loadbb
; X64-NEXT:    movq (%rdi), %rax
; X64-NEXT:    cmpq (%rsi), %rax
; X64-NEXT:    jne .LBB14_1
; X64-NEXT:  # BB#2: # %loadbb1
; X64-NEXT:    movl 8(%rdi), %ecx
; X64-NEXT:    xorl %eax, %eax
; X64-NEXT:    cmpl 8(%rsi), %ecx
; X64-NEXT:    je .LBB14_3
; X64-NEXT:  .LBB14_1: # %res_block
; X64-NEXT:    movl $1, %eax
; X64-NEXT:  .LBB14_3: # %endblock
; X64-NEXT:    testl %eax, %eax
; X64-NEXT:    setne %al
; X64-NEXT:    retq
  %m = tail call i32 @memcmp(i8* %X, i8* %Y, i64 12) nounwind
  %c = icmp ne i32 %m, 0
  ret i1 %c
}

define i32 @length12(i8* %X, i8* %Y) nounwind optsize {
; X86-LABEL: length12:
; X86:       # BB#0:
; X86-NEXT:    pushl $0
; X86-NEXT:    pushl $12
; X86-NEXT:    pushl {{[0-9]+}}(%esp)
; X86-NEXT:    pushl {{[0-9]+}}(%esp)
; X86-NEXT:    calll memcmp
; X86-NEXT:    addl $16, %esp
; X86-NEXT:    retl
;
; X64-LABEL: length12:
; X64:       # BB#0: # %loadbb
; X64-NEXT:    movq (%rdi), %rcx
; X64-NEXT:    movq (%rsi), %rdx
; X64-NEXT:    bswapq %rcx
; X64-NEXT:    bswapq %rdx
; X64-NEXT:    cmpq %rdx, %rcx
; X64-NEXT:    jne .LBB15_1
; X64-NEXT:  # BB#2: # %loadbb1
; X64-NEXT:    movl 8(%rdi), %ecx
; X64-NEXT:    movl 8(%rsi), %edx
; X64-NEXT:    bswapl %ecx
; X64-NEXT:    bswapl %edx
; X64-NEXT:    xorl %eax, %eax
; X64-NEXT:    cmpq %rdx, %rcx
; X64-NEXT:    jne .LBB15_1
; X64-NEXT:  # BB#3: # %endblock
; X64-NEXT:    retq
; X64-NEXT:  .LBB15_1: # %res_block
; X64-NEXT:    cmpq %rdx, %rcx
; X64-NEXT:    movl $-1, %ecx
; X64-NEXT:    movl $1, %eax
; X64-NEXT:    cmovbl %ecx, %eax
; X64-NEXT:    retq
  %m = tail call i32 @memcmp(i8* %X, i8* %Y, i64 12) nounwind
  ret i32 %m
}

; PR33329 - https://bugs.llvm.org/show_bug.cgi?id=33329

define i32 @length16(i8* %X, i8* %Y) nounwind optsize {
; X86-LABEL: length16:
; X86:       # BB#0:
; X86-NEXT:    pushl $0
; X86-NEXT:    pushl $16
; X86-NEXT:    pushl {{[0-9]+}}(%esp)
; X86-NEXT:    pushl {{[0-9]+}}(%esp)
; X86-NEXT:    calll memcmp
; X86-NEXT:    addl $16, %esp
; X86-NEXT:    retl
;
; X64-LABEL: length16:
; X64:       # BB#0: # %loadbb
; X64-NEXT:    movq (%rdi), %rcx
; X64-NEXT:    movq (%rsi), %rdx
; X64-NEXT:    bswapq %rcx
; X64-NEXT:    bswapq %rdx
; X64-NEXT:    cmpq %rdx, %rcx
; X64-NEXT:    jne .LBB16_1
; X64-NEXT:  # BB#2: # %loadbb1
; X64-NEXT:    movq 8(%rdi), %rcx
; X64-NEXT:    movq 8(%rsi), %rdx
; X64-NEXT:    bswapq %rcx
; X64-NEXT:    bswapq %rdx
; X64-NEXT:    xorl %eax, %eax
; X64-NEXT:    cmpq %rdx, %rcx
; X64-NEXT:    jne .LBB16_1
; X64-NEXT:  # BB#3: # %endblock
; X64-NEXT:    retq
; X64-NEXT:  .LBB16_1: # %res_block
; X64-NEXT:    cmpq %rdx, %rcx
; X64-NEXT:    movl $-1, %ecx
; X64-NEXT:    movl $1, %eax
; X64-NEXT:    cmovbl %ecx, %eax
; X64-NEXT:    retq
  %m = tail call i32 @memcmp(i8* %X, i8* %Y, i64 16) nounwind
  ret i32 %m
}

define i1 @length16_eq(i8* %x, i8* %y) nounwind optsize {
; X86-NOSSE-LABEL: length16_eq:
; X86-NOSSE:       # BB#0:
; X86-NOSSE-NEXT:    pushl $0
; X86-NOSSE-NEXT:    pushl $16
; X86-NOSSE-NEXT:    pushl {{[0-9]+}}(%esp)
; X86-NOSSE-NEXT:    pushl {{[0-9]+}}(%esp)
; X86-NOSSE-NEXT:    calll memcmp
; X86-NOSSE-NEXT:    addl $16, %esp
; X86-NOSSE-NEXT:    testl %eax, %eax
; X86-NOSSE-NEXT:    setne %al
; X86-NOSSE-NEXT:    retl
;
; X86-SSE2-LABEL: length16_eq:
; X86-SSE2:       # BB#0:
; X86-SSE2-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X86-SSE2-NEXT:    movl {{[0-9]+}}(%esp), %ecx
; X86-SSE2-NEXT:    movdqu (%ecx), %xmm0
; X86-SSE2-NEXT:    movdqu (%eax), %xmm1
; X86-SSE2-NEXT:    pcmpeqb %xmm0, %xmm1
; X86-SSE2-NEXT:    pmovmskb %xmm1, %eax
; X86-SSE2-NEXT:    cmpl $65535, %eax # imm = 0xFFFF
; X86-SSE2-NEXT:    setne %al
; X86-SSE2-NEXT:    retl
;
; X64-LABEL: length16_eq:
; X64:       # BB#0: # %loadbb
; X64-NEXT:    movq (%rdi), %rax
; X64-NEXT:    cmpq (%rsi), %rax
; X64-NEXT:    jne .LBB17_1
; X64-NEXT:  # BB#2: # %loadbb1
; X64-NEXT:    movq 8(%rdi), %rcx
; X64-NEXT:    xorl %eax, %eax
; X64-NEXT:    cmpq 8(%rsi), %rcx
; X64-NEXT:    je .LBB17_3
; X64-NEXT:  .LBB17_1: # %res_block
; X64-NEXT:    movl $1, %eax
; X64-NEXT:  .LBB17_3: # %endblock
; X64-NEXT:    testl %eax, %eax
; X64-NEXT:    setne %al
; X64-NEXT:    retq
  %call = tail call i32 @memcmp(i8* %x, i8* %y, i64 16) nounwind
  %cmp = icmp ne i32 %call, 0
  ret i1 %cmp
}

define i1 @length16_eq_const(i8* %X) nounwind optsize {
; X86-NOSSE-LABEL: length16_eq_const:
; X86-NOSSE:       # BB#0:
; X86-NOSSE-NEXT:    pushl $0
; X86-NOSSE-NEXT:    pushl $16
; X86-NOSSE-NEXT:    pushl $.L.str
; X86-NOSSE-NEXT:    pushl {{[0-9]+}}(%esp)
; X86-NOSSE-NEXT:    calll memcmp
; X86-NOSSE-NEXT:    addl $16, %esp
; X86-NOSSE-NEXT:    testl %eax, %eax
; X86-NOSSE-NEXT:    sete %al
; X86-NOSSE-NEXT:    retl
;
; X86-SSE2-LABEL: length16_eq_const:
; X86-SSE2:       # BB#0:
; X86-SSE2-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X86-SSE2-NEXT:    movdqu (%eax), %xmm0
; X86-SSE2-NEXT:    pcmpeqb {{\.LCPI.*}}, %xmm0
; X86-SSE2-NEXT:    pmovmskb %xmm0, %eax
; X86-SSE2-NEXT:    cmpl $65535, %eax # imm = 0xFFFF
; X86-SSE2-NEXT:    sete %al
; X86-SSE2-NEXT:    retl
;
; X64-LABEL: length16_eq_const:
; X64:       # BB#0: # %loadbb
; X64-NEXT:    movabsq $3978425819141910832, %rax # imm = 0x3736353433323130
; X64-NEXT:    cmpq %rax, (%rdi)
; X64-NEXT:    jne .LBB18_1
; X64-NEXT:  # BB#2: # %loadbb1
; X64-NEXT:    xorl %eax, %eax
; X64-NEXT:    movabsq $3833745473465760056, %rcx # imm = 0x3534333231303938
; X64-NEXT:    cmpq %rcx, 8(%rdi)
; X64-NEXT:    je .LBB18_3
; X64-NEXT:  .LBB18_1: # %res_block
; X64-NEXT:    movl $1, %eax
; X64-NEXT:  .LBB18_3: # %endblock
; X64-NEXT:    testl %eax, %eax
; X64-NEXT:    sete %al
; X64-NEXT:    retq
  %m = tail call i32 @memcmp(i8* %X, i8* getelementptr inbounds ([65 x i8], [65 x i8]* @.str, i32 0, i32 0), i64 16) nounwind
  %c = icmp eq i32 %m, 0
  ret i1 %c
}

define i32 @length32(i8* %X, i8* %Y) nounwind optsize {
; X86-LABEL: length32:
; X86:       # BB#0:
; X86-NEXT:    pushl $0
; X86-NEXT:    pushl $32
; X86-NEXT:    pushl {{[0-9]+}}(%esp)
; X86-NEXT:    pushl {{[0-9]+}}(%esp)
; X86-NEXT:    calll memcmp
; X86-NEXT:    addl $16, %esp
; X86-NEXT:    retl
;
; X64-LABEL: length32:
; X64:       # BB#0:
; X64-NEXT:    movl $32, %edx
; X64-NEXT:    jmp memcmp # TAILCALL
  %m = tail call i32 @memcmp(i8* %X, i8* %Y, i64 32) nounwind
  ret i32 %m
}

; PR33325 - https://bugs.llvm.org/show_bug.cgi?id=33325

define i1 @length32_eq(i8* %x, i8* %y) nounwind optsize {
; X86-LABEL: length32_eq:
; X86:       # BB#0:
; X86-NEXT:    pushl $0
; X86-NEXT:    pushl $32
; X86-NEXT:    pushl {{[0-9]+}}(%esp)
; X86-NEXT:    pushl {{[0-9]+}}(%esp)
; X86-NEXT:    calll memcmp
; X86-NEXT:    addl $16, %esp
; X86-NEXT:    testl %eax, %eax
; X86-NEXT:    sete %al
; X86-NEXT:    retl
;
; X64-SSE2-LABEL: length32_eq:
; X64-SSE2:       # BB#0:
; X64-SSE2-NEXT:    pushq %rax
; X64-SSE2-NEXT:    movl $32, %edx
; X64-SSE2-NEXT:    callq memcmp
; X64-SSE2-NEXT:    testl %eax, %eax
; X64-SSE2-NEXT:    sete %al
; X64-SSE2-NEXT:    popq %rcx
; X64-SSE2-NEXT:    retq
;
; X64-AVX2-LABEL: length32_eq:
; X64-AVX2:       # BB#0:
; X64-AVX2-NEXT:    vmovdqu (%rdi), %ymm0
; X64-AVX2-NEXT:    vpcmpeqb (%rsi), %ymm0, %ymm0
; X64-AVX2-NEXT:    vpmovmskb %ymm0, %eax
; X64-AVX2-NEXT:    cmpl $-1, %eax
; X64-AVX2-NEXT:    sete %al
; X64-AVX2-NEXT:    vzeroupper
; X64-AVX2-NEXT:    retq
  %call = tail call i32 @memcmp(i8* %x, i8* %y, i64 32) nounwind
  %cmp = icmp eq i32 %call, 0
  ret i1 %cmp
}

define i1 @length32_eq_const(i8* %X) nounwind optsize {
; X86-LABEL: length32_eq_const:
; X86:       # BB#0:
; X86-NEXT:    pushl $0
; X86-NEXT:    pushl $32
; X86-NEXT:    pushl $.L.str
; X86-NEXT:    pushl {{[0-9]+}}(%esp)
; X86-NEXT:    calll memcmp
; X86-NEXT:    addl $16, %esp
; X86-NEXT:    testl %eax, %eax
; X86-NEXT:    setne %al
; X86-NEXT:    retl
;
; X64-SSE2-LABEL: length32_eq_const:
; X64-SSE2:       # BB#0:
; X64-SSE2-NEXT:    pushq %rax
; X64-SSE2-NEXT:    movl $.L.str, %esi
; X64-SSE2-NEXT:    movl $32, %edx
; X64-SSE2-NEXT:    callq memcmp
; X64-SSE2-NEXT:    testl %eax, %eax
; X64-SSE2-NEXT:    setne %al
; X64-SSE2-NEXT:    popq %rcx
; X64-SSE2-NEXT:    retq
;
; X64-AVX2-LABEL: length32_eq_const:
; X64-AVX2:       # BB#0:
; X64-AVX2-NEXT:    vmovdqu (%rdi), %ymm0
; X64-AVX2-NEXT:    vpcmpeqb {{.*}}(%rip), %ymm0, %ymm0
; X64-AVX2-NEXT:    vpmovmskb %ymm0, %eax
; X64-AVX2-NEXT:    cmpl $-1, %eax
; X64-AVX2-NEXT:    setne %al
; X64-AVX2-NEXT:    vzeroupper
; X64-AVX2-NEXT:    retq
  %m = tail call i32 @memcmp(i8* %X, i8* getelementptr inbounds ([65 x i8], [65 x i8]* @.str, i32 0, i32 0), i64 32) nounwind
  %c = icmp ne i32 %m, 0
  ret i1 %c
}

define i32 @length64(i8* %X, i8* %Y) nounwind optsize {
; X86-LABEL: length64:
; X86:       # BB#0:
; X86-NEXT:    pushl $0
; X86-NEXT:    pushl $64
; X86-NEXT:    pushl {{[0-9]+}}(%esp)
; X86-NEXT:    pushl {{[0-9]+}}(%esp)
; X86-NEXT:    calll memcmp
; X86-NEXT:    addl $16, %esp
; X86-NEXT:    retl
;
; X64-LABEL: length64:
; X64:       # BB#0:
; X64-NEXT:    movl $64, %edx
; X64-NEXT:    jmp memcmp # TAILCALL
  %m = tail call i32 @memcmp(i8* %X, i8* %Y, i64 64) nounwind
  ret i32 %m
}

define i1 @length64_eq(i8* %x, i8* %y) nounwind optsize {
; X86-LABEL: length64_eq:
; X86:       # BB#0:
; X86-NEXT:    pushl $0
; X86-NEXT:    pushl $64
; X86-NEXT:    pushl {{[0-9]+}}(%esp)
; X86-NEXT:    pushl {{[0-9]+}}(%esp)
; X86-NEXT:    calll memcmp
; X86-NEXT:    addl $16, %esp
; X86-NEXT:    testl %eax, %eax
; X86-NEXT:    setne %al
; X86-NEXT:    retl
;
; X64-LABEL: length64_eq:
; X64:       # BB#0:
; X64-NEXT:    pushq %rax
; X64-NEXT:    movl $64, %edx
; X64-NEXT:    callq memcmp
; X64-NEXT:    testl %eax, %eax
; X64-NEXT:    setne %al
; X64-NEXT:    popq %rcx
; X64-NEXT:    retq
  %call = tail call i32 @memcmp(i8* %x, i8* %y, i64 64) nounwind
  %cmp = icmp ne i32 %call, 0
  ret i1 %cmp
}

define i1 @length64_eq_const(i8* %X) nounwind optsize {
; X86-LABEL: length64_eq_const:
; X86:       # BB#0:
; X86-NEXT:    pushl $0
; X86-NEXT:    pushl $64
; X86-NEXT:    pushl $.L.str
; X86-NEXT:    pushl {{[0-9]+}}(%esp)
; X86-NEXT:    calll memcmp
; X86-NEXT:    addl $16, %esp
; X86-NEXT:    testl %eax, %eax
; X86-NEXT:    sete %al
; X86-NEXT:    retl
;
; X64-LABEL: length64_eq_const:
; X64:       # BB#0:
; X64-NEXT:    pushq %rax
; X64-NEXT:    movl $.L.str, %esi
; X64-NEXT:    movl $64, %edx
; X64-NEXT:    callq memcmp
; X64-NEXT:    testl %eax, %eax
; X64-NEXT:    sete %al
; X64-NEXT:    popq %rcx
; X64-NEXT:    retq
  %m = tail call i32 @memcmp(i8* %X, i8* getelementptr inbounds ([65 x i8], [65 x i8]* @.str, i32 0, i32 0), i64 64) nounwind
  %c = icmp eq i32 %m, 0
  ret i1 %c
}

