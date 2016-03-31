//===- lld/unittest/MachOTests/MachONormalizedFileBinaryReaderTests.cpp ---===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "gtest/gtest.h"
#include "../../lib/ReaderWriter/MachO/MachONormalizedFile.h"
#include "llvm/Support/MachO.h"

using llvm::StringRef;
using llvm::MemoryBuffer;
using llvm::ErrorOr;

using namespace lld::mach_o::normalized;
using namespace llvm::MachO;

static std::unique_ptr<NormalizedFile>
fromBinary(const uint8_t bytes[], unsigned length, StringRef archStr) {
  StringRef sr((const char*)bytes, length);
  std::unique_ptr<MemoryBuffer> mb(MemoryBuffer::getMemBuffer(sr, "", false));
  llvm::Expected<std::unique_ptr<NormalizedFile>> r =
      lld::mach_o::normalized::readBinary(
          mb, lld::MachOLinkingContext::archFromName(archStr));
  EXPECT_FALSE(!r);
  return std::move(*r);
}

// The Mach-O object reader uses functions such as read32 or read64
// which don't allow unaligned access. Our in-memory object file
// needs to be aligned to a larger boundary than uint8_t's.
#if _MSC_VER
#define FILEBYTES __declspec(align(64)) const uint8_t fileBytes[]
#else
#define FILEBYTES const uint8_t fileBytes[] __attribute__((aligned(64)))
#endif

TEST(BinaryReaderTest, empty_obj_x86_64) {
  FILEBYTES = {
      0xcf, 0xfa, 0xed, 0xfe, 0x07, 0x00, 0x00, 0x01,
      0x03, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00,
      0x01, 0x00, 0x00, 0x00, 0x98, 0x00, 0x00, 0x00,
      0x00, 0x20, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x19, 0x00, 0x00, 0x00, 0x98, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0xb8, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x07, 0x00, 0x00, 0x00, 0x07, 0x00, 0x00, 0x00,
      0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x5f, 0x5f, 0x74, 0x65, 0x78, 0x74, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x5f, 0x5f, 0x54, 0x45, 0x58, 0x54, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0xb8, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x80, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 };
  std::unique_ptr<NormalizedFile> f =
      fromBinary(fileBytes, sizeof(fileBytes), "x86_64");
  EXPECT_EQ(f->arch, lld::MachOLinkingContext::arch_x86_64);
  EXPECT_EQ((int)(f->fileType), MH_OBJECT);
  EXPECT_EQ((int)(f->flags), MH_SUBSECTIONS_VIA_SYMBOLS);
  EXPECT_TRUE(f->localSymbols.empty());
  EXPECT_TRUE(f->globalSymbols.empty());
  EXPECT_TRUE(f->undefinedSymbols.empty());
}

TEST(BinaryReaderTest, empty_obj_x86) {
  FILEBYTES = {
      0xce, 0xfa, 0xed, 0xfe, 0x07, 0x00, 0x00, 0x00,
      0x03, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00,
      0x01, 0x00, 0x00, 0x00, 0x7c, 0x00, 0x00, 0x00,
      0x00, 0x20, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00,
      0x7c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x98, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x07, 0x00, 0x00, 0x00,
      0x07, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x5f, 0x5f, 0x74, 0x65,
      0x78, 0x74, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x5f, 0x5f, 0x54, 0x45,
      0x58, 0x54, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x98, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 };
  std::unique_ptr<NormalizedFile> f =
      fromBinary(fileBytes, sizeof(fileBytes), "i386");
  EXPECT_EQ(f->arch, lld::MachOLinkingContext::arch_x86);
  EXPECT_EQ((int)(f->fileType), MH_OBJECT);
  EXPECT_EQ((int)(f->flags), MH_SUBSECTIONS_VIA_SYMBOLS);
  EXPECT_TRUE(f->localSymbols.empty());
  EXPECT_TRUE(f->globalSymbols.empty());
  EXPECT_TRUE(f->undefinedSymbols.empty());
}

TEST(BinaryReaderTest, empty_obj_ppc) {
  FILEBYTES = {
      0xfe, 0xed, 0xfa, 0xce, 0x00, 0x00, 0x00, 0x12,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01,
      0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x7c,
      0x00, 0x00, 0x20, 0x00, 0x00, 0x00, 0x00, 0x01,
      0x00, 0x00, 0x00, 0x7c, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x98,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x07,
      0x00, 0x00, 0x00, 0x07, 0x00, 0x00, 0x00, 0x01,
      0x00, 0x00, 0x00, 0x00, 0x5f, 0x5f, 0x74, 0x65,
      0x78, 0x74, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x5f, 0x5f, 0x54, 0x45,
      0x58, 0x54, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x98,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x80, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 };
  std::unique_ptr<NormalizedFile> f =
      fromBinary(fileBytes, sizeof(fileBytes), "ppc");
  EXPECT_EQ(f->arch, lld::MachOLinkingContext::arch_ppc);
  EXPECT_EQ((int)(f->fileType), MH_OBJECT);
  EXPECT_EQ((int)(f->flags), MH_SUBSECTIONS_VIA_SYMBOLS);
  EXPECT_TRUE(f->localSymbols.empty());
  EXPECT_TRUE(f->globalSymbols.empty());
  EXPECT_TRUE(f->undefinedSymbols.empty());
}

