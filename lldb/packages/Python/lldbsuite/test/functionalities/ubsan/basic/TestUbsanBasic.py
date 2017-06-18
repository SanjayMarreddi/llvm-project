"""
Tests basic UndefinedBehaviorSanitizer support (detecting an alignment error).
"""

import os
import time
import lldb
from lldbsuite.test.lldbtest import *
from lldbsuite.test.decorators import *
import lldbsuite.test.lldbutil as lldbutil
import json


class UbsanBasicTestCase(TestBase):

    mydir = TestBase.compute_mydir(__file__)

    @skipUnlessUndefinedBehaviorSanitizer
    def test(self):
        self.build()
        self.ubsan_tests()

    def setUp(self):
        # Call super's setUp().
        TestBase.setUp(self)
        self.line_align = line_number('main.c', '// align line')

    def ubsan_tests(self):
        # Load the test
        exe = os.path.join(os.getcwd(), "a.out")
        self.expect(
            "file " + exe,
            patterns=["Current executable set to .*a.out"])

        self.runCmd("run")

        process = self.dbg.GetSelectedTarget().process
        thread = process.GetSelectedThread()
        frame = thread.GetSelectedFrame()

        # the stop reason of the thread should be breakpoint.
        self.expect("thread list", "A ubsan issue should be detected",
                    substrs=['stopped', 'stop reason ='])

        stop_reason = thread.GetStopReason()
        self.assertEqual(stop_reason, lldb.eStopReasonInstrumentation)

        # test that the UBSan dylib is present
        self.expect(
            "image lookup -n __ubsan_on_report",
            "__ubsan_on_report should be present",
            substrs=['1 match found'])

        # We should be stopped in __ubsan_on_report
        self.assertTrue("__ubsan_on_report" in frame.GetFunctionName())

        # The stopped thread backtrace should contain either 'align line'
        found = False
        for i in range(thread.GetNumFrames()):
            frame = thread.GetFrameAtIndex(i)
            if frame.GetLineEntry().GetFileSpec().GetFilename() == "main.c":
                if frame.GetLineEntry().GetLine() == self.line_align:
                    found = True
        self.assertTrue(found)

        backtraces = thread.GetStopReasonExtendedBacktraces(
            lldb.eInstrumentationRuntimeTypeUndefinedBehaviorSanitizer)
        self.assertTrue(backtraces.GetSize() == 1)

        self.expect(
            "thread info -s",
            "The extended stop info should contain the UBSan provided fields",
            substrs=[
                "instrumentation_class",
                "memory_address",
                "description",
                "filename",
                "line",
                "col"])

        output_lines = self.res.GetOutput().split('\n')
        json_line = '\n'.join(output_lines[2:])
        data = json.loads(json_line)

        self.assertEqual(data["instrumentation_class"], "UndefinedBehaviorSanitizer")
        self.assertEqual(data["description"], "misaligned-pointer-use")
        self.assertEqual(data["filename"], "main.c")
        self.assertEqual(data["line"], self.line_align)

        self.runCmd("continue")
