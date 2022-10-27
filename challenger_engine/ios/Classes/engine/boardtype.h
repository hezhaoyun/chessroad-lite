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

#ifndef BOARDTYPE_H_INCLUDED
#define BOARDTYPE_H_INCLUDED

#include "platform.h"
#include "stdio.h"
#include <cassert>


const uint32_t BIT_MASK = 0x03FFFFFF;

// 96 bit board, 3 uint32
struct bitboardtype
{
    uint32_t low, mid, hight;

	bitboardtype():low(0),mid(0),hight(0) {};
	bitboardtype(uint32_t a, uint32_t b, uint32_t c):low(a),mid(b),hight(c&BIT_MASK){};
	bitboardtype(const bitboardtype& board){ low = board.low; mid = board.mid; hight = board.hight&BIT_MASK;};

	bitboardtype& operator=(const bitboardtype& board) 
	{
		low   = board.low;
		mid   = board.mid;
		hight = board.hight&BIT_MASK;
		return *this;
	}

	operator bool() const
	{
        return (low || mid || (hight&BIT_MASK));
	}

	int operator ==(const bitboardtype &board) const 
	{
		return low == board.low && mid == board.mid && hight == board.hight;
	}

	int operator !=(const bitboardtype &board) const 
	{
		return low != board.low || mid != board.mid && hight != board.hight;
	}

	bitboardtype operator ~() const 
	{
		return bitboardtype(~low, ~mid, ~hight);
	}

	bitboardtype operator &(const bitboardtype &board) const 
	{
		return bitboardtype(low & board.low, mid & board.mid, hight & board.hight);
	}

	bitboardtype operator |(const bitboardtype &board) const 
	{
		return bitboardtype(low | board.low, mid | board.mid, hight | board.hight);
	}

	bitboardtype operator ^(const bitboardtype &board) const 
	{
		return bitboardtype(low ^ board.low, mid ^ board.mid, hight ^ board.hight);
	}

	bitboardtype &operator &=(const bitboardtype &board) 
	{
		low &= board.low;
		mid &= board.mid;
		hight  &= board.hight&BIT_MASK;
		return *this;
	}

	bitboardtype &operator |=(const bitboardtype &board) 
	{
		low |= board.low;
		mid |= board.mid;
		hight  |= board.hight;
		hight &= BIT_MASK;
		return *this;
	}

	bitboardtype &operator ^=(const bitboardtype &board) 
	{
		low ^= board.low;
		mid ^= board.mid;
		hight  ^= board.hight;
		hight &= BIT_MASK;//if not, will affect shift
		return *this;
	}

	// Shift Operations
	bitboardtype operator <<(int bit) 
	{
		if (bit < 0)
			return *this >> -bit;
		else if (bit == 0)
			return *this;
		else if (bit < 32)
			return bitboardtype(low << bit, mid << bit | low >> (32 - bit), hight << bit | mid >> (32 - bit));
		else if (bit == 32)
			return bitboardtype(0, low, mid);
		else if (bit < 64)
			return bitboardtype(0, low << (bit - 32), mid << (bit - 32) | low >> (64 - bit));
		else if (bit == 64)
			return bitboardtype(0, 0, low);
		else if (bit < 96)
			return bitboardtype(0, 0, low << (bit - 64));
		else
			return bitboardtype(0, 0, 0);
	}

	bitboardtype operator >>(int bit) 
	{
		hight &= BIT_MASK;
		if (bit < 0)
			return *this << -bit;
		else if (bit == 0)
			return *this;
		else if (bit < 32)
			return bitboardtype(low >> bit | mid << (32 - bit), mid >> bit | hight << (32 - bit), hight >> bit);
		else if (bit == 32)
			return bitboardtype(mid, hight, 0);
		else if (bit < 64)
			return bitboardtype(mid >> (bit - 32) | hight << (64 - bit), hight >> (bit - 32), 0);
		else if (bit == 64)
			return bitboardtype(hight, 0, 0);
		else if (bit < 96)
			return bitboardtype(hight >> (bit - 64), 0, 0);
		else
			return bitboardtype(0, 0, 0);
	}

	bitboardtype &operator <<=(int bit)
	{
		if (bit < 0) 
		{
			*this >>= -bit;
		} 
		else if (bit == 0) 
		{
		} 
		else if (bit < 32) 
		{
			hight <<= bit;
			hight |= mid >> (32 - bit);
			mid <<= bit;
			mid |= low >> (32 - bit);
			low <<= bit;
		} 
		else if (bit == 32) 
		{
			hight = mid;
			mid = low;
			low = 0;
		} 
		else if (bit < 64) 
		{
			hight = mid << (bit - 32);
			hight |= low >> (64 - bit);
			mid = low << (bit - 32);
			low = 0;
		} 
		else if (bit == 64) 
		{
			hight  = low;
			mid = 0;
			low = 0;
		} 
		else if (bit < 96) 
		{
			hight = low << (bit - 64);
			mid = 0;
			low = 0;
		} 
		else 
		{
			hight  = 0;
			mid = 0;
			low = 0;		
		}

		hight &= BIT_MASK;
		return *this;
	}

