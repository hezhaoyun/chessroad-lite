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

#include <algorithm>
#include <cassert>
#include <cstring>
#include <iomanip>
#include <iostream>
#include <sstream>

#include "bitcount.h"
#include "movegen.h"
#include "notation.h"
#include "position.h"
#include "psqtab.h"
#include "rkiss.h"
#include "thread.h"
#include "tt.h"
#include "ucioption.h"

using std::string;
using std::cout;
using std::endl;

// NO_PIECE_TYPE, PAWN, BISHOP, ADVISOR, KNIGHT, CANNON, ROOK, KING,
//static const string PieceToChar(" PNCRBAK  pncrbak");
static const string PieceToChar(" PBANCRK pbancrk");

CACHE_LINE_ALIGNMENT

Score psq[COLOR_NB][PIECE_TYPE_NB][SQUARE_NB];
Value PieceValue[PHASE_NB][PIECE_NB] = {
{ VALUE_ZERO, PawnValueMg, BishopValueMg, AdvisorValueMg, KnightValueMg, CannonValueMg, RookValueMg},
{ VALUE_ZERO, PawnValueEg, BishopValueEg, AdvisorValueEg, KnightValueEg, CannonValueEg, RookValueEg} };

namespace Postion{

	void init_psq_value(){

		PieceValue[MG][PAWN] = (Value)(int)Options["PawnValueMg"];
		PieceValue[EG][PAWN] = (Value)(int)Options["PawnValueEg"];

		PieceValue[MG][BISHOP] = (Value)(int)Options["BishopValueMg"];
		PieceValue[EG][BISHOP] = (Value)(int)Options["BishopValueEg"];

		PieceValue[MG][ADVISOR] = (Value)(int)Options["AdvisorValueMg"];
		PieceValue[EG][ADVISOR] = (Value)(int)Options["AdvisorValueEg"];

		PieceValue[MG][KNIGHT] = (Value)(int)Options["KnightValueMg"];
		PieceValue[EG][KNIGHT] = (Value)(int)Options["KnightValueEg"];

		PieceValue[MG][CANNON] = (Value)(int)Options["CannonValueMg"];
		PieceValue[EG][CANNON] = (Value)(int)Options["CannonValueEg"];

		PieceValue[MG][ROOK] = (Value)(int)Options["RookValueMg"];
		PieceValue[EG][ROOK] = (Value)(int)Options["RookValueEg"];


		//for (PieceType pt = PAWN; pt <= KING; ++pt)
		//{
		//	for (Square sq = SQ_A0; sq < SQUARE_NB; ++sq)
		//	{

		//		char buf[256] = {0};

		//		sprintf(buf, "PSQT_MG[%d][%d]",pt, sq);
		//		int mg = Options[buf];

		//		sprintf(buf, "PSQT_EG[%d][%d]",pt, sq);
		//           int eg = Options[buf];

		//		PSQT[pt][sq] = make_score(mg, eg);
		//	}

		//}


		for (PieceType pt = PAWN; pt <= KING; ++pt)
		{
			PieceValue[MG][make_piece(BLACK, pt)] = PieceValue[MG][pt];
			PieceValue[EG][make_piece(BLACK, pt)] = PieceValue[EG][pt];

			Score v = make_score(PieceValue[MG][pt], PieceValue[EG][pt]);

			for (Square s = SQ_A0; s <= SQ_I9; ++s)
			{
				psq[WHITE][pt][ s] =  (v + PSQT[pt][s]);
				psq[BLACK][pt][~s] = -(v + PSQT[pt][s]);
			}
		}

	}
}


namespace Zobrist {

  Key psq[COLOR_NB][PIECE_TYPE_NB][SQUARE_NB];

  Key side;
  Key exclusion;
}

Key Position::exclusion_key() const { return st->key ^ Zobrist::exclusion;}

namespace {

// min_attacker() is an helper function used by see() to locate the least
// valuable attacker for the side to move, remove the attacker we just found
// from the bitboards and scan for new X-ray attacks behind it.

template<int Pt> FORCE_INLINE
PieceType min_attacker(const Bitboard* bb, const Square& to, const Bitboard& stmAttackers,
                       Bitboard& occ,Bitboard& occl90, Bitboard& attackers) {

  Bitboard b = stmAttackers & bb[Pt];
  if (!b)
      return min_attacker<Pt+1>(bb, to, stmAttackers, occ,occl90, attackers);

  occl90 ^= square_rotate_l90_bb(lsb(b));
  occ    ^= b & ~(b.operator -(1));

  //该函数仅对slider类型的piece计算
  //炮，车和兵是该种类型
  //PAWN应该是最先产生的，在后面的&之后，PAWN应该不会再有了?
  if(Pt == PAWN || Pt == ROOK){
	  attackers |= rook_attacks_bb(to, occ, occl90) & bb[ROOK];
	  attackers |= cannon_control_bb(to, occ, occl90) & bb[CANNON];
  }

  if(Pt == CANNON)
     attackers |= cannon_control_bb(to, occ, occl90) & bb[CANNON];

  attackers &= occ; // After X-ray that may add already processed pieces
  return (PieceType)Pt;
}

template<> FORCE_INLINE
PieceType min_attacker<KING>(const Bitboard*, const Square&, const Bitboard&, Bitboard&,Bitboard&, Bitboard&) {
  return KING; // No need to update bitboards, it is the last cycle
}

} // namespace


/// CheckInfo c'tor

CheckInfo::CheckInfo(const Position& pos) {

  Color them = ~pos.side_to_move();
  ksq = pos.king_square(them);

  pinned = pos.pinned_pieces();
  dcCandidates = pos.discovered_check_candidates();
  forbid = pos.cannon_forbid_bb(them);

  //checkSq是那些可以将军的位置,这些位置可能有子，也可能没子；
  //用于判断某个move是否将军
  //在gen quiet check move 可提高速度

  checkSq[PAWN]   = pos.attacks_from_pawn_nomask(ksq, them); 
  checkSq[KNIGHT] = knight_attacks_to_bb(ksq,pos.occupied);//knight_attackers_to_bb(ksq, pos.pieces(KNIGHT), pos.occupied);较慢
  checkSq[CANNON] = pos.attacks_from<CANNON>(ksq);//要注意跑沿着king方向移动,这里只能这样，要在使用的地方判断，比如：c--b-k**b,*处可能认为是避免将军的to位置

  checkSq[ROOK]   = pos.attacks_from<ROOK>(ksq);//不会将军，可当炮架或rook的block，gen quiet check特别处理
  
  checkSq[KING]   = Bitboard();
  checkSq[BISHOP] = Bitboard();
  checkSq[ADVISOR]= Bitboard();
}


