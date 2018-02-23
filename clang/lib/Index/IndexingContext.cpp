//===- IndexingContext.cpp - Indexing context data ------------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "IndexingContext.h"
#include "clang/Index/IndexDataConsumer.h"
#include "clang/AST/ASTContext.h"
#include "clang/AST/DeclTemplate.h"
#include "clang/AST/DeclObjC.h"
#include "clang/Basic/SourceManager.h"

using namespace clang;
using namespace index;

static bool isGeneratedDecl(const Decl *D) {
  if (auto *attr = D->getAttr<ExternalSourceSymbolAttr>()) {
    return attr->getGeneratedDeclaration();
  }
  return false;
}

bool IndexingContext::shouldIndex(const Decl *D) {
  return !isGeneratedDecl(D);
}

const LangOptions &IndexingContext::getLangOpts() const {
  return Ctx->getLangOpts();
}

bool IndexingContext::shouldIndexFunctionLocalSymbols() const {
  return IndexOpts.IndexFunctionLocals;
}

bool IndexingContext::handleDecl(const Decl *D,
                                 SymbolRoleSet Roles,
                                 ArrayRef<SymbolRelation> Relations) {
  return handleDecl(D, D->getLocation(), Roles, Relations);
}

bool IndexingContext::handleDecl(const Decl *D, SourceLocation Loc,
                                 SymbolRoleSet Roles,
                                 ArrayRef<SymbolRelation> Relations,
                                 const DeclContext *DC) {
  if (!DC)
    DC = D->getDeclContext();

  const Decl *OrigD = D;
  if (isa<ObjCPropertyImplDecl>(D)) {
    D = cast<ObjCPropertyImplDecl>(D)->getPropertyDecl();
  }
  return handleDeclOccurrence(D, Loc, /*IsRef=*/false, cast<Decl>(DC),
                              Roles, Relations,
                              nullptr, OrigD, DC);
}

bool IndexingContext::handleReference(const NamedDecl *D, SourceLocation Loc,
                                      const NamedDecl *Parent,
                                      const DeclContext *DC,
                                      SymbolRoleSet Roles,
                                      ArrayRef<SymbolRelation> Relations,
                                      const Expr *RefE,
                                      const Decl *RefD) {
  if (!shouldIndexFunctionLocalSymbols() && isFunctionLocalSymbol(D))
    return true;

  if (isa<NonTypeTemplateParmDecl>(D) || isa<TemplateTypeParmDecl>(D))
    return true;
    
  return handleDeclOccurrence(D, Loc, /*IsRef=*/true, Parent, Roles, Relations,
                              RefE, RefD, DC);
}

bool IndexingContext::importedModule(const ImportDecl *ImportD) {
  SourceLocation Loc;
  auto IdLocs = ImportD->getIdentifierLocs();
  if (!IdLocs.empty())
    Loc = IdLocs.front();
  else
    Loc = ImportD->getLocation();
  SourceManager &SM = Ctx->getSourceManager();
  Loc = SM.getFileLoc(Loc);
  if (Loc.isInvalid())
    return true;

  FileID FID;
  unsigned Offset;
  std::tie(FID, Offset) = SM.getDecomposedLoc(Loc);
  if (FID.isInvalid())
    return true;

  if (isSystemFile(FID)) {
    switch (IndexOpts.SystemSymbolFilter) {
    case IndexingOptions::SystemSymbolFilterKind::None:
      return true;
    case IndexingOptions::SystemSymbolFilterKind::DeclarationsOnly:
    case IndexingOptions::SystemSymbolFilterKind::All:
      break;
    }
  }

  SymbolRoleSet Roles = (unsigned)SymbolRole::Declaration;
  if (ImportD->isImplicit())
    Roles |= (unsigned)SymbolRole::Implicit;

  return DataConsumer.handleModuleOccurence(ImportD, Roles, FID, Offset);
}