TEST(BinaryReaderTest, empty_obj_armv7) {
  FILEBYTES = {
      0xce, 0xfa, 0xed, 0xfe, 0x0c, 0x00, 0x00, 0x00,
      0x09, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00,
      0x01, 0x00, 0x00, 0x00, 0x7c, 0x00, 0x00, 0x00,
      0x00, 0x20, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00,
      0x7c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x98, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x07, 0x00, 0x00, 0x00,
      0x07, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x5f, 0x5f, 0x74, 0x65,
      0x78, 0x74, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x5f, 0x5f, 0x54, 0x45,
      0x58, 0x54, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x98, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 };
  std::unique_ptr<NormalizedFile> f =
      fromBinary(fileBytes, sizeof(fileBytes), "armv7");
  EXPECT_EQ(f->arch, lld::MachOLinkingContext::arch_armv7);
  EXPECT_EQ((int)(f->fileType), MH_OBJECT);
  EXPECT_EQ((int)(f->flags), MH_SUBSECTIONS_VIA_SYMBOLS);
  EXPECT_TRUE(f->localSymbols.empty());
  EXPECT_TRUE(f->globalSymbols.empty());
  EXPECT_TRUE(f->undefinedSymbols.empty());
}

TEST(BinaryReaderTest, empty_obj_x86_64_arm7) {
  FILEBYTES = {
#include "empty_obj_x86_armv7.txt"
  };
  std::unique_ptr<NormalizedFile> f =
      fromBinary(fileBytes, sizeof(fileBytes), "x86_64");
  EXPECT_EQ(f->arch, lld::MachOLinkingContext::arch_x86_64);
  EXPECT_EQ((int)(f->fileType), MH_OBJECT);
  EXPECT_EQ((int)(f->flags), MH_SUBSECTIONS_VIA_SYMBOLS);
  EXPECT_TRUE(f->localSymbols.empty());
  EXPECT_TRUE(f->globalSymbols.empty());
  EXPECT_TRUE(f->undefinedSymbols.empty());

  std::unique_ptr<NormalizedFile> f2 =
      fromBinary(fileBytes, sizeof(fileBytes), "armv7");
  EXPECT_EQ(f2->arch, lld::MachOLinkingContext::arch_armv7);
  EXPECT_EQ((int)(f2->fileType), MH_OBJECT);
  EXPECT_EQ((int)(f2->flags), MH_SUBSECTIONS_VIA_SYMBOLS);
  EXPECT_TRUE(f2->localSymbols.empty());
  EXPECT_TRUE(f2->globalSymbols.empty());
  EXPECT_TRUE(f2->undefinedSymbols.empty());
}