/// Position::init() initializes at startup the various arrays used to compute
/// hash keys and the piece square tables. The latter is a two-step operation:
/// First, the white halves of the tables are copied from PSQT[] tables. Second,
/// the black halves of the tables are initialized by flipping and changing the
/// sign of the white scores.

void Position::init() {

  RKISS rk;

  for (Color c = WHITE; c <= BLACK; ++c)
      for (PieceType pt = PAWN; pt <= KING; ++pt)
          for (Square s = SQ_A0; s <= SQ_I9; ++s)
              Zobrist::psq[c][pt][s] = rk.rand<Key>();

  Zobrist::side = rk.rand<Key>();
  Zobrist::exclusion  = rk.rand<Key>();

  for (PieceType pt = PAWN; pt <= KING; ++pt)
  {
      PieceValue[MG][make_piece(BLACK, pt)] = PieceValue[MG][pt];
      PieceValue[EG][make_piece(BLACK, pt)] = PieceValue[EG][pt];

      Score v = make_score(PieceValue[MG][pt], PieceValue[EG][pt]);

      for (Square s = SQ_A0; s <= SQ_I9; ++s)
      {
         psq[WHITE][pt][ s] =  (v + PSQT[pt][s]);
         psq[BLACK][pt][~s] = -(v + PSQT[pt][s]);
      }
  }
}


/// Position::operator=() creates a copy of 'pos'. We want the new born Position
/// object do not depend on any external data so we detach state pointer from
/// the source one.

Position& Position::operator=(const Position& pos) {

  std::memcpy(this, &pos, sizeof(Position));
  startState = *st;
  st = &startState;
  nodes = 0;

  assert(pos_is_ok());

  return *this;
}


/// Position::set() initializes the position object with the given FEN string.
/// This function is not very robust - make sure that input FENs are correct,
/// this is assumed to be the responsibility of the GUI.

void Position::set(const string& fenStr, bool isChess960, Thread* th) {
/*
   A FEN string defines a particular position using only the ASCII character set.

   A FEN string contains six fields separated by a space. The fields are:

   1) Piece placement (from white's perspective). Each rank is described, starting
      with rank 8 and ending with rank 1; within each rank, the contents of each
      square are described from file A through file H. Following the Standard
      Algebraic Notation (SAN), each piece is identified by a single letter taken
      from the standard English names. White pieces are designated using upper-case
      letters ("PNBRQK") while Black take lowercase ("pnbrqk"). Blank squares are
      noted using digits 1 through 8 (the number of blank squares), and "/"
      separates ranks.

   2) Active color. "w" means white moves next, "b" means black.

   3) Castling availability. If neither side can castle, this is "-". Otherwise,
      this has one or more letters: "K" (White can castle kingside), "Q" (White
      can castle queenside), "k" (Black can castle kingside), and/or "q" (Black
      can castle queenside).

   4) En passant target square (in algebraic notation). If there's no en passant
      target square, this is "-". If a pawn has just made a 2-square move, this
      is the position "behind" the pawn. This is recorded regardless of whether
      there is a pawn in position to make an en passant capture.

   5) Halfmove clock. This is the number of halfmoves since the last pawn advance
      or capture. This is used to determine if a draw can be claimed under the
      fifty-move rule.

   6) Fullmove number. The number of the full move. It starts at 1, and is
      incremented after Black's move.
*/

  char col, row, token;
  size_t p;
  Square sq = SQ_A9;//last rank,from left to right
  std::istringstream ss(fenStr);

  clear();
  ss >> std::noskipws;

  // 1. Piece placement
  while ((ss >> token) && !isspace(token))
  {
      if (isdigit(token))
          sq += Square(token - '0'); // Advance the given number of files

      else if (token == '/')
          sq -= Square(18);//9+9

      else if ((p = PieceToChar.find(token)) != string::npos)
      {
          put_piece(sq, color_of(Piece(p)), type_of(Piece(p)));
          ++sq;
      }
  }

  // 2. Active color
  ss >> token;
  sideToMove = (token == 'w' ? WHITE : BLACK);
  ss >> token;

  // 3. Castling availability. Compatible with 3 standards: Normal FEN standard,
  // Shredder-FEN that uses the letters of the columns on which the rooks began
  // the game instead of KQkq and also X-FEN standard that, in case of Chess960,
  // if an inner rook is associated with the castling right, the castling tag is
  // replaced by the file letter of the involved rook, as for the Shredder-FEN.
  while ((ss >> token) && !isspace(token))
  {

  }

  // 4. En passant square. Ignore if no pawn capture is possible
  if (   ((ss >> col) && (col >= 'a' && col <= 'h'))
      && ((ss >> row) && (row == '3' || row == '6')))
  {

  }

  // 5-6. Halfmove clock and fullmove number
  ss >> std::skipws >> st->rule50 >> gamePly;

  // Convert from fullmove starting from 1 to ply starting from 0,
  // handle also common incorrect FEN with fullmove = 0.
  gamePly = std::max(2 * (gamePly - 1), 0) + int(sideToMove == BLACK);

  st->key = compute_key();
  st->pawnKey = compute_pawn_key();
  st->materialKey = compute_material_key();
  st->psq = compute_psq_score();
  st->npMaterial[WHITE] = compute_non_pawn_material(WHITE);
  st->npMaterial[BLACK] = compute_non_pawn_material(BLACK);
  st->npAttackMaterial[WHITE] = compute_attack_material(WHITE);
  st->npAttackMaterial[BLACK] = compute_attack_material(BLACK);

  st->checkersBB = attackers_to(king_square(sideToMove)) & pieces(~sideToMove);
  
  thisThread = th;

  assert(pos_is_ok());
}


/// Position::fen() returns a FEN representation of the position. In case
/// of Chess960 the Shredder-FEN notation is used. Mainly a debugging function.

