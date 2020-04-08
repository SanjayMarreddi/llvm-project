//===-- Implementation header for thrd_join function ------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIBC_SRC_THREADS_LINUX_THRD_JOIN_H
#define LLVM_LIBC_SRC_THREADS_LINUX_THRD_JOIN_H

#include "include/threads.h"

namespace __llvm_libc {

int thrd_join(thrd_t *thread, int *retval);

} // namespace __llvm_libc

#endif // LLVM_LIBC_SRC_THREADS_LINUX_THRD_JOIN_H