TEST(BinaryReaderTest, hello_obj_x86_64) {
  FILEBYTES = {
    0xCF, 0xFA, 0xED, 0xFE, 0x07, 0x00, 0x00, 0x01,
    0x03, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00,
    0x03, 0x00, 0x00, 0x00, 0x50, 0x01, 0x00, 0x00,
    0x00, 0x20, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x19, 0x00, 0x00, 0x00, 0xE8, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x34, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x70, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x34, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x07, 0x00, 0x00, 0x00, 0x07, 0x00, 0x00, 0x00,
    0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x5F, 0x5F, 0x74, 0x65, 0x78, 0x74, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x5F, 0x5F, 0x54, 0x45, 0x58, 0x54, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x2D, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x70, 0x01, 0x00, 0x00, 0x04, 0x00, 0x00, 0x00,
    0xA4, 0x01, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00,
    0x00, 0x04, 0x00, 0x80, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x5F, 0x5F, 0x63, 0x73, 0x74, 0x72, 0x69, 0x6E,
    0x67, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x5F, 0x5F, 0x54, 0x45, 0x58, 0x54, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x2D, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x07, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x9D, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x02, 0x00, 0x00, 0x00, 0x18, 0x00, 0x00, 0x00,
    0xB4, 0x01, 0x00, 0x00, 0x03, 0x00, 0x00, 0x00,
    0xE4, 0x01, 0x00, 0x00, 0x18, 0x00, 0x00, 0x00,
    0x0B, 0x00, 0x00, 0x00, 0x50, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00,
    0x01, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00,
    0x02, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x55, 0x48, 0x89, 0xE5, 0x48, 0x83, 0xEC, 0x10,
    0x48, 0x8D, 0x3D, 0x00, 0x00, 0x00, 0x00, 0xC7,
    0x45, 0xFC, 0x00, 0x00, 0x00, 0x00, 0xB0, 0x00,
    0xE8, 0x00, 0x00, 0x00, 0x00, 0xB9, 0x00, 0x00,
    0x00, 0x00, 0x89, 0x45, 0xF8, 0x89, 0xC8, 0x48,
    0x83, 0xC4, 0x10, 0x5D, 0xC3, 0x68, 0x65, 0x6C,
    0x6C, 0x6F, 0x0A, 0x00, 0x19, 0x00, 0x00, 0x00,
    0x02, 0x00, 0x00, 0x2D, 0x0B, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x1D, 0x0F, 0x00, 0x00, 0x00,
    0x0E, 0x02, 0x00, 0x00, 0x2D, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00,
    0x0F, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x07, 0x00, 0x00, 0x00,
    0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x5F, 0x6D, 0x61,
    0x69, 0x6E, 0x00, 0x5F, 0x70, 0x72, 0x69, 0x6E,
    0x74, 0x66, 0x00, 0x4C, 0x5F, 0x2E, 0x73, 0x74,
    0x72, 0x00, 0x00, 0x00 };
  std::unique_ptr<NormalizedFile> f =
      fromBinary(fileBytes, sizeof(fileBytes), "x86_64");

  EXPECT_EQ(f->arch, lld::MachOLinkingContext::arch_x86_64);
  EXPECT_EQ((int)(f->fileType), MH_OBJECT);
  EXPECT_EQ((int)(f->flags), MH_SUBSECTIONS_VIA_SYMBOLS);
  EXPECT_EQ(f->sections.size(), 2UL);
  const Section& text = f->sections[0];
  EXPECT_TRUE(text.segmentName.equals("__TEXT"));
  EXPECT_TRUE(text.sectionName.equals("__text"));
  EXPECT_EQ(text.type, S_REGULAR);
  EXPECT_EQ(text.attributes,SectionAttr(S_ATTR_PURE_INSTRUCTIONS
                                      | S_ATTR_SOME_INSTRUCTIONS));
  EXPECT_EQ((uint16_t)text.alignment, 16U);
  EXPECT_EQ(text.address, Hex64(0x0));
  EXPECT_EQ(text.content.size(), 45UL);
  EXPECT_EQ((int)(text.content[0]), 0x55);
  EXPECT_EQ((int)(text.content[1]), 0x48);
  EXPECT_TRUE(text.indirectSymbols.empty());
  EXPECT_EQ(text.relocations.size(), 2UL);
  const Relocation& call = text.relocations[0];
  EXPECT_EQ(call.offset, Hex32(0x19));
  EXPECT_EQ(call.type, X86_64_RELOC_BRANCH);
  EXPECT_EQ(call.length, 2);
  EXPECT_EQ(call.isExtern, true);
  EXPECT_EQ(call.symbol, 2U);
  const Relocation& str = text.relocations[1];
  EXPECT_EQ(str.offset, Hex32(0xB));
  EXPECT_EQ(str.type, X86_64_RELOC_SIGNED);
  EXPECT_EQ(str.length, 2);
  EXPECT_EQ(str.isExtern, true);
  EXPECT_EQ(str.symbol, 0U);

  const Section& cstring = f->sections[1];
  EXPECT_TRUE(cstring.segmentName.equals("__TEXT"));
  EXPECT_TRUE(cstring.sectionName.equals("__cstring"));
  EXPECT_EQ(cstring.type, S_CSTRING_LITERALS);
  EXPECT_EQ(cstring.attributes, SectionAttr(0));
  EXPECT_EQ((uint16_t)cstring.alignment, 1U);
  EXPECT_EQ(cstring.address, Hex64(0x02D));
  EXPECT_EQ(cstring.content.size(), 7UL);
  EXPECT_EQ((int)(cstring.content[0]), 0x68);
  EXPECT_EQ((int)(cstring.content[1]), 0x65);
  EXPECT_EQ((int)(cstring.content[2]), 0x6c);
  EXPECT_TRUE(cstring.indirectSymbols.empty());
  EXPECT_TRUE(cstring.relocations.empty());

  EXPECT_EQ(f->localSymbols.size(), 1UL);
  const Symbol& strLabel = f->localSymbols[0];
  EXPECT_EQ(strLabel.type, N_SECT);
  EXPECT_EQ(strLabel.sect, 2);
  EXPECT_EQ(strLabel.value, Hex64(0x2D));
  EXPECT_EQ(f->globalSymbols.size(), 1UL);
  const Symbol& mainLabel = f->globalSymbols[0];
  EXPECT_TRUE(mainLabel.name.equals("_main"));
  EXPECT_EQ(mainLabel.type, N_SECT);
  EXPECT_EQ(mainLabel.sect, 1);
  EXPECT_EQ(mainLabel.scope, SymbolScope(N_EXT));
  EXPECT_EQ(mainLabel.value, Hex64(0x0));
  EXPECT_EQ(f->undefinedSymbols.size(), 1UL);
  const Symbol& printfLabel = f->undefinedSymbols[0];
  EXPECT_TRUE(printfLabel.name.equals("_printf"));
  EXPECT_EQ(printfLabel.type, N_UNDF);
  EXPECT_EQ(printfLabel.scope, SymbolScope(N_EXT));
}