const string Position::fen() const {

  std::ostringstream ss;

  for (Rank rank = RANK_9; rank >= RANK_0; --rank)
  {
      for (File file = FILE_A; file <= FILE_I; ++file)
      {
          Square sq = file | rank;

          if (is_empty(sq))
          {
              int emptyCnt = 1;

              for ( ; file < FILE_I && is_empty(++sq); ++file)
                  emptyCnt++;

              ss << emptyCnt;
          }
          else
              ss << PieceToChar[piece_on(sq)];
      }

      if (rank > RANK_0)
          ss << '/';
  }

  ss << (sideToMove == WHITE ? " w " : " b ");

  //ss << (ep_square() == SQ_NONE ? " - " : " " + square_to_string(ep_square()) + " ")
  //    << st->rule50 << " " << 1 + (gamePly - int(sideToMove == BLACK)) / 2;
  ss << "-";
  ss << " ";
  ss << "-";
  ss << " ";
  ss << st->rule50 << " " << 1 + (gamePly - int(sideToMove == BLACK)) / 2;

  return ss.str();
}


/// Position::pretty() returns an ASCII representation of the position to be
/// printed to the standard output together with the move's san notation.

const string Position::pretty(Move move) const {

  string  boards = string("+---+---+---+---+---+---+---+---+\n")
	            + string("|   |   |   |   |   |   |   |   |\n")
	            + string("+---+---+---+---*---+---+---+---+\n")
				+ string("|   |   |   |   |   |   |   |   |\n")
                + string("+---+---+---+---+---+---+---+---+\n")
				+ string("|   |   |   |   |   |   |   |   |\n")
				+ string("*---+---*---+---*---+---*---+---*\n")
				+ string("|   |   |   |   |   |   |   |   |\n")
				+ string("+---+---+---+---+---+---+---+---+\n")
				+ string("|   |   |   |   |   |   |   |   |\n")
				+ string("+---+---+---+---+---+---+---+---+\n")
				+ string("|   |   |   |   |   |   |   |   |\n")
				+ string("*---+---*---+---*---+---*---+---*\n")
				+ string("|   |   |   |   |   |   |   |   |\n")
				+ string("+---+---+---+---+---+---+---+---+\n")
				+ string("|   |   |   |   |   |   |   |   |\n")
				+ string("+---+---+---+---*---+---+---+---+\n")
				+ string("|   |   |   |   |   |   |   |   |\n")
				+ string("+---+---+---+---+---+---+---+---+\n");


  string brd = boards;
  
  for (Bitboard b = pieces(); b; )
  {
      Square s = pop_lsb(&b);

	  int i = 646 - 34 * (rank_of(s)*2) - 34 + 4 * file_of(s);
	  int c = PieceToChar[piece_on(s)];
	 
      brd[i] = c;
  }

  std::ostringstream ss;

  ss<<"time:"<<clock()<<"\n";

  //if (move)
  //    ss << "\nMove: " << (sideToMove == BLACK ? ".." : "")
	 // << move_to_san(*const_cast<Position*>(this), move)<<std::endl;

  ss << brd << "\nFen: " << fen() << "\nKey: " << std::hex << std::uppercase
     << std::setfill('0') << std::setw(16) << st->key << "\nCheckers: ";

  for (Bitboard b = checkers(); b; )
      ss << square_to_string(pop_lsb(&b)) << " ";

  //ss << "\nLegal moves: ";
  //for (MoveList<LEGAL> it(*this); *it; ++it)
  //    ss << move_to_san(*const_cast<Position*>(this), *it) << " ";
 
  return ss.str();
}


/// Position:hidden_checkers() returns a bitboard of all pinned / discovery check
/// pieces, according to the call parameters. Pinned pieces protect our king,
/// discovery check pieces attack the enemy king.
/// cannon and king is special. 

Bitboard Position::hidden_checkers(Square ksq, Color c) const {

  Bitboard b, pinners, result;

  //// Pinners are sliders that give check when pinned piece is removed
   //rook于国际象棋相同
    pinners = (pieces( ROOK) & PseudoAttacks[ROOK][ksq]) & pieces(c);
	while (pinners)
	{
		b = between_bb(ksq, pop_lsb(&pinners)) & pieces();

		if (!more_than_one(b))
			result |= b & pieces(sideToMove);
	}

	//cannon
    pinners = (pieces( CANNON) & PseudoAttacks[ROOK][ksq]) & pieces(c);//用ROOK的PseudoAttacks，仅仅说明同行同列
	while (pinners)
	{
		b = between_bb(ksq, pop_lsb(&pinners)) & pieces();

		if (equal_to_two(b))
			result |= b & pieces(sideToMove);//中间有个子是sideToMove方的，该子移动后会将军
	}

	//knight
	//ksq在马脚，马腿是sideToMove方棋子，s处事c方的子

	pinners = pieces(c, KNIGHT) & pieces(c);
	while(pinners)
	{
		Square s = pop_lsb(&pinners);
		if(KnightStepTo[s][0] & ksq )
		{
			result |= KnightStepLeg[s][0] & pieces(sideToMove);
		}

		if(KnightStepTo[s][1] & ksq )
		{
			result |= KnightStepLeg[s][1] & pieces(sideToMove);
		}

		if(KnightStepTo[s][2] & ksq  )
		{
			result |= KnightStepLeg[s][2] & pieces(sideToMove);
		}

		if(KnightStepTo[s][3] & ksq  )
		{
			result |= KnightStepLeg[s][3] & pieces(sideToMove);
		}
	}

	//king
	//不会king将king,
	//此处的pin可作为候选将军子，所以此处不能处理对脸情况


	//马，炮，兵等需根据应用来判断
	//兵可能不需要，因兵不可能牵制
	//将于帅的牵制可能要考虑
	//炮的牵制可能要考虑

    //总结：该函数的作用是寻找隐藏的将军子，可能的子是rook，cannon，knight

  return result;
}


/// Position::attackers_to() computes a bitboard of all pieces which attack a
/// given square. Slider attacks use occ bitboard as occupancy.
//只能用参数传进来的occ，见see;函数作用是寻找那些可以攻击到s位置的子
Bitboard Position::attackers_to(Square s, Bitboard occ, Bitboard occl90) const {

  return
		  (attacks_from_pawn_nomask(s, BLACK) & pieces(WHITE, PAWN))//有方向问题，所以用nomask的
		| (attacks_from_pawn_nomask(s, WHITE) & pieces(BLACK, PAWN))
		| (knight_attackers_to_bb(s, pieces(KNIGHT), occ))  //| (knight_attacks_bb(s, occ) & pieces(KNIGHT)) //这里有问题，a可以攻击b，不意味着b攻击a位置 
		| (rook_attacks_bb(s,occ,occl90)& pieces(ROOK))                
		| (cannon_control_bb(s, occ,occl90) & pieces(CANNON))             
		| (bishop_attacks_bb(s,occ)   & pieces(BISHOP))
		| (attacks_from<ADVISOR>(s,BLACK) & pieces(ADVISOR))
		| (attacks_from<ADVISOR>(s,WHITE) & pieces(ADVISOR))
		| (attacks_from<KING>(s, BLACK) & pieces(KING))
        | (attacks_from<KING>(s, WHITE) & pieces(KING));
}


