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

#ifndef BITBOARD_H_INCLUDED
#define BITBOARD_H_INCLUDED

#include "types.h"
#include <time.h>

namespace Bitboards {

void init();
void print(Bitboard b);

}

namespace Bitbases {

void init_kpk();
bool probe_kpk(Square wksq, Square wpsq, Square bksq, Color us);

}

#define POW_2(x)   ( (Bitboard(1, 0, 0)<<(x)) )

const Bitboard  A0 = POW_2(SQ_A0), B0 = POW_2(SQ_B0), C0 = POW_2(SQ_C0), D0 = POW_2(SQ_D0), E0 = POW_2(SQ_E0), F0 = POW_2(SQ_F0), G0 = POW_2(SQ_G0), H0 = POW_2(SQ_H0), I0 = POW_2(SQ_I0),
                A1 = POW_2(SQ_A1), B1 = POW_2(SQ_B1), C1 = POW_2(SQ_C1), D1 = POW_2(SQ_D1), E1 = POW_2(SQ_E1), F1 = POW_2(SQ_F1), G1 = POW_2(SQ_G1), H1 = POW_2(SQ_H1), I1 = POW_2(SQ_I1),
				A2 = POW_2(SQ_A2), B2 = POW_2(SQ_B2), C2 = POW_2(SQ_C2), D2 = POW_2(SQ_D2), E2 = POW_2(SQ_E2), F2 = POW_2(SQ_F2), G2 = POW_2(SQ_G2), H2 = POW_2(SQ_H2), I2 = POW_2(SQ_I2),   
				A3 = POW_2(SQ_A3), B3 = POW_2(SQ_B3), C3 = POW_2(SQ_C3), D3 = POW_2(SQ_D3), E3 = POW_2(SQ_E3), F3 = POW_2(SQ_F3), G3 = POW_2(SQ_G3), H3 = POW_2(SQ_H3), I3 = POW_2(SQ_I3),  
				A4 = POW_2(SQ_A4), B4 = POW_2(SQ_B4), C4 = POW_2(SQ_C4), D4 = POW_2(SQ_D4), E4 = POW_2(SQ_E4), F4 = POW_2(SQ_F4), G4 = POW_2(SQ_G4), H4 = POW_2(SQ_H4), I4 = POW_2(SQ_I4), 
				A5 = POW_2(SQ_A5), B5 = POW_2(SQ_B5), C5 = POW_2(SQ_C5), D5 = POW_2(SQ_D5), E5 = POW_2(SQ_E5), F5 = POW_2(SQ_F5), G5 = POW_2(SQ_G5), H5 = POW_2(SQ_H5), I5 = POW_2(SQ_I5), 
				A6 = POW_2(SQ_A6), B6 = POW_2(SQ_B6), C6 = POW_2(SQ_C6), D6 = POW_2(SQ_D6), E6 = POW_2(SQ_E6), F6 = POW_2(SQ_F6), G6 = POW_2(SQ_G6), H6 = POW_2(SQ_H6), I6 = POW_2(SQ_I6),  
				A7 = POW_2(SQ_A7), B7 = POW_2(SQ_B7), C7 = POW_2(SQ_C7), D7 = POW_2(SQ_D7), E7 = POW_2(SQ_E7), F7 = POW_2(SQ_F7), G7 = POW_2(SQ_G7), H7 = POW_2(SQ_H7), I7 = POW_2(SQ_I7),
				A8 = POW_2(SQ_A8), B8 = POW_2(SQ_B8), C8 = POW_2(SQ_C8), D8 = POW_2(SQ_D8), E8 = POW_2(SQ_E8), F8 = POW_2(SQ_F8), G8 = POW_2(SQ_G8), H8 = POW_2(SQ_H8), I8 = POW_2(SQ_I8),
				A9 = POW_2(SQ_A9), B9 = POW_2(SQ_B9), C9 = POW_2(SQ_C9), D9 = POW_2(SQ_D9), E9 = POW_2(SQ_E9), F9 = POW_2(SQ_F9), G9 = POW_2(SQ_G9), H9 = POW_2(SQ_H9), I9 = POW_2(SQ_I9);
				