bool IndexingContext::isTemplateImplicitInstantiation(const Decl *D) {
  TemplateSpecializationKind TKind = TSK_Undeclared;
  if (const ClassTemplateSpecializationDecl *
      SD = dyn_cast<ClassTemplateSpecializationDecl>(D)) {
    TKind = SD->getSpecializationKind();
  } else if (const FunctionDecl *FD = dyn_cast<FunctionDecl>(D)) {
    TKind = FD->getTemplateSpecializationKind();
  } else if (auto *VD = dyn_cast<VarDecl>(D)) {
    TKind = VD->getTemplateSpecializationKind();
  } else if (const auto *RD = dyn_cast<CXXRecordDecl>(D)) {
    if (RD->getInstantiatedFromMemberClass())
      TKind = RD->getTemplateSpecializationKind();
  } else if (const auto *ED = dyn_cast<EnumDecl>(D)) {
    if (ED->getInstantiatedFromMemberEnum())
      TKind = ED->getTemplateSpecializationKind();
  } else if (isa<FieldDecl>(D) || isa<TypedefNameDecl>(D) ||
             isa<EnumConstantDecl>(D)) {
    if (const auto *Parent = dyn_cast<Decl>(D->getDeclContext()))
      return isTemplateImplicitInstantiation(Parent);
  }
  switch (TKind) {
    case TSK_Undeclared:
    case TSK_ExplicitSpecialization:
      return false;
    case TSK_ImplicitInstantiation:
    case TSK_ExplicitInstantiationDeclaration:
    case TSK_ExplicitInstantiationDefinition:
      return true;
  }
  llvm_unreachable("invalid TemplateSpecializationKind");
}

bool IndexingContext::shouldIgnoreIfImplicit(const Decl *D) {
  if (isa<ObjCInterfaceDecl>(D))
    return false;
  if (isa<ObjCCategoryDecl>(D))
    return false;
  if (isa<ObjCIvarDecl>(D))
    return false;
  if (isa<ObjCMethodDecl>(D))
    return false;
  if (isa<ImportDecl>(D))
    return false;
  return true;
}

void IndexingContext::setSysrootPath(StringRef path) {
  // Ignore sysroot path if it points to root, otherwise every header will be
  // treated as system one.
  if (path == "/")
    path = StringRef();
  SysrootPath = path;
}

bool IndexingContext::isSystemFile(FileID FID) {
  if (LastFileCheck.first == FID)
    return LastFileCheck.second;

  auto result = [&](bool res) -> bool {
    LastFileCheck = { FID, res };
    return res;
  };

  bool Invalid = false;
  const SrcMgr::SLocEntry &SEntry =
    Ctx->getSourceManager().getSLocEntry(FID, &Invalid);
  if (Invalid || !SEntry.isFile())
    return result(false);

  const SrcMgr::FileInfo &FI = SEntry.getFile();
  if (FI.getFileCharacteristic() != SrcMgr::C_User)
    return result(true);

  auto *CC = FI.getContentCache();
  if (!CC)
    return result(false);
  auto *FE = CC->OrigEntry;
  if (!FE)
    return result(false);

  if (SysrootPath.empty())
    return result(false);

  // Check if directory is in sysroot so that we can consider system headers
  // even the headers found via a user framework search path, pointing inside
  // sysroot.
  auto dirEntry = FE->getDir();
  auto pair = DirEntries.insert(std::make_pair(dirEntry, false));
  bool &isSystemDir = pair.first->second;
  bool wasInserted = pair.second;
  if (wasInserted) {
    isSystemDir = StringRef(dirEntry->getName()).startswith(SysrootPath);
  }
  return result(isSystemDir);
}

static const CXXRecordDecl *
getDeclContextForTemplateInstationPattern(const Decl *D) {
  if (const auto *CTSD =
          dyn_cast<ClassTemplateSpecializationDecl>(D->getDeclContext()))
    return CTSD->getTemplateInstantiationPattern();
  else if (const auto *RD = dyn_cast<CXXRecordDecl>(D->getDeclContext()))
    return RD->getInstantiatedFromMemberClass();
  return nullptr;
}