/// Position::attacks_from() computes a bitboard of all attacks of a given piece
/// put in a given square. Slider attacks use occ bitboard as occupancy.

Bitboard Position::attacks_from(Piece p, Square s, Bitboard occ, Bitboard occl90) {

  assert(is_ok(s));
  switch (type_of(p))
  {
  case ROOK  : return rook_attacks_bb(s, occ, occl90);
  case CANNON: return cannon_control_bb(s,occ,occl90);
  case KNIGHT: return knight_attacks_bb(s,occ);
  case BISHOP: return bishop_attacks_bb(s,occ);
  case ADVISOR:return StepAttacksBB[p][s];
  case KING:   return StepAttacksBB[p][s];
  case PAWN:   return StepAttacksBB[p][s]; 
  default    : return StepAttacksBB[p][s];//这里p类型是对的
  }
}


/// Position::pl_move_is_legal() tests whether a pseudo-legal move is legal

bool Position::pl_move_is_legal(Move m, Bitboard pinned) const {


  assert(is_ok(m));
  assert(pinned == pinned_pieces());

   return move_is_legal(*this, m);
}


/// Position::is_pseudo_legal() takes a random move and tests whether the move
/// is pseudo legal. It is used to validate moves from TT that can be corrupted
/// due to SMP concurrent access or hash position key aliasing.

bool Position::is_pseudo_legal(const Move m) const {

  Color us = sideToMove;
  Square from = from_sq(m);
  Square to = to_sq(m);

  if(from >= SQUARE_NB || to >= SQUARE_NB)
	  return false;//crash mp

  Piece pc = piece_moved(m);

  //if(MoveList<LEGAL>(*this).contains(m))
	 // return true;
  //else 
	 // return false;


  // If the from square is not occupied by a piece belonging to the side to
  // move, the move is obviously not legal.
  if (pc == NO_PIECE || color_of(pc) != us)
      return false;

  // The destination square cannot be occupied by a friendly piece
  if (pieces(us) & to)
      return false;


  //炮要特别处理，attacks_from计算的事cannon可以控制的区域
  switch (type_of(pc))
  {
  case ROOK  : 
	  {
		 if( !(rook_attacks_bb(from, occupied, occupied_rl90)&to) )
			 return false;
		 break;
	  }
  case CANNON:
	  {
		  if(type_of(piece_on(to)) == NO_PIECE_TYPE)
		  {
			  if( !(rook_attacks_bb(from, occupied, occupied_rl90)&to))			 
			  {
				  return false;
			  }
		  }
		  else
		  {
			  if( !(cannon_control_bb(from,occupied,occupied_rl90) & to))
			  //if( !(between_bb(from, to) & pieces()) )//不能用这种方式，因为中间可能有多个子
			  {
				  return false;
			  }
		  }
		  break;
	  }
  case KNIGHT:
	  {
		  if( !(knight_attacks_bb(from,occupied)&to))
			 return false;

		  break;
	  }
  case BISHOP: 
	  {
		  if(!(bishop_attacks_bb(from,occupied)&to))
			  return false;

		  break;
	  }
  case ADVISOR:
	  {
		  if( !(StepAttacksBB[pc][from]&to))
			  return false;
		  break;
	  }
  case KING: 
	  {
		  if( !(StepAttacksBB[pc][from]&to))
			  return false;
		  break;
	  }
  case PAWN: 
	  {
		  if( !(StepAttacksBB[pc][from]&to))
			  return false;
		  break;
	  } 
  default    :
	  {
		  assert(false);
		  break;
	  }
  }

  return move_is_legal(*this, m);
}


/// Position::move_gives_check() tests whether a pseudo-legal move gives a check

bool Position::move_gives_check(Move m, const CheckInfo& ci) const {

  assert(is_ok(m));
  assert(ci.dcCandidates == discovered_check_candidates());
  assert(color_of(piece_moved(m)) == sideToMove);

  Square from = from_sq(m);
  Square to = to_sq(m);
  PieceType pt = type_of(piece_on(from));

  // Direct check ?
  if ( pt != CANNON && (ci.checkSq[pt] & to))
	  return true;
  else if(pt == CANNON)
  {
	  //from不与king同行同列时成立
     if( !(PseudoAttacks[ROOK][from] & king_square(~sideToMove)) )
	 {
		 if((ci.checkSq[pt] & to))
		    return true;
	 }
  }

  Bitboard pawns   = pieces(sideToMove, PAWN);
  Bitboard knights = pieces(sideToMove, KNIGHT);
  Bitboard cannons = pieces(sideToMove, CANNON);
  Bitboard rooks = pieces(sideToMove, ROOK);
  if(pawns & from)
  {
	  pawns ^= from;
	  pawns ^= to;
  }
  else if(knights & from)
  {
	  knights ^= from;
	  knights ^= to;
  }
  else if(cannons & from)
  {
	  cannons ^= from;
	  cannons ^= to;
  }
  else if(rooks & from)
  {
	  rooks ^= from;
	  rooks ^= to;
  }

  Bitboard  occ    = occupied;
  Bitboard  occl90 = occupied_rl90;

  occl90 ^= square_rotate_l90_bb(from);
  occ    ^= from;

  if(type_of(piece_on(to)) == NO_PIECE_TYPE)
  {
	  occl90 ^= square_rotate_l90_bb(to);
	  occ    ^= to;
  }

  Square s = king_square(~sideToMove); 
  
  //把可能最大的放在前面
  if(cannon_control_bb(s, occ,occl90) & cannons)
	  return true;
  if(rook_attacks_bb(s,occ,occl90)& rooks)
	  return true;
  if(knight_attackers_to_bb(s, knights, occ))
	  return true;
  if((attacks_from_pawn_nomask(s, ~sideToMove) & pawns) )
	  return true;

  return false; 
}