const Bitboard FileABB = A0|A1|A2|A3|A4|A5|A6|A7|A8|A9;
const Bitboard FileBBB = B0|B1|B2|B3|B4|B5|B6|B7|B8|B9;
const Bitboard FileCBB = C0|C1|C2|C3|C4|C5|C6|C7|C8|C9;
const Bitboard FileDBB = D0|D1|D2|D3|D4|D5|D6|D7|D8|D9;
const Bitboard FileEBB = E0|E1|E2|E3|E4|E5|E6|E7|E8|E9;
const Bitboard FileFBB = F0|F1|F2|F3|F4|F5|F6|F7|F8|F9;
const Bitboard FileGBB = G0|G1|G2|G3|G4|G5|G6|G7|G8|G9;
const Bitboard FileHBB = H0|H1|H2|H3|H4|H5|H6|H7|H8|H9;
const Bitboard FileIBB = I0|I1|I2|I3|I4|I5|I6|I7|I8|I9;

const Bitboard Rank0BB = A0|B0|C0|D0|E0|F0|G0|H0|I0;
const Bitboard Rank1BB = A1|B1|C1|D1|E1|F1|G1|H1|I1;
const Bitboard Rank2BB = A2|B2|C2|D2|E2|F2|G2|H2|I2;
const Bitboard Rank3BB = A3|B3|C3|D3|E3|F3|G3|H3|I3;
const Bitboard Rank4BB = A4|B4|C4|D4|E4|F4|G4|H4|I4;
const Bitboard Rank5BB = A5|B5|C5|D5|E5|F5|G5|H5|I5;
const Bitboard Rank6BB = A6|B6|C6|D6|E6|F6|G6|H6|I6;
const Bitboard Rank7BB = A7|B7|C7|D7|E7|F7|G7|H7|I7;
const Bitboard Rank8BB = A8|B8|C8|D8|E8|F8|G8|H8|I8;
const Bitboard Rank9BB = A9|B9|C9|D9|E9|F9|G9|H9|I9;

const Bitboard WhiteCityBB = D0|E0|F0|D1|E1|F1|D2|E2|F2;
const Bitboard BlackCityBB = D7|E7|F7|D8|E8|F8|D9|E9|F9;
const Bitboard WhiteAdvisorCityBB = D0|F0|E1|D2|F2;
const Bitboard BlackAdvisorCityBB = D7|F7|E8|D9|F9;
const Bitboard WhiteBishopCityBB  = C0|G0|A2|E2|I2|C4|G4;
const Bitboard BlackBishopCityBB  = C9|G9|A7|E7|I7|C5|G5;

const Bitboard WhitePawnMaskBB = Rank9BB|Rank8BB|Rank7BB|Rank6BB|Rank5BB|A3|A4|C3|C4|E3|E4|G3|G4|I3|I4;
const Bitboard BlackPawnMaskBB = Rank0BB|Rank1BB|Rank2BB|Rank3BB|Rank4BB|A5|A6|C5|C6|E5|E6|G5|G6|I5|I6;

CACHE_LINE_ALIGNMENT

extern Bitboard RMasks[SQUARE_NB];

extern Bitboard RookR0[SQUARE_NB][128];
extern Bitboard RookRL90[SQUARE_NB][256];

extern Bitboard CannonSupperR0[SQUARE_NB][128];
extern Bitboard CannonSupperRL90[SQUARE_NB][256];
extern Bitboard CannonControlR0[SQUARE_NB][128];
extern Bitboard CannonControlRL90[SQUARE_NB][256];

extern Bitboard KnightStepLeg[SQUARE_NB][4];
extern Bitboard KnightStepTo[SQUARE_NB][4];
extern int8_t   KnightStepIndex[SQUARE_NB][SQUARE_NB];

extern Bitboard BishopStepLeg[SQUARE_NB][4];
extern Bitboard BishopSetpTo[SQUARE_NB][4];