TEST(BinaryReaderTest, hello_obj_x86) {
  FILEBYTES = {
    0xCE, 0xFA, 0xED, 0xFE, 0x07, 0x00, 0x00, 0x00,
    0x03, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00,
    0x03, 0x00, 0x00, 0x00, 0x28, 0x01, 0x00, 0x00,
    0x00, 0x20, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00,
    0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x37, 0x00, 0x00, 0x00, 0x44, 0x01, 0x00, 0x00,
    0x37, 0x00, 0x00, 0x00, 0x07, 0x00, 0x00, 0x00,
    0x07, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x5F, 0x5F, 0x74, 0x65,
    0x78, 0x74, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x5F, 0x5F, 0x54, 0x45,
    0x58, 0x54, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x30, 0x00, 0x00, 0x00, 0x44, 0x01, 0x00, 0x00,
    0x04, 0x00, 0x00, 0x00, 0x7C, 0x01, 0x00, 0x00,
    0x03, 0x00, 0x00, 0x00, 0x00, 0x04, 0x00, 0x80,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x5F, 0x5F, 0x63, 0x73, 0x74, 0x72, 0x69, 0x6E,
    0x67, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x5F, 0x5F, 0x54, 0x45, 0x58, 0x54, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x30, 0x00, 0x00, 0x00, 0x07, 0x00, 0x00, 0x00,
    0x74, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00,
    0x18, 0x00, 0x00, 0x00, 0x94, 0x01, 0x00, 0x00,
    0x02, 0x00, 0x00, 0x00, 0xAC, 0x01, 0x00, 0x00,
    0x10, 0x00, 0x00, 0x00, 0x0B, 0x00, 0x00, 0x00,
    0x50, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x01, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00,
    0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x55, 0x89, 0xE5, 0x83,
    0xEC, 0x18, 0xE8, 0x00, 0x00, 0x00, 0x00, 0x58,
    0x8D, 0x80, 0x25, 0x00, 0x00, 0x00, 0xC7, 0x45,
    0xFC, 0x00, 0x00, 0x00, 0x00, 0x89, 0x04, 0x24,
    0xE8, 0xDF, 0xFF, 0xFF, 0xFF, 0xB9, 0x00, 0x00,
    0x00, 0x00, 0x89, 0x45, 0xF8, 0x89, 0xC8, 0x83,
    0xC4, 0x18, 0x5D, 0xC3, 0x68, 0x65, 0x6C, 0x6C,
    0x6F, 0x0A, 0x00, 0x00, 0x1D, 0x00, 0x00, 0x00,
    0x01, 0x00, 0x00, 0x0D, 0x0E, 0x00, 0x00, 0xA4,
    0x30, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xA1,
    0x0B, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00,
    0x0F, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x07, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x5F, 0x6D, 0x61,
    0x69, 0x6E, 0x00, 0x5F, 0x70, 0x72, 0x69, 0x6E,
    0x74, 0x66, 0x00, 0x00
  };
  std::unique_ptr<NormalizedFile> f =
      fromBinary(fileBytes, sizeof(fileBytes), "i386");

  EXPECT_EQ(f->arch, lld::MachOLinkingContext::arch_x86);
  EXPECT_EQ((int)(f->fileType), MH_OBJECT);
  EXPECT_EQ((int)(f->flags), MH_SUBSECTIONS_VIA_SYMBOLS);
  EXPECT_EQ(f->sections.size(), 2UL);
  const Section& text = f->sections[0];
  EXPECT_TRUE(text.segmentName.equals("__TEXT"));
  EXPECT_TRUE(text.sectionName.equals("__text"));
  EXPECT_EQ(text.type, S_REGULAR);
  EXPECT_EQ(text.attributes,SectionAttr(S_ATTR_PURE_INSTRUCTIONS
                                      | S_ATTR_SOME_INSTRUCTIONS));
  EXPECT_EQ((uint16_t)text.alignment, 16U);
  EXPECT_EQ(text.address, Hex64(0x0));
  EXPECT_EQ(text.content.size(), 48UL);
  EXPECT_EQ((int)(text.content[0]), 0x55);
  EXPECT_EQ((int)(text.content[1]), 0x89);
  EXPECT_TRUE(text.indirectSymbols.empty());
  EXPECT_EQ(text.relocations.size(), 3UL);
  const Relocation& call = text.relocations[0];
  EXPECT_EQ(call.offset, Hex32(0x1D));
  EXPECT_EQ(call.scattered, false);
  EXPECT_EQ(call.type, GENERIC_RELOC_VANILLA);
  EXPECT_EQ(call.pcRel, true);
  EXPECT_EQ(call.length, 2);
  EXPECT_EQ(call.isExtern, true);
  EXPECT_EQ(call.symbol, 1U);
  const Relocation& sectDiff = text.relocations[1];
  EXPECT_EQ(sectDiff.offset, Hex32(0xE));
  EXPECT_EQ(sectDiff.scattered, true);
  EXPECT_EQ(sectDiff.type, GENERIC_RELOC_LOCAL_SECTDIFF);
  EXPECT_EQ(sectDiff.pcRel, false);
  EXPECT_EQ(sectDiff.length, 2);
  EXPECT_EQ(sectDiff.value, 0x30U);
  const Relocation& pair = text.relocations[2];
  EXPECT_EQ(pair.offset, Hex32(0x0));
  EXPECT_EQ(pair.scattered, true);
  EXPECT_EQ(pair.type, GENERIC_RELOC_PAIR);
  EXPECT_EQ(pair.pcRel, false);
  EXPECT_EQ(pair.length, 2);
  EXPECT_EQ(pair.value, 0x0BU);

  const Section& cstring = f->sections[1];
  EXPECT_TRUE(cstring.segmentName.equals("__TEXT"));
  EXPECT_TRUE(cstring.sectionName.equals("__cstring"));
  EXPECT_EQ(cstring.type, S_CSTRING_LITERALS);
  EXPECT_EQ(cstring.attributes, SectionAttr(0));
  EXPECT_EQ((uint16_t)cstring.alignment, 1U);
  EXPECT_EQ(cstring.address, Hex64(0x030));
  EXPECT_EQ(cstring.content.size(), 7UL);
  EXPECT_EQ((int)(cstring.content[0]), 0x68);
  EXPECT_EQ((int)(cstring.content[1]), 0x65);
  EXPECT_EQ((int)(cstring.content[2]), 0x6c);
  EXPECT_TRUE(cstring.indirectSymbols.empty());
  EXPECT_TRUE(cstring.relocations.empty());

  EXPECT_EQ(f->localSymbols.size(), 0UL);
  EXPECT_EQ(f->globalSymbols.size(), 1UL);
  const Symbol& mainLabel = f->globalSymbols[0];
  EXPECT_TRUE(mainLabel.name.equals("_main"));
  EXPECT_EQ(mainLabel.type, N_SECT);
  EXPECT_EQ(mainLabel.sect, 1);
  EXPECT_EQ(mainLabel.scope, SymbolScope(N_EXT));
  EXPECT_EQ(mainLabel.value, Hex64(0x0));
  EXPECT_EQ(f->undefinedSymbols.size(), 1UL);
  const Symbol& printfLabel = f->undefinedSymbols[0];
  EXPECT_TRUE(printfLabel.name.equals("_printf"));
  EXPECT_EQ(printfLabel.type, N_UNDF);
  EXPECT_EQ(printfLabel.scope, SymbolScope(N_EXT));
}