bool  Position::is_in_check()const{

	Color us = side_to_move();
	Square ksq = king_square(sideToMove);

	Bitboard pawns   = pieces(~us, PAWN);
	Bitboard knights = pieces(~us, KNIGHT);
	Bitboard cannons = pieces(~us, CANNON);
	Bitboard rooks = pieces(~us, ROOK);

	if((PseudoAttacks[ROOK][ksq]& cannons) &&(cannon_control_bb(ksq, occupied,occupied_rl90) & cannons)) return true;
	if((PseudoAttacks[ROOK][ksq]& rooks) && (rook_attacks_bb(ksq,occupied,occupied_rl90)& rooks) ) return true;
	if( knight_attackers_to_bb(ksq, knights, occupied) ) return true;
	if( attacks_from_pawn_nomask(ksq, us) & pawns ) return true;

	return false;
}

int  Position::is_repeat()const
{	
	bool oppcheck = true;
	bool mecheck = true;
	int  checktime = 0;

	StateInfo* stp = st;
	for (int i = 2, e = std::min(st->rule50, st->pliesFromNull); i <= e; i += 2)
	{
		StateInfo* stopp = stp->previous;
		StateInfo* stme = stp;

		stp = stp->previous->previous;

		if (oppcheck && !stme->checkersBB) oppcheck = false;
		if (mecheck && !stopp->checkersBB)  mecheck = false;

		if (stp->key == st->key)  //repetition
		{
			checktime++;

			if (checktime >= 1)
			{
				return REPEATE_TRUE + (mecheck ? REPEATE_ME_CHECK : REPEATE_NONE) + (oppcheck ? REPEATE_OPP_CHECK : REPEATE_NONE);
			}
		}
	}

	return REPEATE_NONE;
}

/// Position::do_move() makes a move, and saves all information necessary
/// to a StateInfo object. The move is assumed to be legal. Pseudo-legal
/// moves should be filtered out before this function is called.

void Position::do_move(Move m, StateInfo& newSt) {

  CheckInfo ci(*this);
  do_move(m, newSt, ci, move_gives_check(m, ci));
}

void Position::do_move(Move m, StateInfo& newSt, const CheckInfo& ci, bool moveIsCheck) {

  assert(is_ok(m));
  assert(&newSt != st);

  nodes++;
  Key k = st->key;

  // Copy some fields of old state to our new StateInfo object except the ones
  // which are going to be recalculated from scratch anyway, then switch our state
  // pointer to point to the new, ready to be updated, state.
  std::memcpy(&newSt, st, StateCopySize64 * sizeof(uint64_t));

  newSt.previous = st;
  st = &newSt;

  // Update side to move
  k ^= Zobrist::side;

  // Increment ply counters.In particular rule50 will be later reset it to zero
  // in case of a capture or a pawn move.
  gamePly++;
  st->rule50++;
  st->pliesFromNull++;

  Color us = sideToMove;
  Color them = ~us;
  Square from = from_sq(m);
  Square to = to_sq(m);
  Piece pc = piece_on(from);
  PieceType pt = type_of(pc);
  
  PieceType capture = type_of(piece_on(to));

  assert(color_of(pc) == us);
  if( !(piece_on(to) == NO_PIECE || color_of(piece_on(to)) == them))
      std::cout<<fen().c_str()<<endl;
  assert(piece_on(to) == NO_PIECE || color_of(piece_on(to)) == them );
  assert(capture != KING);


  if (capture)
  {
      Square capsq = to;

      // If the captured piece is a pawn, update pawn hash key, otherwise
      // update non-pawn material.
      if (capture == PAWN)
      {
          st->pawnKey ^= Zobrist::psq[them][PAWN][capsq];
      }
      else
	  {
		  st->npMaterial[them] -= PieceValue[MG][capture];

		  if (capture == ROOK || capture == CANNON || capture == KNIGHT)
		  {
			   st->npAttackMaterial[them] -= PieceValue[MG][capture];
		  }
	     
	  }

      // Update board and piece lists
      remove_piece(capsq, them, capture);

      // Update material hash key and prefetch access to materialTable
      k ^= Zobrist::psq[them][capture][capsq];
      st->materialKey ^= Zobrist::psq[them][capture][pieceCount[them][capture]];
	  //暂时去除
      prefetch((char*)thisThread->materialTable[st->materialKey]);

      // Update incremental scores
      st->psq -= psq[them][capture][capsq];

      // Reset rule 50 counter
      st->rule50 = 0;
  }

  // Update hash key
  k ^= Zobrist::psq[us][pt][from] ^ Zobrist::psq[us][pt][to];

  // Prefetch TT access as soon as we know the new hash key
  //暂时去除
  prefetch((char*)TT.first_entry(k));

  // Move the piece. The tricky Chess960 castle is handled earlier
  move_piece(from, to, us, pt);

  // If the moving piece is a pawn do some special extra work
  if (pt == PAWN)
  {
      // Update pawn hash key and prefetch access to pawnsTable
      st->pawnKey ^= Zobrist::psq[us][PAWN][from] ^ Zobrist::psq[us][PAWN][to];
	  //暂时去除
      prefetch((char*)thisThread->pawnsTable[st->pawnKey]);

      // Reset rule 50 draw counter
      //st->rule50 = 0;
  }

  // Update incremental scores
  st->psq += psq[us][pt][to] - psq[us][pt][from];

  // Set capture piece
  st->capturedType = capture;

  // Update the key with the final value
  st->key = k;

  // Update checkers bitboard, piece must be already moved
  st->checkersBB = attackers_to(king_square(them)) & pieces(us);

  sideToMove = ~sideToMove;

  assert(pos_is_ok());
 
}


/// Position::undo_move() unmakes a move. When it returns, the position should
/// be restored to exactly the same state as before the move was made.

void Position::undo_move(Move m) {

  assert(is_ok(m));

  sideToMove = ~sideToMove;

  Color us = sideToMove;
  Color them = ~us;
  Square from = from_sq(m);
  Square to = to_sq(m);
  PieceType pt = type_of(piece_on(to));
  PieceType capture = st->capturedType;

  assert(capture != KING);

  move_piece(to, from, us, pt); // Put the piece back at the source square

  if (capture)
  {
      Square capsq = to;

      put_piece(capsq, them, capture); // Restore the captured piece
  }

  // Finally point our state pointer back to the previous state
  st = st->previous;
  gamePly--;

  assert(pos_is_ok());
}

/// Position::do(undo)_null_move() is used to do(undo) a "null move": It flips
/// the side to move without executing any move on the board.

