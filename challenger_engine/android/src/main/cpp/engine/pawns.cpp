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

#include <algorithm>
#include <cassert>

#include "bitboard.h"
#include "bitcount.h"
#include "pawns.h"
#include "position.h"

namespace {

  #define V Value
  #define S(mg, eg) make_score(mg, eg)

  //Block knight by flag and file
	const Score BlockKnight[2][FILE_NB] = {
		{
			S(5, 3), S(5, 6), S(10, 8), S(9, 8),S(9, 8), S(9, 8), S(10, 8), S(5, 6), S(5, 3)
		},
		{
			S(13, 23), S(20, 23), S(20, 28), S(23, 28),S(26, 28), S(23, 28), S(20, 28), S(20, 23), S(13, 23)
		},
	};

  //front no pawn
  const Score FrontNoPawn[FILE_NB] = 
  {
      S(2, 10), S(4, 15), S(8, 20), S(4, 25),S(14, 28), S(4, 25), S(8, 20), S(4, 15), S(2, 10)
  };
  //connect pawn
  const Score ConnectPawn[FILE_NB] = 
  {
	  S(0, 0), S(2, 4), S(4, 10), S(10, 15),S(10, 15), S(10, 10), S(4, 4), S(2, 4), S(0, 0)
  };
  //distance with them king
  const Score DistanceWithKing[FILE_NB] = 
  {
      S(0, 0), S(10, 30), S(8, 30), S(6, 25),S(4, 20), S(2, 15), S(0, 10), S(0, 0), S(0, 0)
  };
  //passed river
  const Score PassedRiver[SQUARE_NB] = 
  {
	  S(-20, -20),S(-15, -15),S(-10, -10),S(-5, -5),S(0,  0), S(-5, -5),S(-10,-10),S(-15, -15),S(-20, -20),
	  S(-5,    0),S(15,   20),S(25,   35),S(28, 38),S(38, 58),S(28, 38),S(25,  35),S(15,   20),S(-5,    0),
	  S(5,    20),S(15,   20),S(25,   25),S(25, 30),S(25, 40),S(25, 40),S(25,  30),S(15,   20),S(5,    20),
	  S(15,   20),S(15,   20),S(20,   25),S(25, 30),S(25, 35),S(25, 30),S(20,  25),S(15,   20),S(15,   20),
	  S(10,   15),S(15,   20),S(20,   25),S(20, 30),S(25, 35),S(20, 30),S(20,  25),S(15,   20),S(10,   15),

	  S(10, 15), S(15, 20), S(20, 25), S(20, 30),S(25, 35),S(20, 30),S(20,  25),S(15,  20),S(10, 15),
	  S(15, 20), S(15, 20), S(20, 25), S(25, 30),S(25, 35),S(25, 30),S(20,  25),S(15,  20),S(15, 20),
	  S(5,  20), S(15, 20), S(25, 25), S(25, 40),S(25, 40),S(25, 40),S(25,  30),S(15,  20),S(5,  20),
	  S(-5, 0),  S(15, 20), S(25, 35), S(28, 40),S(48, 58),S(28, 40),S(25,  35),S(15,  20),S(-5,  0),
	  S(-20,-20),S(-15,-15),S(-10,-10),S(-5, -5),S(0,   0),S(-5, -5),S(-10,-10),S(-15,-15),S(-20,-20),	 
  };

  #undef S
  #undef V

  template<Color Us>
  Score evaluate(const Position& pos, Pawns::Entry* e) {

    const Color  Them  = (Us == WHITE ? BLACK    : WHITE);
    const Square Up    = (Us == WHITE ? DELTA_N  : DELTA_S);
    const Square Right = (Us == WHITE ? DELTA_E : DELTA_W);
    const Square Left  = (Us == WHITE ? DELTA_W : DELTA_E);

	//过河兵， 连兵， 进九宫的兵，底线兵，前面没有对方兵的兵,阻碍我方马腿的兵前向的

    Bitboard b;
    Square s;
    File f;
    //bool passed, isolated, doubled, opposed, chain, /*backward, candidate*/, blockKnight,passedRiver,frontp;
	bool passedRiver, frontp,blockKnight,opposed,chain;
    Score value = SCORE_ZERO;
    const Square* pl = pos.list<PAWN>(Us);
	Square ksq = pos.king_square(Them);

    Bitboard ourPawns = pos.pieces(Us, PAWN);
    Bitboard theirPawns = pos.pieces(Them, PAWN);
	Bitboard outKnights = pos.pieces(Us,KNIGHT);

    e->passedPawns[Us] = Bitboard();
    e->kingSquares[Us] = SQ_NONE;
    e->semiopenFiles[Us] = 0x1FF;//纵向通路
    e->pawnAttacks[Us] = (shift_bb<Right>(ourPawns) | shift_bb<Left>(ourPawns)|shift_bb<Up>(ourPawns))&PawnMask[Us];
    e->pawnsOnSquares[Us][BLACK] = popcount<CNT_90>(ourPawns & DarkSquares);
    e->pawnsOnSquares[Us][WHITE] = pos.count<PAWN>(Us) - e->pawnsOnSquares[Us][BLACK];

    // Loop through all pawns of the current color and score each pawn
    while ((s = *pl++) != SQ_NONE)
    {
        assert(pos.piece_on(s) == make_piece(Us, PAWN));

        f = file_of(s);//同列

        // This file cannot be semi-open
        e->semiopenFiles[Us] &= ~(1 << f);//有我方兵，不是file通路

        // Our rank plus previous one. Used for chain detection
        b = rank_bb(s) | rank_bb(s - pawn_push(Us));//同行和后面的位置

        // Flag the pawn as passed, isolated, doubled or member of a pawn
        // chain (but not the backward one).
        chain    =   (ourPawns&(~SquareBB[s]) ) & (adjacent_files_bb(f)|FileBB[f]) & b;//后面和左右的子//ourPawns   & adjacent_files_bb(f) & b;
        opposed  =   theirPawns & forward_bb(Us, s);//我方兵前面的敌方兵
		frontp   =   theirPawns & rank_bb(s + pawn_push(Us)) & (adjacent_files_bb(f)|FileBB[f]);//前面相邻行兵

		//别我方马腿的兵
		blockKnight = false;
		if(outKnights & FileBB[f] & rank_bb(s - pawn_push(Us)))
		{
			blockKnight = true;
		}

        //过河兵
		passedRiver = false;
		if(PassedRiverBB[Us] & s)
		{
			passedRiver = true;
            //连兵
			//进九宫的兵
			//底线兵
		}

        if (passedRiver)
            e->passedPawns[Us] |= s;

        // Score this pawn
		if(blockKnight)
			value -= BlockKnight[frontp][f];
		if(opposed)
			value += FrontNoPawn[f]; 
		if(chain)
			value += ConnectPawn[f];
		if(passedRiver && !(pos.attacks_from<PAWN>(s, Us) & theirPawns))
			value += PassedRiver[s];


		value += DistanceWithKing[std::max(file_distance(s, ksq), rank_distance(s, ksq))];		

    }

    return value;
  }

} // namespace

namespace Pawns {

/// probe() takes a position object as input, computes a Entry object, and returns
/// a pointer to it. The result is also stored in a hash table, so we don't have
/// to recompute everything when the same pawn structure occurs again.

Entry* probe(const Position& pos, Table& entries) {

  Key key = pos.pawn_key();
  Entry* e = entries[key];

  //temp disable
  if (e->key == key)
      return e;

  e->key = key;
  e->value = evaluate<WHITE>(pos, e) - evaluate<BLACK>(pos, e);
  return e;
}
} // namespace Pawns