extern Bitboard SquareBB[SQUARE_NB];
extern Bitboard SquareBBL90[SQUARE_NB];
extern Bitboard FileBB[FILE_NB];
extern Bitboard RankBB[RANK_NB];
extern Bitboard AdjacentFilesBB[FILE_NB];
extern Bitboard InFrontBB[COLOR_NB][RANK_NB];
extern Bitboard StepAttacksBB[PIECE_NB][SQUARE_NB];
extern Bitboard BetweenBB[SQUARE_NB][SQUARE_NB];
extern Bitboard DistanceRingsBB[SQUARE_NB][10];
extern Bitboard ForwardBB[COLOR_NB][SQUARE_NB];
extern Bitboard PassedPawnMask[COLOR_NB][SQUARE_NB];
extern Bitboard PawnAttackSpan[COLOR_NB][SQUARE_NB];
extern Bitboard PseudoAttacks[PIECE_TYPE_NB][SQUARE_NB];
extern Bitboard PawnNoMaskStepAttacksBB[COLOR_NB][SQUARE_NB];

extern Bitboard CityBB[COLOR_NB];
extern Bitboard AdvisorCityBB[COLOR_NB];
extern Bitboard BishopCityBB[COLOR_NB];

extern Bitboard PawnMask[COLOR_NB];
extern Bitboard PassedRiverBB[COLOR_NB];

extern int SquareDistance[SQUARE_NB][SQUARE_NB];

const Bitboard DarkSquares(0x00000000, 0xFFFFE000, 0xFFFFFFFF);

extern Square pop_lsb(Bitboard* b);

/// Overloads of bitwise operators between a Bitboard and a Square for testing
/// whether a given bit is set in a bitboard, and for setting and clearing bits.

inline Bitboard operator&(Bitboard b, Square s) {
  return b & SquareBB[s];
}

inline Bitboard& operator|=(Bitboard& b, Square s) {
  return b |= SquareBB[s];
}

inline Bitboard& operator^=(Bitboard& b, Square s) {
  return b ^= SquareBB[s];
}

inline Bitboard operator|(Bitboard b, Square s) {
  return b | SquareBB[s];
}

inline Bitboard operator^(Bitboard b, Square s) {
  return b ^ SquareBB[s];
}

inline bool more_than_one(Bitboard b) {
	return (b & (b.operator -(1)));
}

inline bool equal_to_two(Bitboard b){
   //it may be better than pop_cnt()
   Bitboard t = (b & (b.operator -(1)));
   if(t)
   {
	   return !(t & (t.operator -(1)));
   }
   return false;
}

inline int square_distance(Square s1, Square s2) {
  return SquareDistance[s1][s2];
}

inline int file_distance(Square s1, Square s2) {
  return abs(file_of(s1) - file_of(s2));
}

inline int rank_distance(Square s1, Square s2) {
  return abs(rank_of(s1) - rank_of(s2));
}


/// shift_bb() moves bitboard one step along direction Delta. Mainly for pawns.

template<Square Delta>
inline Bitboard shift_bb(Bitboard b) {

	return Delta == DELTA_N ? b << 9 : Delta == DELTA_S ? b >> 9
		:  Delta == DELTA_W ? (b & ~FileABB) >> 1 : Delta == DELTA_E ? (b & ~FileIBB) << 1
		:  Bitboard();
}


/// rank_bb() and file_bb() take a file or a square as input and return
/// a bitboard representing all squares on the given file or rank.

inline Bitboard rank_bb(Rank r) {
  return RankBB[r];
}

inline Bitboard rank_bb(Square s) {
  return RankBB[rank_of(s)];
}

inline Bitboard file_bb(File f) {
  return FileBB[f];
}

inline Bitboard file_bb(Square s) {
  return FileBB[file_of(s)];
}


/// adjacent_files_bb() takes a file as input and returns a bitboard representing
/// all squares on the adjacent files.

inline Bitboard adjacent_files_bb(File f) {
  return AdjacentFilesBB[f];
}


/// in_front_bb() takes a color and a rank as input, and returns a bitboard
/// representing all the squares on all ranks in front of the rank, from the
/// given color's point of view. For instance, in_front_bb(BLACK, RANK_3) will
/// give all squares on ranks 1 and 2.

inline Bitboard in_front_bb(Color c, Rank r) {
  return InFrontBB[c][r];
}