TEST(BinaryReaderTest, hello_obj_armv7) {
  FILEBYTES = {
    0xCE, 0xFA, 0xED, 0xFE, 0x0C, 0x00, 0x00, 0x00,
    0x09, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00,
    0x03, 0x00, 0x00, 0x00, 0x28, 0x01, 0x00, 0x00,
    0x00, 0x20, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00,
    0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x31, 0x00, 0x00, 0x00, 0x44, 0x01, 0x00, 0x00,
    0x31, 0x00, 0x00, 0x00, 0x07, 0x00, 0x00, 0x00,
    0x07, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x5F, 0x5F, 0x74, 0x65,
    0x78, 0x74, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x5F, 0x5F, 0x54, 0x45,
    0x58, 0x54, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x2A, 0x00, 0x00, 0x00, 0x44, 0x01, 0x00, 0x00,
    0x02, 0x00, 0x00, 0x00, 0x78, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x00, 0x00, 0x00, 0x04, 0x00, 0x80,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x5F, 0x5F, 0x63, 0x73, 0x74, 0x72, 0x69, 0x6E,
    0x67, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x5F, 0x5F, 0x54, 0x45, 0x58, 0x54, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x2A, 0x00, 0x00, 0x00, 0x07, 0x00, 0x00, 0x00,
    0x6E, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00,
    0x18, 0x00, 0x00, 0x00, 0xA0, 0x01, 0x00, 0x00,
    0x02, 0x00, 0x00, 0x00, 0xB8, 0x01, 0x00, 0x00,
    0x10, 0x00, 0x00, 0x00, 0x0B, 0x00, 0x00, 0x00,
    0x50, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x01, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00,
    0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x80, 0xB5, 0x6F, 0x46,
    0x82, 0xB0, 0x40, 0xF2, 0x18, 0x00, 0xC0, 0xF2,
    0x00, 0x00, 0x78, 0x44, 0x00, 0x21, 0xC0, 0xF2,
    0x00, 0x01, 0x01, 0x91, 0xFF, 0xF7, 0xF2, 0xFF,
    0x00, 0x21, 0xC0, 0xF2, 0x00, 0x01, 0x00, 0x90,
    0x08, 0x46, 0x02, 0xB0, 0x80, 0xBD, 0x68, 0x65,
    0x6C, 0x6C, 0x6F, 0x0A, 0x00, 0x00, 0x00, 0x00,
    0x18, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x6D,
    0x0A, 0x00, 0x00, 0xB9, 0x2A, 0x00, 0x00, 0x00,
    0x18, 0x00, 0x00, 0xB1, 0x0E, 0x00, 0x00, 0x00,
    0x06, 0x00, 0x00, 0xA9, 0x2A, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0xA1, 0x0E, 0x00, 0x00, 0x00,
    0x01, 0x00, 0x00, 0x00, 0x0F, 0x01, 0x08, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x07, 0x00, 0x00, 0x00,
    0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x5F, 0x6D, 0x61, 0x69, 0x6E, 0x00, 0x5F,
    0x70, 0x72, 0x69, 0x6E, 0x74, 0x66, 0x00, 0x00
  };
  std::unique_ptr<NormalizedFile> f =
      fromBinary(fileBytes, sizeof(fileBytes), "armv7");

  EXPECT_EQ(f->arch, lld::MachOLinkingContext::arch_armv7);
  EXPECT_EQ((int)(f->fileType), MH_OBJECT);
  EXPECT_EQ((int)(f->flags), MH_SUBSECTIONS_VIA_SYMBOLS);
  EXPECT_EQ(f->sections.size(), 2UL);
  const Section& text = f->sections[0];
  EXPECT_TRUE(text.segmentName.equals("__TEXT"));
  EXPECT_TRUE(text.sectionName.equals("__text"));
  EXPECT_EQ(text.type, S_REGULAR);
  EXPECT_EQ(text.attributes,SectionAttr(S_ATTR_PURE_INSTRUCTIONS
                                      | S_ATTR_SOME_INSTRUCTIONS));
  EXPECT_EQ((uint16_t)text.alignment, 4U);
  EXPECT_EQ(text.address, Hex64(0x0));
  EXPECT_EQ(text.content.size(), 42UL);
  EXPECT_EQ((int)(text.content[0]), 0x80);
  EXPECT_EQ((int)(text.content[1]), 0xB5);
  EXPECT_TRUE(text.indirectSymbols.empty());
  EXPECT_EQ(text.relocations.size(), 5UL);
  const Relocation& call = text.relocations[0];
  EXPECT_EQ(call.offset, Hex32(0x18));
  EXPECT_EQ(call.scattered, false);
  EXPECT_EQ(call.type, ARM_THUMB_RELOC_BR22);
  EXPECT_EQ(call.length, 2);
  EXPECT_EQ(call.isExtern, true);
  EXPECT_EQ(call.symbol, 1U);
  const Relocation& movt = text.relocations[1];
  EXPECT_EQ(movt.offset, Hex32(0xA));
  EXPECT_EQ(movt.scattered, true);
  EXPECT_EQ(movt.type, ARM_RELOC_HALF_SECTDIFF);
  EXPECT_EQ(movt.length, 3);
  EXPECT_EQ(movt.value, Hex32(0x2A));
  const Relocation& movtPair = text.relocations[2];
  EXPECT_EQ(movtPair.offset, Hex32(0x18));
  EXPECT_EQ(movtPair.scattered, true);
  EXPECT_EQ(movtPair.type, ARM_RELOC_PAIR);
  EXPECT_EQ(movtPair.length, 3);
  EXPECT_EQ(movtPair.value, Hex32(0xE));
  const Relocation& movw = text.relocations[3];
  EXPECT_EQ(movw.offset, Hex32(0x6));
  EXPECT_EQ(movw.scattered, true);
  EXPECT_EQ(movw.type, ARM_RELOC_HALF_SECTDIFF);
  EXPECT_EQ(movw.length, 2);
  EXPECT_EQ(movw.value, Hex32(0x2A));
  const Relocation& movwPair = text.relocations[4];
  EXPECT_EQ(movwPair.offset, Hex32(0x0));
  EXPECT_EQ(movwPair.scattered, true);
  EXPECT_EQ(movwPair.type, ARM_RELOC_PAIR);
  EXPECT_EQ(movwPair.length, 2);
  EXPECT_EQ(movwPair.value, Hex32(0xE));

  const Section& cstring = f->sections[1];
  EXPECT_TRUE(cstring.segmentName.equals("__TEXT"));
  EXPECT_TRUE(cstring.sectionName.equals("__cstring"));
  EXPECT_EQ(cstring.type, S_CSTRING_LITERALS);
  EXPECT_EQ(cstring.attributes, SectionAttr(0));
  EXPECT_EQ((uint16_t)cstring.alignment, 1U);
  EXPECT_EQ(cstring.address, Hex64(0x02A));
  EXPECT_EQ(cstring.content.size(), 7UL);
  EXPECT_EQ((int)(cstring.content[0]), 0x68);
  EXPECT_EQ((int)(cstring.content[1]), 0x65);
  EXPECT_EQ((int)(cstring.content[2]), 0x6c);
  EXPECT_TRUE(cstring.indirectSymbols.empty());
  EXPECT_TRUE(cstring.relocations.empty());

  EXPECT_EQ(f->localSymbols.size(), 0UL);
  EXPECT_EQ(f->globalSymbols.size(), 1UL);
  const Symbol& mainLabel = f->globalSymbols[0];
  EXPECT_TRUE(mainLabel.name.equals("_main"));
  EXPECT_EQ(mainLabel.type, N_SECT);
  EXPECT_EQ(mainLabel.sect, 1);
  EXPECT_EQ(mainLabel.scope, SymbolScope(N_EXT));
  EXPECT_EQ(mainLabel.value, Hex64(0x0));
  EXPECT_EQ(f->undefinedSymbols.size(), 1UL);
  const Symbol& printfLabel = f->undefinedSymbols[0];
  EXPECT_TRUE(printfLabel.name.equals("_printf"));
  EXPECT_EQ(printfLabel.type, N_UNDF);
  EXPECT_EQ(printfLabel.scope, SymbolScope(N_EXT));
}

