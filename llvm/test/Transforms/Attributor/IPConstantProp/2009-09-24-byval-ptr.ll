; NOTE: Assertions have been autogenerated by utils/update_test_checks.py UTC_ARGS: --function-signature --scrub-attributes
; RUN: opt -attributor -attributor-manifest-internal  -attributor-max-iterations-verify -attributor-annotate-decl-cs -attributor-max-iterations=5 -S < %s | FileCheck %s --check-prefixes=CHECK,NOT_CGSCC_NPM,NOT_CGSCC_OPM,NOT_TUNIT_NPM,IS__TUNIT____,IS________OPM,IS__TUNIT_OPM
; RUN: opt -aa-pipeline=basic-aa -passes=attributor -attributor-manifest-internal  -attributor-max-iterations-verify -attributor-annotate-decl-cs -attributor-max-iterations=5 -S < %s | FileCheck %s --check-prefixes=CHECK,NOT_CGSCC_OPM,NOT_CGSCC_NPM,NOT_TUNIT_OPM,IS__TUNIT____,IS________NPM,IS__TUNIT_NPM
; RUN: opt -attributor-cgscc -attributor-manifest-internal  -attributor-annotate-decl-cs -S < %s | FileCheck %s --check-prefixes=CHECK,NOT_TUNIT_NPM,NOT_TUNIT_OPM,NOT_CGSCC_NPM,IS__CGSCC____,IS________OPM,IS__CGSCC_OPM
; RUN: opt -aa-pipeline=basic-aa -passes=attributor-cgscc -attributor-manifest-internal  -attributor-annotate-decl-cs -S < %s | FileCheck %s --check-prefixes=CHECK,NOT_TUNIT_NPM,NOT_TUNIT_OPM,NOT_CGSCC_OPM,IS__CGSCC____,IS________NPM,IS__CGSCC_NPM