void Position::do_null_move(StateInfo& newSt) {

  assert(!checkers());

  std::memcpy(&newSt, st, sizeof(StateInfo)); // Fully copy here

  newSt.previous = st;
  st = &newSt;

  st->key ^= Zobrist::side;
  //暂时去除
  prefetch((char*)TT.first_entry(st->key));

  st->rule50++;
  st->pliesFromNull = 0;

  sideToMove = ~sideToMove;

  assert(pos_is_ok());
}

void Position::undo_null_move() {

  assert(!checkers());

  st = st->previous;
  sideToMove = ~sideToMove;
}


/// Position::see() is a static exchange evaluator: It tries to estimate the
/// material gain or loss resulting from a move. Parameter 'asymmThreshold' takes
/// tempi into account. If the side who initiated the capturing sequence does the
/// last capture, he loses a tempo and if the result is below 'asymmThreshold'
/// the capturing sequence is considered bad.

int Position::see_sign(Move m) const {

  assert(is_ok(m));

  // Early return if SEE cannot be negative because captured piece value
  // is not less then capturing one. Note that king moves always return
  // here because king midgame value is set to 0.
  if (PieceValue[MG][piece_moved(m)] <= PieceValue[MG][piece_on(to_sq(m))])
      return 1;

  return see(m);
}

int Position::see(Move m, int asymmThreshold) const {

  Square from, to;
  Bitboard occ,occl90, attackers, stmAttackers;
  int swapList[32], slIndex = 1;
  PieceType captured;
  Color stm;

  assert(is_ok(m));

  from = from_sq(m);
  to = to_sq(m);
  swapList[0] = PieceValue[MG][type_of(piece_on(to))];
  stm = color_of(piece_on(from));
  occ = pieces() ^ from;//去除from
  occl90 = occupied_rl90 ^ square_rotate_l90_bb(from);


  // Find all attackers to the destination square, with the moving piece
  // removed, but possibly an X-ray attacker added behind it.
  attackers = attackers_to(to, occ, occl90) & occ;//所有的attacker,注意：这里假设to位置的子类型，结果是所有攻击to位置的子，包括本方，对方


  // If the opponent has no attackers we are finished
  stm = ~stm;
  stmAttackers = attackers & pieces(stm);//相与之后，就是对方攻击to位置的子
  if (!stmAttackers)
      return swapList[0];

  // The destination square is defended, which makes things rather more
  // difficult to compute. We proceed by building up a "swap list" containing
  // the material gain or loss at each stop in a sequence of captures to the
  // destination square, where the sides alternately capture, and always
  // capture with the least valuable piece. After each capture, we look for
  // new X-ray attacks from behind the capturing piece.
  captured = type_of(piece_on(from));//from的子吃到to位置后，变为对方要吃得子，所里这里相当于交换side

  do {
      assert(slIndex < 32);

      // Add the new entry to the swap list
      swapList[slIndex] = -swapList[slIndex - 1] + PieceValue[MG][captured];//相当于交换手，相反方向加子的分值
      slIndex++;

      // Locate and remove the next least valuable attacker
	  //这是一个递归模板，PAWN~KING
      captured = min_attacker<PAWN>(byTypeBB, to, stmAttackers, occ, occl90, attackers);//只找slidder类型，1142 line 中已找到所有一步吃子，这里只能是rook， cannon之类
      stm = ~stm;
      stmAttackers = attackers & pieces(stm);//交换side

      // Stop before processing a king capture
      if (captured == KING && stmAttackers)
      {
          swapList[slIndex++] = RookValueMg * 16;//替换了原QeenValueMg
          break;
      }

  } while (stmAttackers);

  // If we are doing asymmetric SEE evaluation and the same side does the first
  // and the last capture, he loses a tempo and gain must be at least worth
  // 'asymmThreshold', otherwise we replace the score with a very low value,
  // before negamaxing.
  if (asymmThreshold)
      for (int i = 0; i < slIndex; i += 2)
          if (swapList[i] < asymmThreshold)
              swapList[i] = - RookValueMg * 16;//QeenValueMg

  // Having built the swap list, we negamax through it to find the best
  // achievable score from the point of view of the side to move.
  while (--slIndex)
      swapList[slIndex-1] = std::min(-swapList[slIndex], swapList[slIndex-1]);//这个过程相当于negamax

  return swapList[0];
}


/// Position::clear() erases the position object to a pristine state, with an
/// empty board, white to move, and no castling rights.

void Position::clear() {

  std::memset(this, 0, sizeof(Position));
 
  st = &startState;

  for (int i = 0; i < PIECE_TYPE_NB; ++i)
      for (int j = 0; j < 16; j++)
          pieceList[WHITE][i][j] = pieceList[BLACK][i][j] = SQ_NONE;
}


/// Position::compute_key() computes the hash key of the position. The hash
/// key is usually updated incrementally as moves are made and unmade, the
/// compute_key() function is only used when a new position is set up, and
/// to verify the correctness of the hash key when running in debug mode.

Key Position::compute_key() const {

  Key k = 0;

  for (Bitboard b = pieces(); b; )
  {
      Square s = pop_lsb(&b);
      k ^= Zobrist::psq[color_of(piece_on(s))][type_of(piece_on(s))][s];
  }


  if (sideToMove == BLACK)
      k ^= Zobrist::side;

  return k;
}


/// Position::compute_pawn_key() computes the hash key of the position. The
/// hash key is usually updated incrementally as moves are made and unmade,
/// the compute_pawn_key() function is only used when a new position is set
/// up, and to verify the correctness of the pawn hash key when running in
/// debug mode.

Key Position::compute_pawn_key() const {

  Key k = 0;

  for (Bitboard b = pieces(PAWN); b; )
  {
      Square s = pop_lsb(&b);
      k ^= Zobrist::psq[color_of(piece_on(s))][PAWN][s];
  }

  return k;
}


/// Position::compute_material_key() computes the hash key of the position.
/// The hash key is usually updated incrementally as moves are made and unmade,
/// the compute_material_key() function is only used when a new position is set
/// up, and to verify the correctness of the material hash key when running in
/// debug mode.

Key Position::compute_material_key() const {

  Key k = 0;

  for (Color c = WHITE; c <= BLACK; ++c)
      for (PieceType pt = PAWN; pt <= ROOK; ++pt)
          for (int cnt = 0; cnt < pieceCount[c][pt]; ++cnt)
              k ^= Zobrist::psq[c][pt][cnt];

  return k;
}


