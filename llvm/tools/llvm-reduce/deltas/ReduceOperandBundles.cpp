//===- ReduceOperandBundes.cpp - Specialized Delta Pass -------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file implements a function which calls the Generic Delta pass in order
// to reduce uninteresting operand bundes from calls.
//
//===----------------------------------------------------------------------===//

#include "ReduceOperandBundles.h"
#include "Delta.h"
#include "TestRunner.h"
#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/Sequence.h"
#include "llvm/ADT/iterator_range.h"
#include "llvm/IR/InstVisitor.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/Support/raw_ostream.h"
#include <algorithm>
#include <iterator>
#include <vector>

namespace llvm {
class Module;
} // namespace llvm

using namespace llvm;

namespace {

/// Given ChunksToKeep, produce a map of calls and indexes of operand bundles
/// to be preserved for each call.
class OperandBundleRemapper : public InstVisitor<OperandBundleRemapper> {
  Oracle O;

public:
  DenseMap<CallBase *, std::vector<unsigned>> CallsToRefine;

  explicit OperandBundleRemapper(ArrayRef<Chunk> ChunksToKeep)
      : O(ChunksToKeep) {}

  /// So far only CallBase sub-classes can have operand bundles.
  /// Let's see which of the operand bundles of this call are to be kept.
  void visitCallBase(CallBase &Call) {
    if (!Call.hasOperandBundles())
      return; // No bundles to begin with.

    // Insert this call into map, we will likely want to rebuild it.
    auto &OperandBundlesToKeepIndexes = CallsToRefine[&Call];
    OperandBundlesToKeepIndexes.reserve(Call.getNumOperandBundles());

    // Enumerate every operand bundle on this call.
    for_each(seq(0U, Call.getNumOperandBundles()), [&](unsigned BundleIndex) {
      if (O.shouldKeep()) // Should we keep this one?
        OperandBundlesToKeepIndexes.emplace_back(BundleIndex);
    });
  }
};

struct OperandBundleCounter : public InstVisitor<OperandBundleCounter> {
  /// How many features (in this case, operand bundles) did we count, total?
  int OperandBundeCount = 0;

  /// So far only CallBase sub-classes can have operand bundles.
  void visitCallBase(CallBase &Call) {
    // Just accumulate the total number of operand bundles.
    OperandBundeCount += Call.getNumOperandBundles();
  }
};

} // namespace

static void maybeRewriteCallWithDifferentBundles(
    CallBase *OrigCall, ArrayRef<unsigned> OperandBundlesToKeepIndexes) {
  if (OperandBundlesToKeepIndexes.size() == OrigCall->getNumOperandBundles())
    return; // Not modifying operand bundles of this call after all.

  std::vector<OperandBundleDef> NewBundles;
  NewBundles.reserve(OperandBundlesToKeepIndexes.size());

  // Actually copy over the bundles that we want to keep.
  transform(OperandBundlesToKeepIndexes, std::back_inserter(NewBundles),
            [OrigCall](unsigned Index) {
              return OperandBundleDef(OrigCall->getOperandBundleAt(Index));
            });

  // Finally actually replace the bundles on the call.
  CallBase *NewCall = CallBase::Create(OrigCall, NewBundles, OrigCall);
  OrigCall->replaceAllUsesWith(NewCall);
  OrigCall->eraseFromParent();
}

/// Removes out-of-chunk operand bundles from calls.
static void extractOperandBundesFromModule(std::vector<Chunk> ChunksToKeep,
                                           Module *Program) {
  OperandBundleRemapper R(ChunksToKeep);
  R.visit(Program);

  for_each(R.CallsToRefine, [](const auto &P) {
    return maybeRewriteCallWithDifferentBundles(P.first, P.second);
  });
}

/// Counts the amount of operand bundles.
static int countOperandBundes(Module *Program) {
  OperandBundleCounter C;

  // TODO: Silence index with --quiet flag
  outs() << "----------------------------\n";
  C.visit(Program);
  outs() << "Number of operand bundles: " << C.OperandBundeCount << "\n";

  return C.OperandBundeCount;
}

void llvm::reduceOperandBundesDeltaPass(TestRunner &Test) {
  outs() << "*** Reducing OperandBundes...\n";
  int OperandBundeCount = countOperandBundes(Test.getProgram());
  runDeltaPass(Test, OperandBundeCount, extractOperandBundesFromModule);
}
