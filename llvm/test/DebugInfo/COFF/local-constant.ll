; RUN: llc -mtriple=x86_64-windows-msvc < %s -filetype=obj | llvm-readobj -codeview - | FileCheck %s --check-prefix=OBJ

; This LL file was generated by running 'clang -g -gcodeview' on the
; following code:
; void useint(int);
; void constant_var() {
;   int x = 42;
;   useint(x);
;   useint(x);
; }

; FIXME: Find a way to describe variables optimized to constants.

; OBJ:        {{.*}}Proc{{.*}}Sym {
; OBJ:           DisplayName: constant_var
; OBJ:         }
; OBJ:         LocalSym {
; OBJ-NEXT:      Kind:
; OBJ-NEXT:      Type: int (0x74)
; OBJ-NEXT:      Flags [ (0x100)
; OBJ-NEXT:        IsOptimizedOut (0x100)
; OBJ-NEXT:      ]
; OBJ-NEXT:      VarName: x
; OBJ-NEXT:    }
; OBJ-NOT:     DefRange
; OBJ:         ProcEnd

; ModuleID = 't.cpp'
target datalayout = "e-m:w-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-windows-msvc18.0.0"

; Function Attrs: nounwind uwtable
define void @"\01?constant_var@@YAXXZ"() #0 !dbg !4 {
entry:
  tail call void @llvm.dbg.value(metadata i32 42, i64 0, metadata !8, metadata !14), !dbg !15
  tail call void @"\01?useint@@YAXH@Z"(i32 42) #3, !dbg !16
  tail call void @"\01?useint@@YAXH@Z"(i32 42) #3, !dbg !17
  ret void, !dbg !18
}

declare void @"\01?useint@@YAXH@Z"(i32) #1

; Function Attrs: nounwind readnone
declare void @llvm.dbg.value(metadata, i64, metadata, metadata) #2

attributes #0 = { nounwind uwtable "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+fxsr,+mmx,+sse,+sse2" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+fxsr,+mmx,+sse,+sse2" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #2 = { nounwind readnone }
attributes #3 = { nounwind }

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!10, !11, !12}
!llvm.ident = !{!13}

!0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "clang version 3.9.0 (trunk 260957)", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, enums: !2)
!1 = !DIFile(filename: "t.cpp", directory: "D:\5Csrc\5Cllvm\5Cbuild")
!2 = !{}
!4 = distinct !DISubprogram(name: "constant_var", linkageName: "\01?constant_var@@YAXXZ", scope: !1, file: !1, line: 2, type: !5, isLocal: false, isDefinition: true, scopeLine: 2, flags: DIFlagPrototyped, isOptimized: true, unit: !0, variables: !7)
!5 = !DISubroutineType(types: !6)
!6 = !{null}
!7 = !{!8}
!8 = !DILocalVariable(name: "x", scope: !4, file: !1, line: 3, type: !9)
!9 = !DIBasicType(name: "int", size: 32, align: 32, encoding: DW_ATE_signed)
!10 = !{i32 2, !"CodeView", i32 1}
!11 = !{i32 2, !"Debug Info Version", i32 3}
!12 = !{i32 1, !"PIC Level", i32 2}
!13 = !{!"clang version 3.9.0 (trunk 260957)"}
!14 = !DIExpression()
!15 = !DILocation(line: 3, column: 7, scope: !4)
!16 = !DILocation(line: 4, column: 3, scope: !4)
!17 = !DILocation(line: 5, column: 3, scope: !4)
!18 = !DILocation(line: 6, column: 1, scope: !4)