/// between_bb() returns a bitboard representing all squares between two squares.
/// For instance, between_bb(SQ_C4, SQ_F7) returns a bitboard with the bits for
/// square d5 and e6 set.  If s1 and s2 are not on the same line, file or diagonal,
/// 0 is returned.

inline Bitboard between_bb(Square s1, Square s2) {
  return BetweenBB[s1][s2];
}


/// forward_bb() takes a color and a square as input, and returns a bitboard
/// representing all squares along the line in front of the square, from the
/// point of view of the given color. Definition of the table is:
/// ForwardBB[c][s] = in_front_bb(c, s) & file_bb(s)

inline Bitboard forward_bb(Color c, Square s) {
  return ForwardBB[c][s];
}


/// pawn_attack_span() takes a color and a square as input, and returns a bitboard
/// representing all squares that can be attacked by a pawn of the given color
/// when it moves along its file starting from the given square. Definition is:
/// PawnAttackSpan[c][s] = in_front_bb(c, s) & adjacent_files_bb(s);

inline Bitboard pawn_attack_span(Color c, Square s) {
  return PawnAttackSpan[c][s];
}


/// passed_pawn_mask() takes a color and a square as input, and returns a
/// bitboard mask which can be used to test if a pawn of the given color on
/// the given square is a passed pawn. Definition of the table is:
/// PassedPawnMask[c][s] = pawn_attack_span(c, s) | forward_bb(c, s)

inline Bitboard passed_pawn_mask(Color c, Square s) {
  return PassedPawnMask[c][s];
}


/// squares_of_color() returns a bitboard representing all squares with the same
/// color of the given square.

inline Bitboard squares_of_color(Square s) {
  return DarkSquares & s ? DarkSquares : ~DarkSquares;
}

/// squares_aligned() returns true if the squares s1, s2 and s3 are aligned
/// either on a straight or on a diagonal line.

inline bool squares_aligned(Square s1, Square s2, Square s3) {
  return  (BetweenBB[s1][s2] | BetweenBB[s1][s3] | BetweenBB[s2][s3])
        & (     SquareBB[s1] |      SquareBB[s2] |      SquareBB[s3]);
}

//help function
inline Bitboard bitboard_rotate_l90_bb(Bitboard occ)
{
	Bitboard occl90(0,0,0);
	for (Square s = SQ_A0; s <= SQ_I9; ++s)
	{
		if(occ&SquareBB[s])
		{
            occl90 |= SquareBBL90[s];
		}
	}

	return occl90;
}

//
inline Bitboard rook_rank_attacks_bb(Square s, Bitboard occ)
{
	return RookR0[s][((occ>>(rank_of(s)*9 + 1)).low)&127];
}

inline Bitboard rook_file_attacks_bb(Square s, Bitboard occl90)
{
	return RookRL90[s][((occl90>>(file_of(s)*10 +1)).low)&255];
}

inline Bitboard rook_attacks_bb(Square s, Bitboard occ, Bitboard occl90)
{
    return (RookR0[s][((occ>>(rank_of(s)*9 + 1)).low)&127]) | (RookRL90[s][((occl90>>(file_of(s)*10 + 1)).low)&255]);
}

inline Bitboard cannon_rank_control_bb(Square s, Bitboard occ)
{
   return CannonControlR0[s][((occ>>(rank_of(s)*9+ 1)).low)&127];
}

inline Bitboard cannon_file_control_bb(Square s, Bitboard occl90)
{
	return CannonControlRL90[s][((occl90>>(file_of(s)*10 + 1)).low)&255];
}

//include capture pos, capture bitboard is result&occ
inline Bitboard cannon_control_bb(Square s, Bitboard occ, Bitboard occl90)
{
	return (CannonControlR0[s][((occ>>(rank_of(s)*9 + 1)).low)&127])|(CannonControlRL90[s][((occl90>>(file_of(s)*10 + 1)).low)&255]);
}

inline Bitboard cannon_rank_supper_pin_bb(Square s, Bitboard occ)
{
	return CannonSupperR0[s][((occ>>(rank_of(s)*9 + 1)).low)&127];
}