	bitboardtype &operator >>=(int bit)
	{
		hight &= BIT_MASK;
		if (bit < 0) 
		{
			*this <<= -bit;
		} 
		else if (bit == 0) 
		{
		} 
		else if (bit < 32) 
		{
			low >>= bit;
			low |= mid << (32 - bit);
			mid >>= bit;
			mid |= hight << (32 - bit);
			hight >>= bit;
		} 
		else if (bit == 32) 
		{
			low = mid;
			mid = hight;
			hight = 0;
		} 
		else if (bit < 64) 
		{
			low = mid >> (bit - 32);
			low |= hight << (64 - bit);
			mid = hight >> (bit - 32);
			hight = 0;
		} 
		else if (bit == 64) 
		{
			low = hight;
			mid = 0;
			hight = 0;
		} 
		else if (bit < 96) 
		{
			low = hight >> (bit - 64);
			mid = 0;
			hight = 0;
		} 
		else 
		{
			low = 0;
			mid = 0;
			hight = 0;
		}
		return *this;
	}

	// b - 1
	bitboardtype operator-(uint32_t n)
	{
		if(low >= n)
		{
			return bitboardtype(low - n, mid, hight);
		}
		else if(mid > 0)
		{
			return bitboardtype(0xffffffff,mid - 1, hight);
		}
		else if(hight > 0)
		{
			return bitboardtype(0xffffffff, 0xffffffff, hight - 1);
		}
		return bitboardtype(0, 0, 0);
	}

	// debug
	void print()
	{
		int shift[10] = {0,9,18,27,36,45,54,63,72,81};  

		printf("\n");
		
        bitboardtype one(0x1,0,0);
        for(int i = 0 ; i< 10; ++i)
		{
			bitboardtype t = (*this)>>shift[9-i];
            for(int j = 0; j < 9; ++j)
			{
				printf("%d",(t&(one<<j)) ? 1 : 0);
				
			}
            printf("\n");
		}
	}

	void printl90()
	{
		printf("\n");
        
		int shift[10] = {0,10,20,30,40,50,60,70,80,90};       

		bitboardtype one(0x1,0,0);
		for(int i = 0 ; i< 9; ++i)
		{
			bitboardtype t = (*this)>>shift[8-i];
			for(int j = 0; j < 10; ++j)
			{
				printf("%d",(t&(one<<j)) ? 1 : 0);

			}
			printf("\n");
		}
	}

	void printall()
	{
		int shift[10] = {0,9,18,27,36,45,54,63,72,81};  

		printf("\n");
		
        bitboardtype one(0x1,0,0);
        for(int i = 0 ; i< 10; ++i)
		{
			bitboardtype t = (*this)>>shift[9-i];
            for(int j = 0; j < 9; ++j)
			{
				printf("%d",(t&(one<<j)) ? 1 : 0);
	
			}
            printf("\n");
		}

		bitboardtype t = (*this)>>90;
		for(int i = 0; i < 6; ++i)
		{
			printf("%d",(t&(one<<i)) ? 1 : 0);
		}
		printf("\n");
	}

};

// test
inline void test_boardtype()
{
    
	{
		bitboardtype b;
	    assert(!b);
	}
	{		
		bitboardtype b(0xFFFFFFFF,0xFFFFFFFF,BIT_MASK);
		//b.print();
		//b.printall();
		bitboardtype b1(0xFFFFFFFF,0xFFFFFFFF,0xFFFFFFFF);
		//b.print();
		//b.printall();
		b = ~b1;
		//b.printall();
		//b = b & b1;
		//b.printall();
		//b = b | b1;
		//b.printall();
		//b = b ^ b1;
		//b = b ^ b1;
		b &= b1;
		b |= b1;
		b ^= b1;
		b ^= b1;
		//b.printall();

	}

	{
        bitboardtype b(0xFFFFFFFF,0xFFFFFFFF,BIT_MASK);
		//b = b<<3;  b.printall();
		//b = b>>1;  b.printall();

		//b <<= 1;  b.printall();
		//b >>= 1;  b.printall();

		//b = b.operator-(1); b.printall();

		//bitboardtype b(0x1,0,0);
		for(int i = 0 ; i < 6; i++)
		{
            //bitboardtype t = b<<i;
			//bitboardtype t = b>>i;			
			//t.printall();
		}
	}


}
#endif