static const Decl *adjustTemplateImplicitInstantiation(const Decl *D) {
  if (const ClassTemplateSpecializationDecl *
      SD = dyn_cast<ClassTemplateSpecializationDecl>(D)) {
    return SD->getTemplateInstantiationPattern();
  } else if (const FunctionDecl *FD = dyn_cast<FunctionDecl>(D)) {
    return FD->getTemplateInstantiationPattern();
  } else if (auto *VD = dyn_cast<VarDecl>(D)) {
    return VD->getTemplateInstantiationPattern();
  } else if (const auto *RD = dyn_cast<CXXRecordDecl>(D)) {
    return RD->getInstantiatedFromMemberClass();
  } else if (const auto *ED = dyn_cast<EnumDecl>(D)) {
    return ED->getInstantiatedFromMemberEnum();
  } else if (isa<FieldDecl>(D) || isa<TypedefNameDecl>(D)) {
    const auto *ND = cast<NamedDecl>(D);
    if (const CXXRecordDecl *Pattern =
            getDeclContextForTemplateInstationPattern(ND)) {
      for (const NamedDecl *BaseND : Pattern->lookup(ND->getDeclName())) {
        if (BaseND->isImplicit())
          continue;
        if (BaseND->getKind() == ND->getKind())
          return BaseND;
      }
    }
  } else if (const auto *ECD = dyn_cast<EnumConstantDecl>(D)) {
    if (const auto *ED = dyn_cast<EnumDecl>(ECD->getDeclContext())) {
      if (const EnumDecl *Pattern = ED->getInstantiatedFromMemberEnum()) {
        for (const NamedDecl *BaseECD : Pattern->lookup(ECD->getDeclName()))
          return BaseECD;
      }
    }
  }
  return nullptr;
}

static bool isDeclADefinition(const Decl *D, const DeclContext *ContainerDC, ASTContext &Ctx) {
  if (auto VD = dyn_cast<VarDecl>(D))
    return VD->isThisDeclarationADefinition(Ctx);

  if (auto FD = dyn_cast<FunctionDecl>(D))
    return FD->isThisDeclarationADefinition();

  if (auto TD = dyn_cast<TagDecl>(D))
    return TD->isThisDeclarationADefinition();

  if (auto MD = dyn_cast<ObjCMethodDecl>(D))
    return MD->isThisDeclarationADefinition() || isa<ObjCImplDecl>(ContainerDC);

  if (isa<TypedefNameDecl>(D) ||
      isa<EnumConstantDecl>(D) ||
      isa<FieldDecl>(D) ||
      isa<MSPropertyDecl>(D) ||
      isa<ObjCImplDecl>(D) ||
      isa<ObjCPropertyImplDecl>(D))
    return true;

  return false;
}

/// Whether the given NamedDecl should be skipped because it has no name.
static bool shouldSkipNamelessDecl(const NamedDecl *ND) {
  return ND->getDeclName().isEmpty() && !isa<TagDecl>(ND) &&
         !isa<ObjCCategoryDecl>(ND);
}

static const Decl *adjustParent(const Decl *Parent) {
  if (!Parent)
    return nullptr;
  for (;; Parent = cast<Decl>(Parent->getDeclContext())) {
    if (isa<TranslationUnitDecl>(Parent))
      return nullptr;
    if (isa<LinkageSpecDecl>(Parent) || isa<BlockDecl>(Parent))
      continue;
    if (auto NS = dyn_cast<NamespaceDecl>(Parent)) {
      if (NS->isAnonymousNamespace())
        continue;
    } else if (auto RD = dyn_cast<RecordDecl>(Parent)) {
      if (RD->isAnonymousStructOrUnion())
        continue;
    } else if (auto ND = dyn_cast<NamedDecl>(Parent)) {
      if (shouldSkipNamelessDecl(ND))
        continue;
    }
    return Parent;
  }
}

static const Decl *getCanonicalDecl(const Decl *D) {
  D = D->getCanonicalDecl();
  if (auto TD = dyn_cast<TemplateDecl>(D)) {
    if (auto TTD = TD->getTemplatedDecl()) {
      D = TTD;
      assert(D->isCanonicalDecl());
    }
  }

  return D;
}

static bool shouldReportOccurrenceForSystemDeclOnlyMode(
    bool IsRef, SymbolRoleSet Roles, ArrayRef<SymbolRelation> Relations) {
  if (!IsRef)
    return true;

  auto acceptForRelation = [](SymbolRoleSet roles) -> bool {
    bool accept = false;
    applyForEachSymbolRoleInterruptible(roles, [&accept](SymbolRole r) -> bool {
      switch (r) {
      case SymbolRole::RelationChildOf:
      case SymbolRole::RelationBaseOf:
      case SymbolRole::RelationOverrideOf:
      case SymbolRole::RelationExtendedBy:
      case SymbolRole::RelationAccessorOf:
      case SymbolRole::RelationIBTypeOf:
        accept = true;
        return false;
      case SymbolRole::Declaration:
      case SymbolRole::Definition:
      case SymbolRole::Reference:
      case SymbolRole::Read:
      case SymbolRole::Write:
      case SymbolRole::Call:
      case SymbolRole::Dynamic:
      case SymbolRole::AddressOf:
      case SymbolRole::Implicit:
      case SymbolRole::RelationReceivedBy:
      case SymbolRole::RelationCalledBy:
      case SymbolRole::RelationContainedBy:
      case SymbolRole::RelationSpecializationOf:
        return true;
      }
      llvm_unreachable("Unsupported SymbolRole value!");
    });
    return accept;
  };

  for (auto &Rel : Relations) {
    if (acceptForRelation(Rel.Roles))
      return true;
  }

  return false;
}