/// Position::compute_psq_score() computes the incremental scores for the middle
/// game and the endgame. These functions are used to initialize the incremental
/// scores when a new position is set up, and to verify that the scores are correctly
/// updated by do_move and undo_move when the program is running in debug mode.

Score Position::compute_psq_score() const {

  Score score = SCORE_ZERO;

  for (Bitboard b = pieces(); b; )
  {
      Square s = pop_lsb(&b);
      Piece pc = piece_on(s);
      score += psq[color_of(pc)][type_of(pc)][s];
  }

  return score;
}


/// Position::compute_non_pawn_material() computes the total non-pawn middle
/// game material value for the given side. Material values are updated
/// incrementally during the search, this function is only used while
/// initializing a new Position object.

Value Position::compute_non_pawn_material(Color c) const {

  Value value = VALUE_ZERO;

  for (PieceType pt = BISHOP; pt <= ROOK; ++pt)
      value += pieceCount[c][pt] * PieceValue[MG][pt];

  return value;
}

Value Position::compute_attack_material(Color c) const {

	Value value = VALUE_ZERO;

	for (PieceType pt = KNIGHT; pt <= ROOK; ++pt)
		value += pieceCount[c][pt] * PieceValue[MG][pt];	

	return value;
}


/// Position::is_draw() tests whether the position is drawn by material,
/// repetition, or the 50 moves rule. It does not detect stalemates, this
/// must be done by the search.
bool Position::is_draw() const {

  // Draw by material?

	if( !pieces(PAWN) && !pieces(CANNON) && !pieces(KNIGHT) && !pieces(ROOK))
		return true;

  // Draw by the 50 moves rule?
  if (st->rule50 > 99 && (!checkers() || MoveList<LEGAL>(*this).size()))
      return true;

  int i = 4, e = std::min(st->rule50, st->pliesFromNull);
  int n = 0;

  if (i <= e)
  {
      StateInfo* stp = st->previous->previous;

      do {
          stp = stp->previous->previous;

          if (stp->key == st->key)
		  {
			  return true; // Draw after first repetition
		  }

          i += 2;

      } while (i <= e);
  }

  return false;
}


/// Position::flip() flips position with the white and black sides reversed. This
/// is only useful for debugging especially for finding evaluation symmetry bugs.

static char toggle_case(char c) {
  return char(islower(c) ? toupper(c) : tolower(c));
}

void Position::flip() {

  string f, token;
  std::stringstream ss(fen());

  for (Rank rank = RANK_9; rank >= RANK_0; --rank) // Piece placement
  {
      std::getline(ss, token, rank > RANK_1 ? '/' : ' ');
      f.insert(0, token + (f.empty() ? " " : "/"));
  }

  ss >> token; // Active color
  f += (token == "w" ? "B " : "W "); // Will be lowercased later

  ss >> token; // Castling availability
  f += token + " ";

  std::transform(f.begin(), f.end(), f.begin(), toggle_case);

  ss >> token; // En passant square
  f += "-";

  std::getline(ss, token); // Half and full moves
  f += token;

  set(f, is_chess960(), this_thread());

  assert(pos_is_ok());
}


/// Position::pos_is_ok() performs some consitency checks for the position object.
/// This is meant to be helpful when debugging.

bool Position::pos_is_ok(int* failedStep) const {

  int dummy, *step = failedStep ? failedStep : &dummy;

  // What features of the position should be verified?
  const bool all = true;

  const bool debugBitboards       = all || false;
  const bool debugKingCount       = all || false;
  const bool debugKingCapture     = all || false;
  const bool debugCheckerCount    = all || false;
  const bool debugKey             = all || false;
  const bool debugMaterialKey     = all || false;
  const bool debugPawnKey         = all || false;
  const bool debugIncrementalEval = all || false;
  const bool debugNonPawnMaterial = all || false;
  const bool debugPieceCounts     = all || false;
  const bool debugPieceList       = all || false;
  const bool debugKingFace        = all || false;

  *step = 1;

  if (sideToMove != WHITE && sideToMove != BLACK)
      return false;

  if ((*step)++, piece_on(king_square(WHITE)) != W_KING)
      return false;

  if ((*step)++, piece_on(king_square(BLACK)) != B_KING)
      return false;

  if ((*step)++, debugKingCount)
  {
      int kingCount[COLOR_NB] = {};

      for (Square s = SQ_A0; s <= SQ_I9; ++s)
          if (type_of(piece_on(s)) == KING)
              kingCount[color_of(piece_on(s))]++;

      if (kingCount[0] != 1 || kingCount[1] != 1)
          return false;
  }

  if ((*step)++, debugKingCapture)
      if (attackers_to(king_square(~sideToMove)) & pieces(sideToMove))
          return false;

  if ((*step)++, debugBitboards)
  {
      // The intersection of the white and black pieces must be empty
      if (pieces(WHITE) & pieces(BLACK))
          return false;

      // The union of the white and black pieces must be equal to all
      // occupied squares
      if ((pieces(WHITE) | pieces(BLACK))  != pieces())
          return false;

      // Separate piece type bitboards must have empty intersections
      for (PieceType p1 = PAWN; p1 <= KING; ++p1)
          for (PieceType p2 = PAWN; p2 <= KING; ++p2)
              if (p1 != p2 && (pieces(p1) & pieces(p2)))
                  return false;
  }

  if ((*step)++, debugKey && st->key != compute_key())
      return false;

  if ((*step)++, debugPawnKey && st->pawnKey != compute_pawn_key())
      return false;

  if ((*step)++, debugMaterialKey && st->materialKey != compute_material_key())
      return false;

  if ((*step)++, debugIncrementalEval && st->psq != compute_psq_score())
      return false;

  if ((*step)++, debugNonPawnMaterial)
      if (   st->npMaterial[WHITE] != compute_non_pawn_material(WHITE)
          || st->npMaterial[BLACK] != compute_non_pawn_material(BLACK))
          return false;

  if ((*step)++, debugPieceCounts)
      for (Color c = WHITE; c <= BLACK; ++c)
          for (PieceType pt = PAWN; pt <= KING; ++pt)
              if (pieceCount[c][pt] != popcount<CNT_90>(pieces(c, pt)))
                  return false;

  if ((*step)++, debugPieceList)
      for (Color c = WHITE; c <= BLACK; ++c)
          for (PieceType pt = PAWN; pt <= KING; ++pt)
              for (int i = 0; i < pieceCount[c][pt];  ++i)
                  if (   board[pieceList[c][pt][i]] != make_piece(c, pt)
                      || index[pieceList[c][pt][i]] != i)
                      return false;


   if ((*step)++, debugKingFace && (PseudoAttacks[ROOK][king_square(WHITE)]&king_square(BLACK)) &&!(between_bb(king_square(WHITE) , king_square(BLACK))& pieces()))
	   return false;

  *step = 0;
  return true;
}

