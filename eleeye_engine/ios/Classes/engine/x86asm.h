#include "base.h"

#ifndef X86ASM_H
#define X86ASM_H

#pragma warning(disable: 4146)

inline uint32_t LOW_LONG(uint64_t Operand) {
  return (uint32_t) Operand;
}

inline uint32_t HIGH_LONG(uint64_t Operand) {
  return (uint32_t) (Operand >> 32);
}

inline uint64_t MAKE_LONG_LONG(uint32_t LowLong, uint32_t HighLong) {
  return (uint64_t) LowLong | ((uint64_t) HighLong << 32);
}

static int cnBitScanTable[64] = {
  32,  0,  1, 12,  2,  6, -1, 13,  3, -1,  7, -1, -1, -1, -1, 14,
  10,  4, -1, -1,  8, -1, -1, 25, -1, -1, -1, -1, -1, 21, 27, 15,
  31, 11,  5, -1, -1, -1, -1, -1,  9, -1, -1, 24, -1, -1, 20, 26,
  30, -1, -1, -1, -1, 23, -1, 19, 29, -1, 22, 18, 28, 17, 16, -1
};

inline int BitScan(uint32_t Operand) {
  uint32_t dw = (Operand << 4) + Operand;
  dw += dw << 6;
  dw = (dw << 16) - dw;
  return cnBitScanTable[dw >> 26];  
}

inline int Bsf(uint32_t Operand) {
  return BitScan(Operand & -Operand);
}

inline int Bsr(uint32_t Operand) {
  uint32_t dw = Operand | (Operand >> 1);
  dw |= dw >> 2;
  dw |= dw >> 4;
  dw |= dw >> 8;
  dw |= dw >> 16;
  return BitScan(dw - (dw >> 1));
}

#endif
