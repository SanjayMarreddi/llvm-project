# NOTE: Assertions have been autogenerated by utils/update_mca_test_checks.py
# RUN: llvm-mca -mtriple=x86_64-unknown-unknown -mcpu=haswell -instruction-tables < %s | FileCheck %s

pclmulqdq     $11, %xmm0, %xmm2
pclmulqdq     $11, (%rax), %xmm2

# CHECK:      Instruction Info:
# CHECK-NEXT: [1]: #uOps
# CHECK-NEXT: [2]: Latency
# CHECK-NEXT: [3]: RThroughput
# CHECK-NEXT: [4]: MayLoad
# CHECK-NEXT: [5]: MayStore
# CHECK-NEXT: [6]: HasSideEffects (U)

# CHECK:      [1]    [2]    [3]    [4]    [5]    [6]    Instructions:
# CHECK-NEXT:  3      11    2.00                        pclmulqdq	$11, %xmm0, %xmm2
# CHECK-NEXT:  4      17    2.00    *                   pclmulqdq	$11, (%rax), %xmm2

# CHECK:      Resources:
# CHECK-NEXT: [0]   - HWDivider
# CHECK-NEXT: [1]   - HWFPDivider
# CHECK-NEXT: [2]   - HWPort0
# CHECK-NEXT: [3]   - HWPort1
# CHECK-NEXT: [4]   - HWPort2
# CHECK-NEXT: [5]   - HWPort3
# CHECK-NEXT: [6]   - HWPort4
# CHECK-NEXT: [7]   - HWPort5
# CHECK-NEXT: [8]   - HWPort6
# CHECK-NEXT: [9]   - HWPort7

# CHECK:      Resource pressure per iteration:
# CHECK-NEXT: [0]    [1]    [2]    [3]    [4]    [5]    [6]    [7]    [8]    [9]
# CHECK-NEXT:  -      -     4.00    -     0.50   0.50    -     2.00    -      -

# CHECK:      Resource pressure by instruction:
# CHECK-NEXT: [0]    [1]    [2]    [3]    [4]    [5]    [6]    [7]    [8]    [9]    Instructions:
# CHECK-NEXT:  -      -     2.00    -      -      -      -     1.00    -      -     pclmulqdq	$11, %xmm0, %xmm2
# CHECK-NEXT:  -      -     2.00    -     0.50   0.50    -     1.00    -      -     pclmulqdq	$11, (%rax), %xmm2