inline Bitboard cannon_file_supper_pin_bb(Square s, Bitboard occl90)
{
	return CannonSupperRL90[s][((occl90>>(file_of(s)*10 + 1)).low)&255];
}

inline Bitboard cannon_supper_pin_bb(Square s, Bitboard occ, Bitboard occl90)
{
	return  CannonSupperR0[s][((occ>>(rank_of(s)*9 + 1)).low)&127] | CannonSupperRL90[s][((occl90>>(file_of(s)*10 + 1)).low)&255];
}

inline bool square_in_city(Color c, Square s)
{
   return CityBB[c]&s;
}

inline bool advisor_in_city(Color c, Square s)
{
	return AdvisorCityBB[c]&s;
}

inline bool bishop_in_city(Color c, Square s)
{
   return BishopCityBB[c]&s;
}

inline bool pawn_square_ok(Color c, Square s)
{
   return PawnMask[c]&s;
}

inline Bitboard square_rotate_l90_bb(Square s)
{
   return  SquareBBL90[s];
}

//NOTE: from attack to doesnt mean to attack from
inline Bitboard knight_attacks_bb(Square s, Bitboard occ)
{
   Bitboard b;
   
   if(KnightStepLeg[s][0] && !(KnightStepLeg[s][0] & occ) )  b |= KnightStepTo[s][0];
   if(KnightStepLeg[s][1] &&  !(KnightStepLeg[s][1] & occ) )  b |= KnightStepTo[s][1];
   if(KnightStepLeg[s][2] &&  !(KnightStepLeg[s][2] & occ) ) b |= KnightStepTo[s][2];
   if(KnightStepLeg[s][3] &&  !(KnightStepLeg[s][3] & occ) ) b |= KnightStepTo[s][3];

   return b;
}

inline Bitboard knight_attacks_bb(Square s)
{
	return StepAttacksBB[KNIGHT][s];//马部分黑白，所以可以这样用
}

//攻击到s位置的马的位棋盘，真实的马的位置
inline Bitboard knight_attackers_to_bb(Square s, Bitboard occknight, Bitboard occ)
{
    Bitboard b;
	
	Bitboard knights = knight_attacks_bb(s) & occknight;//马的位置

	while (knights)
	{
		Square k = pop_lsb(&knights);

		//KnightStepTo[k][0]&s 意思是，k攻击到s，因为k可以有四个方向
		if(KnightStepTo[k][0]&s && !(KnightStepLeg[k][0] & occ) && KnightStepLeg[k][0])//马腿没子
		{
			b |= k; continue;			
		}
		if(KnightStepTo[k][1]&s && !(KnightStepLeg[k][1] & occ) && KnightStepLeg[k][1])
		{
			b |= k; continue;
		}
		if(KnightStepTo[k][2]&s && !(KnightStepLeg[k][2] & occ) && KnightStepLeg[k][2]) 
		{
			b |= k; continue;
		}
		if(KnightStepTo[k][3]&s && !(KnightStepLeg[k][3] & occ) && KnightStepLeg[k][3])
		{
			b |= k; continue;
		}
		
	}

	return b;
}

//可以攻击到to位置的位置,用于CheckInfo，位置的位置可能没有子
inline Bitboard knight_attacks_to_bb(Square s, Bitboard occ)
{
     Bitboard b;
	
	 Bitboard from = knight_attacks_bb(s);
	while(from)
	{
		Square k = pop_lsb(&from);

		if(KnightStepTo[k][0]&s && !(KnightStepLeg[k][0] & occ) && KnightStepLeg[k][0])
		{
			b |= k; continue;			
		}
		if(KnightStepTo[k][1]&s && !(KnightStepLeg[k][1] & occ) && KnightStepLeg[k][1])
		{
			b |= k; continue;
		}
		if(KnightStepTo[k][2]&s && !(KnightStepLeg[k][2] & occ) && KnightStepLeg[k][2]) 
		{
			b |= k; continue;
		}
		if(KnightStepTo[k][3]&s && !(KnightStepLeg[k][3] & occ) && KnightStepLeg[k][3])
		{
			b |= k; continue;
		}
	}

	return b;
}

