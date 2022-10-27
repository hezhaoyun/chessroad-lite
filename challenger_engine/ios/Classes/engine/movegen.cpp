/*
Challenger, a UCI chess playing engine derived from Stockfish

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

#include <cassert>
#include <algorithm>
#include <cassert>
#include <cstring>
#include <iomanip>
#include <iostream>
#include <sstream>

#include "movegen.h"
#include "position.h"
#include "notation.h"

/// Simple macro to wrap a very common while loop, no facny, no flexibility,
/// hardcoded names 'mlist' and 'from'.
#define SERIALIZE(b) while (b) (mlist++)->move = make_move(from, pop_lsb(&b))

/// Version used for pawns, where the 'from' square is given as a delta from the 'to' square
#define SERIALIZE_PAWNS(b, d) while (b) { Square to = pop_lsb(&b); \
	(mlist++)->move = make_move(to - (d), to); }

bool move_is_legal(const Position& pos, Move move)
{

	Move m = move;
	assert(is_ok(m));	

	Color us = pos.side_to_move();
	Square from = from_sq(m);
	Square to   = to_sq(m);

	assert(color_of(pos.piece_moved(m)) == us);
	assert(pos.piece_on(pos.king_square(us)) == make_piece(us, KING));

	PieceType pfr = type_of(pos.piece_on(from));
	PieceType pto= type_of(pos.piece_on(to));

	Bitboard pawns   = pos.pieces(~us, PAWN);
	Bitboard knights = pos.pieces(~us, KNIGHT);
	Bitboard cannons = pos.pieces(~us, CANNON);
	Bitboard rooks = pos.pieces(~us, ROOK);

	Bitboard  occ    = pos.pieces();
	Bitboard  occl90 = pos.piecesl90();

	occl90 ^= square_rotate_l90_bb(from);
	occ    ^= from;

	if(pto == NO_PIECE_TYPE)
	{
		occl90 ^= square_rotate_l90_bb(to);
		occ    ^= to;
	}

	Square ksq = pos.king_square(us);
	if(ksq == from)
		ksq = to;

	if (pto != NO_PIECE_TYPE)
	{
		switch(pto)
		{
		case PAWN:
			pawns ^= to;
			break;
		case KNIGHT:
			knights ^= to;
			break;
		case ROOK:
			rooks ^= to;
			break;
		case CANNON:
			cannons ^= to;
			break;
		}
	}



	if((PseudoAttacks[ROOK][ksq]& cannons) &&(cannon_control_bb(ksq, occ,occl90) & cannons)) return false;
	if((PseudoAttacks[ROOK][ksq]& rooks) && (rook_attacks_bb(ksq,occ,occl90)& rooks) ) return false;
	if( knight_attackers_to_bb(ksq, knights, occ) ) return false;
	if( pos.attacks_from_pawn_nomask(ksq, us) & pawns ) return false;

	if((PseudoAttacks[ROOK][ksq]& pos.king_square(~us)) && (rook_attacks_bb(ksq,occ,occl90)& pos.king_square(~us))) return false;//对脸

	return true;
}
bool move_is_check(const Position& pos, Move move)
{
	Color us = pos.side_to_move();
	Square from = from_sq(move);
	Square to = to_sq(move);
	Square ksq = pos.king_square(~us);

	PieceType pfr = type_of(pos.piece_on(from));
	PieceType pto = type_of(pos.piece_on(to));

	Bitboard pawns = pos.pieces(us, PAWN);
	Bitboard knights = pos.pieces(us, KNIGHT);
	Bitboard cannons = pos.pieces(us, CANNON);
	Bitboard rooks = pos.pieces(us, ROOK);

	Bitboard  occ = pos.pieces();
	Bitboard  occl90 = pos.piecesl90();

	occ ^= from;
	occl90 ^= square_rotate_l90_bb(from);
	if (pto == NO_PIECE_TYPE)
	{
		occ ^= to;
		occl90 ^= square_rotate_l90_bb(to);
	}

	switch (pfr)
	{
	case ROOK:
		rooks ^= from;
		rooks ^= to;
		break;
	case CANNON:
		cannons ^= from;
		cannons ^= to;
		break;
	case KNIGHT:
		knights ^= from;
		knights ^= to;
		break;
	case PAWN:
		pawns ^= from;
		pawns ^= to;
		break;
	default:break;
	}

	if((PseudoAttacks[ROOK][ksq]& cannons) &&(cannon_control_bb(ksq, occ,occl90) & cannons)) return true;
	if((PseudoAttacks[ROOK][ksq]& rooks) && (rook_attacks_bb(ksq,occ,occl90)& rooks) ) return true;
	if( knight_attackers_to_bb(ksq, knights, occ) ) return true;
	if( pos.attacks_from_pawn_nomask(ksq, ~us) & pawns ) return true;

	return false;
}

namespace {


	static ExtMove* gen_rook_moves(const Position& pos, ExtMove* mlist, Bitboard target)
	{
		Color    us     = pos.side_to_move();
		//Bitboard target = ~pos.pieces(us);
		const Square* pl = pos.list<ROOK>(us);
		for (Square from = *pl; from != SQ_NONE; from = *++pl)
		{
			Bitboard att = pos.attacks_from<ROOK>(from)&target;

			SERIALIZE(att);
		}
		return mlist;
	}
	static ExtMove* gen_knight_moves(const Position& pos, ExtMove* mlist, Bitboard target)
	{
		Color    us     = pos.side_to_move();
		//Bitboard target = ~pos.pieces(us);
		const Square* pl = pos.list<KNIGHT>(us);
		for (Square from = *pl; from != SQ_NONE; from = *++pl)
		{
			Bitboard att = pos.attacks_from<KNIGHT>(from)&target;

			SERIALIZE(att);
		}
		return mlist;
	}
	static ExtMove* gen_cannon_moves(const Position& pos, ExtMove* mlist, Bitboard target)
	{
		Color    us     = pos.side_to_move();
		//Bitboard target = pos.pieces(~us);
		Bitboard empty  = ~pos.pieces();
		const Square* pl = pos.list<CANNON>(us);
		for (Square from = *pl; from != SQ_NONE; from = *++pl)
		{
			Bitboard att = pos.attacks_from<CANNON>(from)&target&pos.pieces(~us);

			SERIALIZE(att);

			Bitboard natt = pos.attacks_from<ROOK>(from)&empty&target;
			SERIALIZE(natt);
		}
		return mlist;
	}
	template<Color Us>
	static ExtMove* gen_pawn_moves(const Position& pos, ExtMove* mlist, Bitboard target)
	{
		Color    us     = pos.side_to_move();
		//Bitboard target = ~pos.pieces(us);
		Bitboard pawns  = pos.pieces(us, PAWN);

		const Square   Up       = (Us == WHITE ? DELTA_N  : DELTA_S);
		const Square   Right    = (Us == WHITE ? DELTA_E : DELTA_W);
		const Square   Left     = (Us == WHITE ? DELTA_W : DELTA_E);

		const Bitboard MaskBB   =  PawnMask[us];

		Bitboard attup = shift_bb<Up>(pawns) & MaskBB & target;
		Bitboard attleft = shift_bb<Left>(pawns) & MaskBB & target;
		Bitboard attright= shift_bb<Right>(pawns) & MaskBB & target;

		while(attup){
			Square to = pop_lsb(&attup);
			Square from = to - (Up);		

			(mlist++)->move = make_move(from, to);
		}

		while(attleft){
			Square to = pop_lsb(&attleft);
			Square from = to - (Left);		
			(mlist++)->move = make_move(from, to);
		}

		while(attright){
			Square to = pop_lsb(&attright);
			Square from = to - (Right);		
			(mlist++)->move = make_move(from, to);
		}
		return mlist;
	}
	static ExtMove* gen_bishop_moves(const Position& pos, ExtMove* mlist, Bitboard target)
	{
		Color    us     = pos.side_to_move();
		//Bitboard target = ~pos.pieces(us);
		const Square* pl = pos.list<BISHOP>(us);
		for (Square from = *pl; from != SQ_NONE; from = *++pl)
		{
			Bitboard att = pos.attacks_from<BISHOP>(from, us)&target;

			SERIALIZE(att);
		}
		return mlist;
	}
	static ExtMove* gen_advisor_moves(const Position& pos, ExtMove* mlist, Bitboard target)
	{
		Color    us     = pos.side_to_move();
		//Bitboard target = ~pos.pieces(us);
		const Square* pl = pos.list<ADVISOR>(us);
		for (Square from = *pl; from != SQ_NONE; from = *++pl)
		{
			Bitboard att = pos.attacks_from<ADVISOR>(from, us)&target;

			SERIALIZE(att);
		}
		return mlist;
	}
	static ExtMove* gen_king_moves(const Position& pos, ExtMove* mlist, Bitboard target)
	{
		Color    us     = pos.side_to_move();
		//Bitboard target = ~pos.pieces(us);
		const Square* pl = pos.list<KING>(us);
		for (Square from = *pl; from != SQ_NONE; from = *++pl)
		{
			Bitboard att = pos.attacks_from<KING>(from,us)&target;

			SERIALIZE(att);
		}
		return mlist;
	}
} // namespace

template<Color Us, GenType Type> FORCE_INLINE
ExtMove* generate_all(const Position& pos, ExtMove* mlist, Bitboard target,
					  const CheckInfo* ci = NULL) {

						  const bool Checks = Type == QUIET_CHECKS;						 

						  mlist = gen_rook_moves(pos, mlist,target);
						  mlist = gen_knight_moves(pos, mlist,target);
						  mlist = gen_cannon_moves(pos, mlist,target);
						  mlist = gen_pawn_moves<Us>(pos, mlist,target);
						  mlist = gen_bishop_moves(pos, mlist,target);
						  mlist = gen_advisor_moves(pos, mlist,target);

						  if(QUIET_CHECKS != Type)
							  mlist = gen_king_moves(pos, mlist,target);

						  return mlist;

}
template<GenType Type>
ExtMove* generate(const Position& pos, ExtMove* mlist) {

	assert(Type == CAPTURES || Type == QUIETS || Type == NON_EVASIONS);
	assert(!pos.checkers());

	Color us = pos.side_to_move();

	Bitboard target = Type == CAPTURES     ?  pos.pieces(~us)
		: Type == QUIETS       ? ~pos.pieces()
		: Type == NON_EVASIONS ? ~pos.pieces(us) : Bitboard();

	return us == WHITE ? generate_all<WHITE, Type>(pos, mlist, target)
		: generate_all<BLACK, Type>(pos, mlist, target);
}

// Explicit template instantiations
template ExtMove* generate<CAPTURES>(const Position&, ExtMove*);
template ExtMove* generate<QUIETS>(const Position&, ExtMove*);
template ExtMove* generate<NON_EVASIONS>(const Position&, ExtMove*);

template<>
ExtMove* generate<QUIET_CHECKS>(const Position& pos, ExtMove* mlist) {

	assert(!pos.checkers());

	Color us = pos.side_to_move();
	CheckInfo ci(pos);

	ExtMove *end, *cur = mlist;

	end = us == WHITE ? generate_all<WHITE, QUIET_CHECKS>(pos, mlist, ~pos.pieces(), &ci)
		: generate_all<BLACK, QUIET_CHECKS>(pos, mlist, ~pos.pieces(), &ci);

	//remove uncheck opp

	while (cur != end)
	{
		if(move_is_check(pos, cur->move)){
			cur++;
		}
		else{
			cur->move = (--end)->move;
		}
	}

	return end;
}
template<>
ExtMove* generate<EVASIONS>(const Position& pos, ExtMove* mlist){

	Color us = pos.side_to_move();
	Bitboard target = ~pos.pieces(us);

	ExtMove *end, *cur = mlist;

	end = us == WHITE ? generate_all<WHITE, EVASIONS>(pos, mlist, target)
		: generate_all<BLACK, EVASIONS>(pos, mlist, target);

	while (cur != end)
	{
		if(move_is_legal(pos, cur->move)){
			cur++;
		}
		else{
			cur->move = (--end)->move;
		}
	}

	return end;
}
template<>
ExtMove* generate<LEGAL>(const Position& pos, ExtMove* mlist){

	ExtMove *end, *cur = mlist;
	Bitboard pinned = pos.pinned_pieces();
	Square ksq = pos.king_square(pos.side_to_move());

	end = pos.checkers() ? generate<EVASIONS>(pos, mlist)
		: generate<NON_EVASIONS>(pos, mlist);
	while (cur != end)
	{
		if(move_is_legal(pos, cur->move)){

			//if (move_is_check(pos, cur->move))
			//{
			//             std::cout<<"move is check "<< move_to_chinese(pos,cur->move).c_str()<<std::endl;
			//}

			cur++;
		}
		else{
			cur->move = (--end)->move;
		}
	}

	//std::cout<< std::endl;
	//cur = mlist;
	//for(; cur != end; ++cur)
	//{
	//	std::cout<< move_to_chinese(pos,cur->move).c_str()<<std::endl;
	//}
	//std::cout<<pos.pretty();

	return end;
}
void test_move_gen( Position& pos)
{
	//Bitboard target;
	//target = ~target;

	std::cout<<"------------------"<<std::endl;

	ExtMove mlist[MAX_MOVES];
	ExtMove *cur, *last;
	cur = mlist;

	//last = generate_pawn_moves<WHITE, NON_EVASIONS>(pos, mlist, target, 0);
	// last = generate_moves<  ROOK, false>(pos, mlist, WHITE, target, 0);

	// last = generate_moves<  KNIGHT, false>(pos, mlist, WHITE, target, 0);
	//last = generate_moves<  CANNON, false>(pos, mlist, WHITE, target, 0);
	//last = generate_moves<  ADVISOR, false>(pos, mlist, WHITE, target, 0);
	//last = generate_moves<  BISHOP, false>(pos, mlist, WHITE, target, 0);
	///last = generate_moves<  KING, false>(pos, mlist, WHITE, target, 0);

	//last = generate<CAPTURES>(pos, mlist);
	//last = generate<QUIETS>(pos, mlist);
	//last = generate<NON_EVASIONS>(pos, mlist);
	last = generate<QUIET_CHECKS>(pos, mlist);

	std::cout<< std::endl;
	for(; cur != last; ++cur)
	{
		std::cout<< move_to_chinese(pos,cur->move).c_str();
	}
}