void test_position()
{
    //const char *const StartFen = "Cnbakabn1/9/1c2r4/p1p3p1p/9/6c2/P1P1P3P/4C4/9/RNBAKABNR b - - 0 7";//"rnC1kabnr/4a4/7c1/p1p3p1p/4p4/9/P1P1P1P1P/1C7/9/RcBAKABNR w - - 0 4";//"rnbakabnr/9/4c4/p3p1C1p/9/9/P1P1c1P1P/1C7/9/RNBAKABNR b - - 0 4";//"rnbakabnr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RNBAKABNR w - - 0 1";
	//const char *const StartFen = "Cnbakabn1/9/1c7/p1p3p1p/4c4/9/P1P1r3P/4C4/9/RNBAKABNR b - - 0 7";
	//const char *const StartFen = "3R5/4P4/4k4/9/8P/P8/4P4/9/9/3AKA3 w - - 0 43";//"5R3/4P4/b3k4/9/P1b6/8P/4P4/9/9/3AKA3 b - - 0 39";
	const char *const StartFen = "3ak1b2/4a4/b5n1c/p5C1p/4p1P2/1R7/P4r2P/4B1NrC/2nRA4/4KAB2 w - - 0 21";
	Position position;

    position.set(StartFen, false, NULL);

	std::cout<<position.pretty(MOVE_NULL).c_str()<<endl;//move:a3a4

	//CheckInfo ci(position);
	//position.move_gives_check(make_move(SQ_D9,SQ_C9),ci);
	
	//std::cout<<position.fen().c_str()<<endl;
    //std::cout<<position.see(Move(0x1b24))<<endl;
	{
		//for (MoveList<LEGAL> it(position); *it; ++it)
		//{
		//	StateInfo st;
		//	position.do_move(*it, st);
		//	std::cout<<position.pretty(Move(0x1b24)).c_str()<<endl;
		//	position.undo_move(*it);
		//}
	}

	//Bitboards::print(position.pieces());	

	//for (Color c = WHITE; c <= BLACK; ++c)
	//	for (PieceType pt = PAWN; pt <= KING; ++pt)
	//	{
	//           Bitboards::print(position.pieces( c, pt));
	//	}
    //PAWN, BISHOP, ADVISOR, KNIGHT, CANNON, ROOK, KING
	//std::cout<<position.count<PAWN>(WHITE)<<endl;
	//std::cout<<position.count<BISHOP>(WHITE)<<endl;
	//std::cout<<position.count<ADVISOR>(WHITE)<<endl;
	//std::cout<<position.count<KNIGHT>(WHITE)<<endl;
	//std::cout<<position.count<CANNON>(WHITE)<<endl;
	//std::cout<<position.count<ROOK>(WHITE)<<endl;
	//std::cout<<position.count<KING>(WHITE)<<endl;


	 //Bitboards::print(position.attacks_from<ROOK>(SQ_A0));
	 //Bitboards::print(position.attacks_from<CANNON>(SQ_A0));
	 //Bitboards::print(position.attacks_from<KNIGHT>(SQ_A0));
	 //Bitboards::print(position.attacks_from<ADVISOR>(SQ_E1,WHITE));
	 //Bitboards::print(position.attacks_from<BISHOP>(SQ_E2,WHITE));
	 //Bitboards::print(position.attacks_from<KING>(SQ_E0,WHITE));
	 //Bitboards::print(position.attacks_from<PAWN>(SQ_E3,WHITE));
	 //Bitboards::print(position.attacks_from_pawn_nomask(SQ_E9,BLACK));

    for(Square s = SQ_A6; s <= SQ_I9; ++s)
	{
		//Bitboards::print(position.attacks_from_pawn_nomask(s, BLACK) & position.pieces(WHITE, PAWN));
		//Bitboards::print(position.attacks_from_pawn_nomask(s, WHITE) & position.pieces(BLACK, PAWN));
		//Bitboards::print(knight_attacks_bb(s,  position.occupied) & position.pieces(KNIGHT));
		//Bitboards::print(rook_attacks_bb(s, position.occupied,position.occupied_rl90)& position.pieces(ROOK));
		//Bitboards::print(cannon_control_bb(s,  position.occupied,position.occupied_rl90) & position.pieces(CANNON));
		//Bitboards::print(bishop_attacks_bb(s, position.occupied)   & position.pieces(BISHOP));
		//Bitboards::print(position.attacks_from<ADVISOR>(s,BLACK) & position.pieces(ADVISOR));
		//Bitboards::print(position.attacks_from<ADVISOR>(s,WHITE) & position.pieces(ADVISOR));
		//Bitboards::print(position.attacks_from<KING>(s,BLACK) & position.pieces(KING));
		//Bitboards::print(position.attacks_from<KING>(s,WHITE) & position.pieces(KING));

		//Bitboards::print(position.attackers_to(s));
		//Bitboards::print((knight_attackers_to_bb(s, position.pieces(KNIGHT), position.occupied)));
		
		//Bitboards::print(knight_attacks_bb(s,  position.occupied) );

		//Bitboards::print(position.attacks_from(position.piece_on(s),s));
	}

	//Square s = SQ_A5;
	//Bitboards::print(position.attacks_from_pawn_nomask(s, BLACK) & position.pieces(WHITE, PAWN));
	//Bitboards::print(position.attacks_from_pawn_nomask(s, WHITE) & position.pieces(BLACK, PAWN));

    test_move_gen(position);

	//position.occupied.print();
	//printf("\n");

	//Bitboard occ = bitboard_rotate_l90_bb( position.occupied );
	//occ.printl90();
	//printf("\n");

	//position.occupied_rl90.print();

	//Bitboard b = position.attacks_from<ROOK>(SQ_I0);
	//b.print();

	//Bitboard b = position.attacks_from<CANNON>(SQ_B2);
	//b.print();

	//Bitboard b = position.attacks_from<KNIGHT>(SQ_B0);
	//b.print();

}