inline Bitboard bishop_attacks_bb(Square s, Bitboard occ)
{
	Bitboard b;

	if(BishopStepLeg[s][0] &&  !(BishopStepLeg[s][0] & occ) ) b |= BishopSetpTo[s][0];
	if(BishopStepLeg[s][1] &&  !(BishopStepLeg[s][1] & occ) ) b |= BishopSetpTo[s][1];
	if(BishopStepLeg[s][2] &&  !(BishopStepLeg[s][2] & occ) ) b |= BishopSetpTo[s][2];
	if(BishopStepLeg[s][3] &&  !(BishopStepLeg[s][3] & occ) ) b |= BishopSetpTo[s][3];

	return b;
}

/// lsb()/msb() finds the least/most significant bit in a nonzero bitboard.
/// pop_lsb() finds and clears the least significant bit in a nonzero bitboard.

extern Square msb(Bitboard b);
extern Square lsb(Bitboard b);
extern Square pop_lsb(Bitboard* b);
extern size_t pop_lsb(uint64_t* b);
extern size_t msb(size_t b);


/// frontmost_sq() and backmost_sq() find the square corresponding to the
/// most/least advanced bit relative to the given color.

inline Square frontmost_sq(Color c, Bitboard b) { return c == WHITE ? msb(b) : lsb(b); }
inline Square  backmost_sq(Color c, Bitboard b) { return c == WHITE ? lsb(b) : msb(b); }