; Don't constant-propagate byval pointers, since they are not pointers!
; PR5038
%struct.MYstr = type { i8, i32 }
@mystr = internal global %struct.MYstr zeroinitializer ; <%struct.MYstr*> [#uses=3]
define internal void @vfu1(%struct.MYstr* byval align 4 %u) nounwind {
; IS__CGSCC_OPM-LABEL: define {{[^@]+}}@vfu1
; IS__CGSCC_OPM-SAME: (%struct.MYstr* noalias nocapture nofree nonnull writeonly byval align 4 dereferenceable(1) [[U:%.*]])
; IS__CGSCC_OPM-NEXT:  entry:
; IS__CGSCC_OPM-NEXT:    [[TMP0:%.*]] = getelementptr [[STRUCT_MYSTR:%.*]], %struct.MYstr* [[U]], i32 0, i32 1
; IS__CGSCC_OPM-NEXT:    store i32 99, i32* [[TMP0]], align 4
; IS__CGSCC_OPM-NEXT:    [[TMP1:%.*]] = getelementptr [[STRUCT_MYSTR]], %struct.MYstr* [[U]], i32 0, i32 0
; IS__CGSCC_OPM-NEXT:    store i8 97, i8* [[TMP1]], align 4
; IS__CGSCC_OPM-NEXT:    br label [[RETURN:%.*]]
; IS__CGSCC_OPM:       return:
; IS__CGSCC_OPM-NEXT:    ret void
;
; IS__CGSCC_NPM-LABEL: define {{[^@]+}}@vfu1
; IS__CGSCC_NPM-SAME: (i8 [[TMP0:%.*]], i32 [[TMP1:%.*]])
; IS__CGSCC_NPM-NEXT:  entry:
; IS__CGSCC_NPM-NEXT:    [[U_PRIV:%.*]] = alloca [[STRUCT_MYSTR:%.*]]
; IS__CGSCC_NPM-NEXT:    [[U_PRIV_CAST:%.*]] = bitcast %struct.MYstr* [[U_PRIV]] to i8*
; IS__CGSCC_NPM-NEXT:    store i8 [[TMP0]], i8* [[U_PRIV_CAST]]
; IS__CGSCC_NPM-NEXT:    [[U_PRIV_0_1:%.*]] = getelementptr [[STRUCT_MYSTR]], %struct.MYstr* [[U_PRIV]], i32 0, i32 1
; IS__CGSCC_NPM-NEXT:    store i32 [[TMP1]], i32* [[U_PRIV_0_1]], align 4
; IS__CGSCC_NPM-NEXT:    [[TMP2:%.*]] = getelementptr [[STRUCT_MYSTR]], %struct.MYstr* [[U_PRIV]], i32 0, i32 1
; IS__CGSCC_NPM-NEXT:    store i32 99, i32* [[TMP2]], align 4
; IS__CGSCC_NPM-NEXT:    [[TMP3:%.*]] = getelementptr [[STRUCT_MYSTR]], %struct.MYstr* [[U_PRIV]], i32 0, i32 0
; IS__CGSCC_NPM-NEXT:    store i8 97, i8* [[TMP3]], align 4
; IS__CGSCC_NPM-NEXT:    br label [[RETURN:%.*]]
; IS__CGSCC_NPM:       return:
; IS__CGSCC_NPM-NEXT:    ret void
;
entry:
  %0 = getelementptr %struct.MYstr, %struct.MYstr* %u, i32 0, i32 1 ; <i32*> [#uses=1]
  store i32 99, i32* %0, align 4
  %1 = getelementptr %struct.MYstr, %struct.MYstr* %u, i32 0, i32 0 ; <i8*> [#uses=1]
  store i8 97, i8* %1, align 4
  br label %return

return:                                           ; preds = %entry
  ret void
}

define internal i32 @vfu2(%struct.MYstr* byval align 4 %u) nounwind readonly {
; IS__TUNIT_OPM-LABEL: define {{[^@]+}}@vfu2
; IS__TUNIT_OPM-SAME: (%struct.MYstr* noalias nocapture nofree nonnull readonly byval align 8 dereferenceable(8) [[U:%.*]])
; IS__TUNIT_OPM-NEXT:  entry:
; IS__TUNIT_OPM-NEXT:    [[TMP0:%.*]] = getelementptr [[STRUCT_MYSTR:%.*]], %struct.MYstr* @mystr, i32 0, i32 1
; IS__TUNIT_OPM-NEXT:    [[TMP1:%.*]] = load i32, i32* [[TMP0]], align 4
; IS__TUNIT_OPM-NEXT:    [[TMP2:%.*]] = getelementptr [[STRUCT_MYSTR]], %struct.MYstr* @mystr, i32 0, i32 0
; IS__TUNIT_OPM-NEXT:    [[TMP3:%.*]] = load i8, i8* [[TMP2]], align 8
; IS__TUNIT_OPM-NEXT:    [[TMP4:%.*]] = zext i8 [[TMP3]] to i32
; IS__TUNIT_OPM-NEXT:    [[TMP5:%.*]] = add i32 [[TMP4]], [[TMP1]]
; IS__TUNIT_OPM-NEXT:    ret i32 [[TMP5]]
;
; IS__TUNIT_NPM-LABEL: define {{[^@]+}}@vfu2
; IS__TUNIT_NPM-SAME: (i8 [[TMP0:%.*]], i32 [[TMP1:%.*]])
; IS__TUNIT_NPM-NEXT:  entry:
; IS__TUNIT_NPM-NEXT:    [[U_PRIV:%.*]] = alloca [[STRUCT_MYSTR:%.*]]
; IS__TUNIT_NPM-NEXT:    [[U_PRIV_CAST:%.*]] = bitcast %struct.MYstr* [[U_PRIV]] to i8*
; IS__TUNIT_NPM-NEXT:    store i8 [[TMP0]], i8* [[U_PRIV_CAST]]
; IS__TUNIT_NPM-NEXT:    [[U_PRIV_0_1:%.*]] = getelementptr [[STRUCT_MYSTR]], %struct.MYstr* [[U_PRIV]], i32 0, i32 1
; IS__TUNIT_NPM-NEXT:    store i32 [[TMP1]], i32* [[U_PRIV_0_1]]
; IS__TUNIT_NPM-NEXT:    [[TMP2:%.*]] = getelementptr [[STRUCT_MYSTR]], %struct.MYstr* @mystr, i32 0, i32 1
; IS__TUNIT_NPM-NEXT:    [[TMP3:%.*]] = load i32, i32* [[TMP2]], align 4
; IS__TUNIT_NPM-NEXT:    [[TMP4:%.*]] = getelementptr [[STRUCT_MYSTR]], %struct.MYstr* @mystr, i32 0, i32 0
; IS__TUNIT_NPM-NEXT:    [[TMP5:%.*]] = load i8, i8* [[TMP4]], align 8
; IS__TUNIT_NPM-NEXT:    [[TMP6:%.*]] = zext i8 [[TMP5]] to i32
; IS__TUNIT_NPM-NEXT:    [[TMP7:%.*]] = add i32 [[TMP6]], [[TMP3]]
; IS__TUNIT_NPM-NEXT:    ret i32 [[TMP7]]
;
; IS__CGSCC____-LABEL: define {{[^@]+}}@vfu2()
; IS__CGSCC____-NEXT:  entry:
; IS__CGSCC____-NEXT:    [[TMP0:%.*]] = getelementptr [[STRUCT_MYSTR:%.*]], %struct.MYstr* @mystr, i32 0, i32 1
; IS__CGSCC____-NEXT:    [[TMP1:%.*]] = load i32, i32* [[TMP0]], align 4
; IS__CGSCC____-NEXT:    [[TMP2:%.*]] = getelementptr [[STRUCT_MYSTR]], %struct.MYstr* @mystr, i32 0, i32 0
; IS__CGSCC____-NEXT:    [[TMP3:%.*]] = load i8, i8* [[TMP2]], align 4
; IS__CGSCC____-NEXT:    [[TMP4:%.*]] = zext i8 [[TMP3]] to i32
; IS__CGSCC____-NEXT:    [[TMP5:%.*]] = add i32 [[TMP4]], [[TMP1]]
; IS__CGSCC____-NEXT:    ret i32 [[TMP5]]
;
entry:
  %0 = getelementptr %struct.MYstr, %struct.MYstr* %u, i32 0, i32 1 ; <i32*> [#uses=1]
  %1 = load i32, i32* %0
  %2 = getelementptr %struct.MYstr, %struct.MYstr* %u, i32 0, i32 0 ; <i8*> [#uses=1]
  %3 = load i8, i8* %2
  %4 = zext i8 %3 to i32
  %5 = add i32 %4, %1
  ret i32 %5
}

define i32 @unions() nounwind {
; IS__TUNIT_OPM-LABEL: define {{[^@]+}}@unions()
; IS__TUNIT_OPM-NEXT:  entry:
; IS__TUNIT_OPM-NEXT:    [[RESULT:%.*]] = call i32 @vfu2(%struct.MYstr* nocapture nofree nonnull readonly byval align 8 dereferenceable(8) @mystr)
; IS__TUNIT_OPM-NEXT:    ret i32 [[RESULT]]
;
; IS__TUNIT_NPM-LABEL: define {{[^@]+}}@unions()
; IS__TUNIT_NPM-NEXT:  entry:
; IS__TUNIT_NPM-NEXT:    [[MYSTR_CAST:%.*]] = bitcast %struct.MYstr* @mystr to i8*
; IS__TUNIT_NPM-NEXT:    [[TMP0:%.*]] = load i8, i8* [[MYSTR_CAST]], align 1
; IS__TUNIT_NPM-NEXT:    [[MYSTR_0_1:%.*]] = getelementptr [[STRUCT_MYSTR:%.*]], %struct.MYstr* @mystr, i32 0, i32 1
; IS__TUNIT_NPM-NEXT:    [[TMP1:%.*]] = load i32, i32* [[MYSTR_0_1]], align 1
; IS__TUNIT_NPM-NEXT:    [[RESULT:%.*]] = call i32 @vfu2(i8 [[TMP0]], i32 [[TMP1]])
; IS__TUNIT_NPM-NEXT:    ret i32 [[RESULT]]
;
; IS__CGSCC____-LABEL: define {{[^@]+}}@unions()
; IS__CGSCC____-NEXT:  entry:
; IS__CGSCC____-NEXT:    [[RESULT:%.*]] = call i32 @vfu2()
; IS__CGSCC____-NEXT:    ret i32 [[RESULT]]
;
entry:
  call void @vfu1(%struct.MYstr* byval align 4 @mystr) nounwind
  %result = call i32 @vfu2(%struct.MYstr* byval align 4 @mystr) nounwind
  ret i32 %result
}

define internal i32 @vfu2_v2(%struct.MYstr* byval align 4 %u) nounwind readonly {
; IS__TUNIT_OPM-LABEL: define {{[^@]+}}@vfu2_v2
; IS__TUNIT_OPM-SAME: (%struct.MYstr* noalias nocapture nofree nonnull byval align 8 dereferenceable(8) [[U:%.*]])
; IS__TUNIT_OPM-NEXT:  entry:
; IS__TUNIT_OPM-NEXT:    [[Z:%.*]] = getelementptr [[STRUCT_MYSTR:%.*]], %struct.MYstr* [[U]], i32 0, i32 1
; IS__TUNIT_OPM-NEXT:    store i32 99, i32* [[Z]], align 4
; IS__TUNIT_OPM-NEXT:    [[TMP0:%.*]] = getelementptr [[STRUCT_MYSTR]], %struct.MYstr* [[U]], i32 0, i32 1
; IS__TUNIT_OPM-NEXT:    [[TMP1:%.*]] = load i32, i32* [[TMP0]], align 4
; IS__TUNIT_OPM-NEXT:    [[TMP2:%.*]] = getelementptr [[STRUCT_MYSTR]], %struct.MYstr* [[U]], i32 0, i32 0
; IS__TUNIT_OPM-NEXT:    [[TMP3:%.*]] = load i8, i8* [[TMP2]], align 8
; IS__TUNIT_OPM-NEXT:    [[TMP4:%.*]] = zext i8 [[TMP3]] to i32
; IS__TUNIT_OPM-NEXT:    [[TMP5:%.*]] = add i32 [[TMP4]], [[TMP1]]
; IS__TUNIT_OPM-NEXT:    ret i32 [[TMP5]]
;
; IS__TUNIT_NPM-LABEL: define {{[^@]+}}@vfu2_v2
; IS__TUNIT_NPM-SAME: (i8 [[TMP0:%.*]], i32 [[TMP1:%.*]])
; IS__TUNIT_NPM-NEXT:  entry:
; IS__TUNIT_NPM-NEXT:    [[U_PRIV:%.*]] = alloca [[STRUCT_MYSTR:%.*]]
; IS__TUNIT_NPM-NEXT:    [[U_PRIV_CAST:%.*]] = bitcast %struct.MYstr* [[U_PRIV]] to i8*
; IS__TUNIT_NPM-NEXT:    store i8 [[TMP0]], i8* [[U_PRIV_CAST]]
; IS__TUNIT_NPM-NEXT:    [[U_PRIV_0_1:%.*]] = getelementptr [[STRUCT_MYSTR]], %struct.MYstr* [[U_PRIV]], i32 0, i32 1
; IS__TUNIT_NPM-NEXT:    store i32 [[TMP1]], i32* [[U_PRIV_0_1]]
; IS__TUNIT_NPM-NEXT:    [[Z:%.*]] = getelementptr [[STRUCT_MYSTR]], %struct.MYstr* [[U_PRIV]], i32 0, i32 1
; IS__TUNIT_NPM-NEXT:    store i32 99, i32* [[Z]], align 4
; IS__TUNIT_NPM-NEXT:    [[TMP2:%.*]] = getelementptr [[STRUCT_MYSTR]], %struct.MYstr* [[U_PRIV]], i32 0, i32 1
; IS__TUNIT_NPM-NEXT:    [[TMP3:%.*]] = load i32, i32* [[TMP2]], align 4
; IS__TUNIT_NPM-NEXT:    [[TMP4:%.*]] = getelementptr [[STRUCT_MYSTR]], %struct.MYstr* [[U_PRIV]], i32 0, i32 0
; IS__TUNIT_NPM-NEXT:    [[TMP5:%.*]] = load i8, i8* [[TMP4]], align 8
; IS__TUNIT_NPM-NEXT:    [[TMP6:%.*]] = zext i8 [[TMP5]] to i32
; IS__TUNIT_NPM-NEXT:    [[TMP7:%.*]] = add i32 [[TMP6]], [[TMP3]]
; IS__TUNIT_NPM-NEXT:    ret i32 [[TMP7]]
;
; IS__CGSCC_OPM-LABEL: define {{[^@]+}}@vfu2_v2
; IS__CGSCC_OPM-SAME: (%struct.MYstr* noalias nocapture nofree nonnull byval align 4 dereferenceable(1) [[U:%.*]])
; IS__CGSCC_OPM-NEXT:  entry:
; IS__CGSCC_OPM-NEXT:    [[Z:%.*]] = getelementptr [[STRUCT_MYSTR:%.*]], %struct.MYstr* [[U]], i32 0, i32 1
; IS__CGSCC_OPM-NEXT:    store i32 99, i32* [[Z]], align 4
; IS__CGSCC_OPM-NEXT:    [[TMP0:%.*]] = getelementptr [[STRUCT_MYSTR]], %struct.MYstr* [[U]], i32 0, i32 1
; IS__CGSCC_OPM-NEXT:    [[TMP1:%.*]] = load i32, i32* [[TMP0]], align 4
; IS__CGSCC_OPM-NEXT:    [[TMP2:%.*]] = getelementptr [[STRUCT_MYSTR]], %struct.MYstr* [[U]], i32 0, i32 0
; IS__CGSCC_OPM-NEXT:    [[TMP3:%.*]] = load i8, i8* [[TMP2]], align 4
; IS__CGSCC_OPM-NEXT:    [[TMP4:%.*]] = zext i8 [[TMP3]] to i32
; IS__CGSCC_OPM-NEXT:    [[TMP5:%.*]] = add i32 [[TMP4]], [[TMP1]]
; IS__CGSCC_OPM-NEXT:    ret i32 [[TMP5]]
;
; IS__CGSCC_NPM-LABEL: define {{[^@]+}}@vfu2_v2
; IS__CGSCC_NPM-SAME: (i8 [[TMP0:%.*]], i32 [[TMP1:%.*]])
; IS__CGSCC_NPM-NEXT:  entry:
; IS__CGSCC_NPM-NEXT:    [[U_PRIV:%.*]] = alloca [[STRUCT_MYSTR:%.*]]
; IS__CGSCC_NPM-NEXT:    [[U_PRIV_CAST:%.*]] = bitcast %struct.MYstr* [[U_PRIV]] to i8*
; IS__CGSCC_NPM-NEXT:    store i8 [[TMP0]], i8* [[U_PRIV_CAST]]
; IS__CGSCC_NPM-NEXT:    [[U_PRIV_0_1:%.*]] = getelementptr [[STRUCT_MYSTR]], %struct.MYstr* [[U_PRIV]], i32 0, i32 1
; IS__CGSCC_NPM-NEXT:    store i32 [[TMP1]], i32* [[U_PRIV_0_1]], align 4
; IS__CGSCC_NPM-NEXT:    [[Z:%.*]] = getelementptr [[STRUCT_MYSTR]], %struct.MYstr* [[U_PRIV]], i32 0, i32 1
; IS__CGSCC_NPM-NEXT:    store i32 99, i32* [[Z]], align 4
; IS__CGSCC_NPM-NEXT:    [[TMP2:%.*]] = getelementptr [[STRUCT_MYSTR]], %struct.MYstr* [[U_PRIV]], i32 0, i32 1
; IS__CGSCC_NPM-NEXT:    [[TMP3:%.*]] = load i32, i32* [[TMP2]], align 4
; IS__CGSCC_NPM-NEXT:    [[TMP4:%.*]] = getelementptr [[STRUCT_MYSTR]], %struct.MYstr* [[U_PRIV]], i32 0, i32 0
; IS__CGSCC_NPM-NEXT:    [[TMP5:%.*]] = load i8, i8* [[TMP4]], align 4
; IS__CGSCC_NPM-NEXT:    [[TMP6:%.*]] = zext i8 [[TMP5]] to i32
; IS__CGSCC_NPM-NEXT:    [[TMP7:%.*]] = add i32 [[TMP6]], [[TMP3]]
; IS__CGSCC_NPM-NEXT:    ret i32 [[TMP7]]
;
entry:
  %z = getelementptr %struct.MYstr, %struct.MYstr* %u, i32 0, i32 1
  store i32 99, i32* %z, align 4
  %0 = getelementptr %struct.MYstr, %struct.MYstr* %u, i32 0, i32 1 ; <i32*> [#uses=1]
  %1 = load i32, i32* %0
  %2 = getelementptr %struct.MYstr, %struct.MYstr* %u, i32 0, i32 0 ; <i8*> [#uses=1]
  %3 = load i8, i8* %2
  %4 = zext i8 %3 to i32
  %5 = add i32 %4, %1
  ret i32 %5
}

define i32 @unions_v2() nounwind {
; IS__TUNIT_OPM-LABEL: define {{[^@]+}}@unions_v2()
; IS__TUNIT_OPM-NEXT:  entry:
; IS__TUNIT_OPM-NEXT:    [[RESULT:%.*]] = call i32 @vfu2_v2(%struct.MYstr* nocapture nofree nonnull readonly byval align 8 dereferenceable(8) @mystr)
; IS__TUNIT_OPM-NEXT:    ret i32 [[RESULT]]
;
; IS__TUNIT_NPM-LABEL: define {{[^@]+}}@unions_v2()
; IS__TUNIT_NPM-NEXT:  entry:
; IS__TUNIT_NPM-NEXT:    [[MYSTR_CAST:%.*]] = bitcast %struct.MYstr* @mystr to i8*
; IS__TUNIT_NPM-NEXT:    [[TMP0:%.*]] = load i8, i8* [[MYSTR_CAST]], align 1
; IS__TUNIT_NPM-NEXT:    [[MYSTR_0_1:%.*]] = getelementptr [[STRUCT_MYSTR:%.*]], %struct.MYstr* @mystr, i32 0, i32 1
; IS__TUNIT_NPM-NEXT:    [[TMP1:%.*]] = load i32, i32* [[MYSTR_0_1]], align 1
; IS__TUNIT_NPM-NEXT:    [[RESULT:%.*]] = call i32 @vfu2_v2(i8 [[TMP0]], i32 [[TMP1]])
; IS__TUNIT_NPM-NEXT:    ret i32 [[RESULT]]
;
; IS__CGSCC_OPM-LABEL: define {{[^@]+}}@unions_v2()
; IS__CGSCC_OPM-NEXT:  entry:
; IS__CGSCC_OPM-NEXT:    [[RESULT:%.*]] = call i32 @vfu2_v2(%struct.MYstr* noalias nocapture nofree nonnull readnone byval align 8 dereferenceable(8) @mystr)
; IS__CGSCC_OPM-NEXT:    ret i32 [[RESULT]]
;
; IS__CGSCC_NPM-LABEL: define {{[^@]+}}@unions_v2()
; IS__CGSCC_NPM-NEXT:  entry:
; IS__CGSCC_NPM-NEXT:    [[MYSTR_CAST1:%.*]] = bitcast %struct.MYstr* @mystr to i8*
; IS__CGSCC_NPM-NEXT:    [[TMP0:%.*]] = load i8, i8* [[MYSTR_CAST1]], align 8
; IS__CGSCC_NPM-NEXT:    [[MYSTR_0_12:%.*]] = getelementptr [[STRUCT_MYSTR:%.*]], %struct.MYstr* @mystr, i32 0, i32 1
; IS__CGSCC_NPM-NEXT:    [[TMP1:%.*]] = load i32, i32* [[MYSTR_0_12]], align 1
; IS__CGSCC_NPM-NEXT:    [[RESULT:%.*]] = call i32 @vfu2_v2(i8 [[TMP0]], i32 [[TMP1]])
; IS__CGSCC_NPM-NEXT:    ret i32 [[RESULT]]
;
entry:
  call void @vfu1(%struct.MYstr* byval align 4 @mystr) nounwind
  %result = call i32 @vfu2_v2(%struct.MYstr* byval align 4 @mystr) nounwind
  ret i32 %result
}
