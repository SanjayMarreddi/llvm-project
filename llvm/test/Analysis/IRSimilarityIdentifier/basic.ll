; RUN: opt -disable-output -S -passes=print-ir-similarity < %s 2>&1 | FileCheck %s

; This is a simple test to make sure the IRSimilarityIdentifier and 
; IRSimilarityPrinterPass is working.

; CHECK: 4 candidates of length 2.  Found in: 
; CHECK-NEXT:   Function: cat,  Basic Block: entry
; CHECK-NEXT:   Function: fish,  Basic Block: entry
; CHECK-NEXT:   Function: dog,  Basic Block: entry
; CHECK-NEXT:   Function: turtle,  Basic Block: (unnamed)
; CHECK-NEXT: 4 candidates of length 3.  Found in: 
; CHECK-NEXT:   Function: cat,  Basic Block: entry
; CHECK-NEXT:   Function: fish,  Basic Block: entry
; CHECK-NEXT:   Function: dog,  Basic Block: entry
; CHECK-NEXT:   Function: turtle,  Basic Block: (unnamed)
; CHECK-NEXT: 4 candidates of length 4.  Found in: 
; CHECK-NEXT:   Function: cat,  Basic Block: entry
; CHECK-NEXT:   Function: fish,  Basic Block: entry
; CHECK-NEXT:   Function: dog,  Basic Block: entry
; CHECK-NEXT:   Function: turtle,  Basic Block: (unnamed)
; CHECK-NEXT: 4 candidates of length 5.  Found in: 
; CHECK-NEXT:   Function: cat,  Basic Block: entry
; CHECK-NEXT:   Function: fish,  Basic Block: entry
; CHECK-NEXT:   Function: dog,  Basic Block: entry
; CHECK-NEXT:   Function: turtle,  Basic Block: (unnamed)
; CHECK-NEXT: 4 candidates of length 6.  Found in: 
; CHECK-NEXT:   Function: cat,  Basic Block: entry
; CHECK-NEXT:   Function: fish,  Basic Block: entry
; CHECK-NEXT:   Function: dog,  Basic Block: entry
; CHECK-NEXT:   Function: turtle,  Basic Block: (unnamed)

define linkonce_odr void @fish() {
entry:
  %0 = alloca i32, align 4
  %1 = alloca i32, align 4
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  store i32 6, i32* %0, align 4
  store i32 1, i32* %1, align 4
  store i32 2, i32* %2, align 4
  store i32 3, i32* %3, align 4
  store i32 4, i32* %4, align 4
  store i32 5, i32* %5, align 4
  ret void
}

define void @turtle() {
  %1 = alloca i32, align 4
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  store i32 1, i32* %1, align 4
  store i32 2, i32* %2, align 4
  store i32 3, i32* %3, align 4
  store i32 4, i32* %4, align 4
  store i32 5, i32* %5, align 4
  store i32 6, i32* %6, align 4
  ret void
}

define void @cat() {
entry:
  %0 = alloca i32, align 4
  %1 = alloca i32, align 4
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  store i32 6, i32* %0, align 4
  store i32 1, i32* %1, align 4
  store i32 2, i32* %2, align 4
  store i32 3, i32* %3, align 4
  store i32 4, i32* %4, align 4
  store i32 5, i32* %5, align 4
  ret void
}

define void @dog() {
entry:
  %0 = alloca i32, align 4
  %1 = alloca i32, align 4
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  store i32 6, i32* %0, align 4
  store i32 1, i32* %1, align 4
  store i32 2, i32* %2, align 4
  store i32 3, i32* %3, align 4
  store i32 4, i32* %4, align 4
  store i32 5, i32* %5, align 4
  ret void
}