inline void test_bitboard()
{
   Bitboards::init();

   Bitboard n;
   n |= SQ_D5;
   n |= SQ_E4;
   n |= SQ_E5;
   n |= SQ_F6;
   n |= SQ_D7;
   n |= SQ_F7;

   //Bitboards::print(knight_attacks_to_bb(SQ_E5, n));
   //Bitboards::print(knight_attacks_bb(SQ_E5, n));
   //Bitboards::print(knight_attackers_to_bb(SQ_E5, n, n));

   //clock_t t = clock();
   //for(int i = 0 ; i < 9999999; ++i)
   //{
	  // knight_attacks_to_bb(SQ_E5, n);
   //}
   //printf("%d\n",clock()-t);

   //t = clock();
   //for(int i = 0 ; i < 9999999; ++i)
   //{
	  // knight_attacks_to_bb__(SQ_E5, n);
   //}
   //printf("%d\n",clock()-t);


   //for(int i = 0; i < 10; ++i)
   //{
   //    Bitboards::print(SquareBB[i]);
   //}
   //for(int i = 0; i < 9; ++i)   
   //{
   //    Bitboards::print(FileBB[i]);
   //}
   //for(int i = 0; i < 10; ++i)   
   //{
   //    Bitboards::print(RankBB[i]);
   //}

   {
	   //for(Square i = SQ_A0; i < SQUARE_NB; ++i)  
	   //{
		  // for(int k = 0; k < 128; ++k)
		  // {
			 //  Bitboards::print(RookR0[i][k]);
		  // }
	   //}

	   //for(Square i = SQ_A0; i < SQUARE_NB; ++i)  
	   //{
		  // for(int k = 0; k < 256; ++k)
		  // {
			 //  Bitboards::print(RookRL90[i][k]);
		  // }
	   //}

	   //Bitboards::print(RookR0[1][4]);	
	   //Bitboards::print(RookRL90[1][1]);
	   //Bitboards::print(rook_rank_attacks_bb(Square(0),RankBB[0]|FileBB[0]));
	   //Bitboards::print(rook_file_attacks_bb(Square(0),bitboard_rotate_l90_bb(FileBB[0])));
	  // Bitboards::print(rook_rank_attacks_bb(Square(0),FileBB[0]));
	   //Bitboards::print(rook_file_attacks_bb(Square(0),bitboard_rotate_l90_bb(RankBB[0])));
  //      Bitboards::print(rook_attacks_bb(Square(0),RankBB[0],bitboard_rotate_l90_bb(RankBB[0])));
		//Bitboards::print(rook_attacks_bb(Square(0),FileBB[0],bitboard_rotate_l90_bb(FileBB[0])));
		//Bitboards::print(rook_attacks_bb(Square(0),FileBB[0]|RankBB[0],bitboard_rotate_l90_bb(FileBB[0]|RankBB[0])));
		//Bitboards::print(rook_attacks_bb(Square(SQ_B1),FileBB[1]|RankBB[1],bitboard_rotate_l90_bb(FileBB[1]|RankBB[1])));
   }

   {
	   Bitboard t;
	   for(Square i = SQ_A0; i < SQUARE_NB; ++i)   
	   {
		   //Bitboards::print(RMasks[i]);

		   //Bitboards::print(SquareBBL90[i]);

		   //Square s = Square(file_of(i) * 10 + (9-rank_of(i)));//File(9-rank_of(i))|Rank(file_of(i));very different bug
		   //printf("(%d %d)%d->%d ",file_of(i),9-rank_of(i),i,s);
	   }
   }

   printf("\n");

   {
	   //extern Bitboard CannonSupperR0[SQUARE_NB][512];
	   //extern Bitboard CannonSupperRL90[SQUARE_NB][1024];
	   //extern Bitboard CannonControlR0[SQUARE_NB][512];
	   //extern Bitboard CannonControlRL90[SQUARE_NB][1024];
	   //Bitboards::print(CannonSupperR0[0][15]);
	   //Bitboards::print(CannonControlR0[0][15]);  
   }
   {
	   //extern Bitboard KnightStepLeg[SQUARE_NB][4];
	   //extern Bitboard KnightStepTo[SQUARE_NB][4];
	   //extern Bitboard BishopStepLeg[SQUARE_NB][4];
	   //extern Bitboard BishopSetpTo[SQUARE_NB][4];
   }

   {
	   //extern Bitboard SquareBB[SQUARE_NB];
	   //extern Bitboard SquareBBL90[SQUARE_NB];
	   //extern Bitboard FileBB[FILE_NB];
	   //extern Bitboard RankBB[RANK_NB];
	   //extern Bitboard AdjacentFilesBB[FILE_NB];
	   //extern Bitboard InFrontBB[COLOR_NB][RANK_NB];
	   //extern Bitboard StepAttacksBB[PIECE_NB][SQUARE_NB];
	   //extern Bitboard BetweenBB[SQUARE_NB][SQUARE_NB];
	   //extern Bitboard DistanceRingsBB[SQUARE_NB][10];
	   //extern Bitboard ForwardBB[COLOR_NB][SQUARE_NB];
	   //extern Bitboard PassedPawnMask[COLOR_NB][SQUARE_NB];
	   //extern Bitboard PawnAttackSpan[COLOR_NB][SQUARE_NB];
	   //extern Bitboard PseudoAttacks[PIECE_TYPE_NB][SQUARE_NB];
	   //extern Bitboard PawnNoMaskStep[COLOR_NB][SQUARE_NB];

	   //extern Bitboard CityBB[COLOR_NB];
	   //extern Bitboard AdvisorCityBB[COLOR_NB];
	   //extern Bitboard BishopCityBB[COLOR_NB];

	   //extern Bitboard PawnMask[COLOR_NB];
	   //extern Bitboard PassedRiverBB[COLOR_NB];

	   //extern int SquareDistance[SQUARE_NB][SQUARE_NB];

	   //const Bitboard DarkSquares(0x00000000, 0xFFFFE000, 0xFFFFFFFF);

	   //Bitboards::print(PawnMask[WHITE]);
	   //Bitboards::print(PawnMask[BLACK]);

	   //Bitboards::print(PassedRiverBB[WHITE]);
	   //Bitboards::print(PassedRiverBB[BLACK]);

	   for (Color c = WHITE; c <= BLACK; ++c)
		   for (Square s = SQ_A0; s <= SQ_I9; ++s)
		   {
			   //Bitboards::print(ForwardBB[c][s]);
			   //Bitboards::print(PawnAttackSpan[c][s]);
			   
		   }


	   SquareDistance[SQ_A1][SQ_H8];
   }
   
   for(int i = 0; i < 10; ++i)
   {
	   //Bitboards::print(in_front_bb(WHITE,Rank(i)));
   }

   for(int i = 0; i < 9; ++i)
   {	   
	   //Bitboards::print(adjacent_files_bb(File(i)));
   }

   for(int i = 0; i < 90; ++i)
	   for(int j = 0; j < 90; ++j)
   {	   
	  // Bitboards::print(between_bb(Square(i), Square(j)));
   }

   
	//Bitboards::print(forward_bb(WHITE,Square(1)));
  
	//Bitboards::print( PassedPawnMask[0][5]);
    //Bitboards::print( PawnAttackSpan[0][5]);

	//Bitboards::print( InFrontBB[0][5]);
	
  	//Bitboards::print( DistanceRingsBB[SQ_E1][0]);

     for (Color c = WHITE; c <= BLACK; ++c)
      for (PieceType pt = ADVISOR; pt <= ADVISOR; ++pt)
          //for (Square s = SQ_A0; s <= SQ_I9; ++s)
		  {
				//Bitboards::print( StepAttacksBB[make_piece(c, pt)][13]);
		  }
     //Bitboards::print(~DarkSquares);

	  //Bitboards::print(CityBB[WHITE]);  
	  //Bitboards::print(CityBB[BLACK]);  

	 //Bitboards::print(AdvisorCityBB[WHITE]);  
	 //Bitboards::print(AdvisorCityBB[BLACK]);  

	 //Bitboards::print(BishopCityBB[WHITE]);  
	 //Bitboards::print(BishopCityBB[BLACK]); 

	 //printf("%d", square_in_city(WHITE, Square(5)));

	  {
		  //for(int i = 0; i < 90; ++i)
		  //{
		  // Bitboard b(0x3,0,0);
		  // b = b<<i;	   
		  // printf("%d ", (int)lsb(b));
		  // printf("%d ", (int)msb(b));
		  //}
		  //Bitboard b(0x3,0,0);
		  //printf("%d ", (int)lsb(b));
		  //printf("%d ", (int)msb(b));

		  //Bitboard b(0xFFFFFFFF,0xFFFFFFFF,0x03FFFFFF);
		  //for(int i = 0; i < 90; ++i)
		  //{
			 // Square t = pop_lsb(&b);
			 // printf("%d ",t);
		  //}
	  }

	  {
		  //Bitboard b(0x3,0,0);
		  //Bitboard b(0x5,0,0);
		  //Bitboard b(0x7,0,0);
		  //printf("more_than_one %s\n", more_than_one(b) ? "yes" : "no");
		  //printf("equal_to_two %s\n", equal_to_two(b) ? "yes" : "no"); 

	  }

	  {
		 // for(int i = 0; i < 90; ++i)
		  {
			  //Bitboards::print(PawnNoMaskStepAttacksBB[BLACK][i]);

			  //Bitboards::print(knight_attacks_bb(Square(i), ~(Bitboard())));
			  //Bitboards::print(bishop_attacks_bb(i, ~(Bitboard())));

			 // KnightStepLeg[s][0] & occ) )  b |= KnightStepTo[s][0]
			  //Bitboards::print(KnightStepLeg[SQ_B9][0]);
			  //Bitboards::print(KnightStepLeg[SQ_B9][1]);
			  //Bitboards::print(KnightStepLeg[SQ_B9][2]);
			  //Bitboards::print(KnightStepLeg[SQ_B9][3]);

			  //Bitboards::print(BishopStepLeg[SQ_E2][0]);
			  //Bitboards::print(BishopStepLeg[SQ_E2][1]);
			  //Bitboards::print(BishopStepLeg[SQ_E2][2]);
			  //Bitboards::print(BishopStepLeg[SQ_E2][3]);

			  
			  //Bitboards::print(StepAttacksBB[make_piece(BLACK, KING)][SQ_C8]);
		  }
	  }

	  {
    //      Bitboard b( 0x41dc1000,0x02010080,0x00000804);

		  //while(b)
		  //{
			 // Square t = pop_lsb(&b);
			 // printf("%d ",t);
		  //}


	  }
}

#endif // #ifndef BITBOARD_H_INCLUDED