TEST(BinaryReaderTest, hello_obj_ppc) {
  FILEBYTES = {
    0xFE, 0xED, 0xFA, 0xCE, 0x00, 0x00, 0x00, 0x12,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01,
    0x00, 0x00, 0x00, 0x03, 0x00, 0x00, 0x01, 0x28,
    0x00, 0x00, 0x20, 0x00, 0x00, 0x00, 0x00, 0x01,
    0x00, 0x00, 0x00, 0xC0, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x4B, 0x00, 0x00, 0x01, 0x44,
    0x00, 0x00, 0x00, 0x4B, 0x00, 0x00, 0x00, 0x07,
    0x00, 0x00, 0x00, 0x07, 0x00, 0x00, 0x00, 0x02,
    0x00, 0x00, 0x00, 0x00, 0x5F, 0x5F, 0x74, 0x65,
    0x78, 0x74, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x5F, 0x5F, 0x54, 0x45,
    0x58, 0x54, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x44, 0x00, 0x00, 0x01, 0x44,
    0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x01, 0x90,
    0x00, 0x00, 0x00, 0x05, 0x80, 0x00, 0x04, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x5F, 0x5F, 0x63, 0x73, 0x74, 0x72, 0x69, 0x6E,
    0x67, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x5F, 0x5F, 0x54, 0x45, 0x58, 0x54, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x44, 0x00, 0x00, 0x00, 0x07,
    0x00, 0x00, 0x01, 0x88, 0x00, 0x00, 0x00, 0x02,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02,
    0x00, 0x00, 0x00, 0x18, 0x00, 0x00, 0x01, 0xB8,
    0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x01, 0xD0,
    0x00, 0x00, 0x00, 0x10, 0x00, 0x00, 0x00, 0x0B,
    0x00, 0x00, 0x00, 0x50, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x7C, 0x08, 0x02, 0xA6,
    0xBF, 0xC1, 0xFF, 0xF8, 0x90, 0x01, 0x00, 0x08,
    0x94, 0x21, 0xFF, 0xB0, 0x7C, 0x3E, 0x0B, 0x78,
    0x42, 0x9F, 0x00, 0x05, 0x7F, 0xE8, 0x02, 0xA6,
    0x3C, 0x5F, 0x00, 0x00, 0x38, 0x62, 0x00, 0x2C,
    0x4B, 0xFF, 0xFF, 0xDD, 0x38, 0x00, 0x00, 0x00,
    0x7C, 0x03, 0x03, 0x78, 0x80, 0x21, 0x00, 0x00,
    0x80, 0x01, 0x00, 0x08, 0x7C, 0x08, 0x03, 0xA6,
    0xBB, 0xC1, 0xFF, 0xF8, 0x4E, 0x80, 0x00, 0x20,
    0x68, 0x65, 0x6C, 0x6C, 0x6F, 0x0A, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x24, 0x00, 0x00, 0x01, 0xD3,
    0xAB, 0x00, 0x00, 0x20, 0x00, 0x00, 0x00, 0x44,
    0xA1, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x18,
    0xAC, 0x00, 0x00, 0x1C, 0x00, 0x00, 0x00, 0x44,
    0xA1, 0x00, 0x00, 0x2C, 0x00, 0x00, 0x00, 0x18,
    0x00, 0x00, 0x00, 0x01, 0x0F, 0x01, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x07,
    0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x5F, 0x6D, 0x61, 0x69, 0x6E, 0x00, 0x5F,
    0x70, 0x72, 0x69, 0x6E, 0x74, 0x66, 0x00, 0x00
  };
  std::unique_ptr<NormalizedFile> f =
      fromBinary(fileBytes, sizeof(fileBytes), "ppc");

  EXPECT_EQ(f->arch, lld::MachOLinkingContext::arch_ppc);
  EXPECT_EQ((int)(f->fileType), MH_OBJECT);
  EXPECT_EQ((int)(f->flags), MH_SUBSECTIONS_VIA_SYMBOLS);
  EXPECT_EQ(f->sections.size(), 2UL);
  const Section& text = f->sections[0];
  EXPECT_TRUE(text.segmentName.equals("__TEXT"));
  EXPECT_TRUE(text.sectionName.equals("__text"));
  EXPECT_EQ(text.type, S_REGULAR);
  EXPECT_EQ(text.attributes,SectionAttr(S_ATTR_PURE_INSTRUCTIONS
                                      | S_ATTR_SOME_INSTRUCTIONS));
  EXPECT_EQ((uint16_t)text.alignment, 4U);
  EXPECT_EQ(text.address, Hex64(0x0));
  EXPECT_EQ(text.content.size(), 68UL);
  EXPECT_EQ((int)(text.content[0]), 0x7C);
  EXPECT_EQ((int)(text.content[1]), 0x08);
  EXPECT_TRUE(text.indirectSymbols.empty());
  EXPECT_EQ(text.relocations.size(), 5UL);
  const Relocation& bl = text.relocations[0];
  EXPECT_EQ(bl.offset, Hex32(0x24));
  EXPECT_EQ(bl.type, PPC_RELOC_BR24);
  EXPECT_EQ(bl.length, 2);
  EXPECT_EQ(bl.isExtern, true);
  EXPECT_EQ(bl.symbol, 1U);
  const Relocation& lo = text.relocations[1];
  EXPECT_EQ(lo.offset, Hex32(0x20));
  EXPECT_EQ(lo.scattered, true);
  EXPECT_EQ(lo.type, PPC_RELOC_LO16_SECTDIFF);
  EXPECT_EQ(lo.length, 2);
  EXPECT_EQ(lo.value, Hex32(0x44));
  const Relocation& loPair = text.relocations[2];
  EXPECT_EQ(loPair.offset, Hex32(0x0));
  EXPECT_EQ(loPair.scattered, true);
  EXPECT_EQ(loPair.type, PPC_RELOC_PAIR);
  EXPECT_EQ(loPair.length, 2);
  EXPECT_EQ(loPair.value, Hex32(0x18));
  const Relocation& ha = text.relocations[3];
  EXPECT_EQ(ha.offset, Hex32(0x1C));
  EXPECT_EQ(ha.scattered, true);
  EXPECT_EQ(ha.type, PPC_RELOC_HA16_SECTDIFF);
  EXPECT_EQ(ha.length, 2);
  EXPECT_EQ(ha.value, Hex32(0x44));
  const Relocation& haPair = text.relocations[4];
  EXPECT_EQ(haPair.offset, Hex32(0x2c));
  EXPECT_EQ(haPair.scattered, true);
  EXPECT_EQ(haPair.type, PPC_RELOC_PAIR);
  EXPECT_EQ(haPair.length, 2);
  EXPECT_EQ(haPair.value, Hex32(0x18));

  const Section& cstring = f->sections[1];
  EXPECT_TRUE(cstring.segmentName.equals("__TEXT"));
  EXPECT_TRUE(cstring.sectionName.equals("__cstring"));
  EXPECT_EQ(cstring.type, S_CSTRING_LITERALS);
  EXPECT_EQ(cstring.attributes, SectionAttr(0));
  EXPECT_EQ((uint16_t)cstring.alignment, 4U);
  EXPECT_EQ(cstring.address, Hex64(0x044));
  EXPECT_EQ(cstring.content.size(), 7UL);
  EXPECT_EQ((int)(cstring.content[0]), 0x68);
  EXPECT_EQ((int)(cstring.content[1]), 0x65);
  EXPECT_EQ((int)(cstring.content[2]), 0x6c);
  EXPECT_TRUE(cstring.indirectSymbols.empty());
  EXPECT_TRUE(cstring.relocations.empty());

  EXPECT_EQ(f->localSymbols.size(), 0UL);
  EXPECT_EQ(f->globalSymbols.size(), 1UL);
  const Symbol& mainLabel = f->globalSymbols[0];
  EXPECT_TRUE(mainLabel.name.equals("_main"));
  EXPECT_EQ(mainLabel.type, N_SECT);
  EXPECT_EQ(mainLabel.sect, 1);
  EXPECT_EQ(mainLabel.scope, SymbolScope(N_EXT));
  EXPECT_EQ(mainLabel.value, Hex64(0x0));
  EXPECT_EQ(f->undefinedSymbols.size(), 1UL);
  const Symbol& printfLabel = f->undefinedSymbols[0];
  EXPECT_TRUE(printfLabel.name.equals("_printf"));
  EXPECT_EQ(printfLabel.type, N_UNDF);
  EXPECT_EQ(printfLabel.scope, SymbolScope(N_EXT));

  auto ec = writeBinary(*f, "/tmp/foo.o");
  // FIXME: We want to do EXPECT_FALSE(ec) but that fails on some Windows bots,
  // probably due to /tmp not being available.
  // For now just check if an error happens as we need to mark it as checked.
  bool failed = (bool)ec;
  (void)failed;
}
