/*
  Challenger, a UCI chinese chess playing engine based on Stockfish
  
  Copyright (C) 2013-2017 grefen

  Challenger is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.


  Challenger is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#ifndef BITCOUNT_H_INCLUDED
#define BITCOUNT_H_INCLUDED

#include <cassert>
#include "types.h"

enum BitCountType {
	CNT_90,	
};



/// popcount() counts the number of nonzero bits in a bitboard
template<BitCountType> inline int popcount(Bitboard);

inline int popcount32(uint32_t b)
{
	uint32_t  v = uint32_t(b);
	v -=  (v >> 1) & 0x55555555; // 0-2 in 2 bits
	v  = ((v >> 2) & 0x33333333) + (v & 0x33333333); // 0-4 in 4 bits
	v  = ((v >> 4) + v) & 0x0F0F0F0F;
	return (v * 0x01010101) >> 24;
}

template<>
inline int popcount<CNT_90>(Bitboard b)
{
	return popcount32(b.low) + popcount32(b.mid) + popcount32(b.hight);
}

inline void test_bitcount()
{
	Bitboard board(0x03,0x1,0xf);

	printf("%d",popcount<CNT_90>(board));
}

#endif // #ifndef BITCOUNT_H_INCLUDED
