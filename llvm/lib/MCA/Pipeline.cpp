//===--------------------- Pipeline.cpp -------------------------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
/// \file
///
/// This file implements an ordered container of stages that simulate the
/// pipeline of a hardware backend.
///
//===----------------------------------------------------------------------===//

#include "llvm/MCA/Pipeline.h"
#include "llvm/MCA/HWEventListener.h"
#include "llvm/Support/Debug.h"

namespace llvm {
namespace mca {

#define DEBUG_TYPE "llvm-mca"

void Pipeline::addEventListener(HWEventListener *Listener) {
  if (Listener)
    Listeners.insert(Listener);
  for (auto &S : Stages)
    S->addListener(Listener);
}

bool Pipeline::hasWorkToProcess() {
  return any_of(Stages, [](const std::unique_ptr<Stage> &S) {
    return S->hasWorkToComplete();
  });
}

Expected<unsigned> Pipeline::run() {
  assert(!Stages.empty() && "Unexpected empty pipeline found!");

  do {
    notifyCycleBegin();
    if (Error Err = runCycle())
      return std::move(Err);
    notifyCycleEnd();
    ++Cycles;
  } while (hasWorkToProcess());

  return Cycles;
}

Error Pipeline::runCycle() {
  Error Err = ErrorSuccess();
  // Update stages before we start processing new instructions.
  for (auto I = Stages.rbegin(), E = Stages.rend(); I != E && !Err; ++I) {
    const std::unique_ptr<Stage> &S = *I;
    Err = S->cycleStart();
  }

  // Now fetch and execute new instructions.
  InstRef IR;
  Stage &FirstStage = *Stages[0];
  while (!Err && FirstStage.isAvailable(IR))
    Err = FirstStage.execute(IR);

  // Update stages in preparation for a new cycle.
  for (auto I = Stages.rbegin(), E = Stages.rend(); I != E && !Err; ++I) {
    const std::unique_ptr<Stage> &S = *I;
    Err = S->cycleEnd();
  }

  return Err;
}

void Pipeline::appendStage(std::unique_ptr<Stage> S) {
  assert(S && "Invalid null stage in input!");
  if (!Stages.empty()) {
    Stage *Last = Stages.back().get();
    Last->setNextInSequence(S.get());
  }

  Stages.push_back(std::move(S));
}

void Pipeline::notifyCycleBegin() {
  LLVM_DEBUG(dbgs() << "[E] Cycle begin: " << Cycles << '\n');
  for (HWEventListener *Listener : Listeners)
    Listener->onCycleBegin();
}

void Pipeline::notifyCycleEnd() {
  LLVM_DEBUG(dbgs() << "[E] Cycle end: " << Cycles << "\n\n");
  for (HWEventListener *Listener : Listeners)
    Listener->onCycleEnd();
}
} // namespace mca.
} // namespace llvm