bool IndexingContext::handleDeclOccurrence(const Decl *D, SourceLocation Loc,
                                           bool IsRef, const Decl *Parent,
                                           SymbolRoleSet Roles,
                                           ArrayRef<SymbolRelation> Relations,
                                           const Expr *OrigE,
                                           const Decl *OrigD,
                                           const DeclContext *ContainerDC) {
  if (D->isImplicit() && !(isa<ObjCMethodDecl>(D) || isa<ObjCIvarDecl>(D)))
    return true;
  if (!isa<NamedDecl>(D) || shouldSkipNamelessDecl(cast<NamedDecl>(D)))
    return true;

  SourceManager &SM = Ctx->getSourceManager();
  Loc = SM.getFileLoc(Loc);
  if (Loc.isInvalid())
    return true;

  FileID FID;
  unsigned Offset;
  std::tie(FID, Offset) = SM.getDecomposedLoc(Loc);
  if (FID.isInvalid())
    return true;

  if (isSystemFile(FID)) {
    switch (IndexOpts.SystemSymbolFilter) {
    case IndexingOptions::SystemSymbolFilterKind::None:
      return true;
    case IndexingOptions::SystemSymbolFilterKind::DeclarationsOnly:
      if (!shouldReportOccurrenceForSystemDeclOnlyMode(IsRef, Roles, Relations))
        return true;
      break;
    case IndexingOptions::SystemSymbolFilterKind::All:
      break;
    }
  }

  if (isTemplateImplicitInstantiation(D)) {
    if (!IsRef)
      return true;
    D = adjustTemplateImplicitInstantiation(D);
    if (!D)
      return true;
    assert(!isTemplateImplicitInstantiation(D));
  }

  if (!OrigD)
    OrigD = D;

  if (IsRef)
    Roles |= (unsigned)SymbolRole::Reference;
  else if (isDeclADefinition(OrigD, ContainerDC, *Ctx))
    Roles |= (unsigned)SymbolRole::Definition;
  else
    Roles |= (unsigned)SymbolRole::Declaration;

  D = getCanonicalDecl(D);
  Parent = adjustParent(Parent);
  if (Parent)
    Parent = getCanonicalDecl(Parent);

  SmallVector<SymbolRelation, 6> FinalRelations;
  FinalRelations.reserve(Relations.size()+1);

  auto addRelation = [&](SymbolRelation Rel) {
    auto It = std::find_if(FinalRelations.begin(), FinalRelations.end(),
                [&](SymbolRelation Elem)->bool {
                  return Elem.RelatedSymbol == Rel.RelatedSymbol;
                });
    if (It != FinalRelations.end()) {
      It->Roles |= Rel.Roles;
    } else {
      FinalRelations.push_back(Rel);
    }
    Roles |= Rel.Roles;
  };

  if (Parent) {
    if (IsRef || (!isa<ParmVarDecl>(D) && isFunctionLocalSymbol(D))) {
      addRelation(SymbolRelation{
        (unsigned)SymbolRole::RelationContainedBy,
        Parent
      });
    } else {
      addRelation(SymbolRelation{
        (unsigned)SymbolRole::RelationChildOf,
        Parent
      });
    }
  }

  for (auto &Rel : Relations) {
    addRelation(SymbolRelation(Rel.Roles,
                               Rel.RelatedSymbol->getCanonicalDecl()));
  }

  IndexDataConsumer::ASTNodeInfo Node{ OrigE, OrigD, Parent, ContainerDC };
  return DataConsumer.handleDeclOccurence(D, Roles, FinalRelations, FID, Offset,
                                          Node);
}
