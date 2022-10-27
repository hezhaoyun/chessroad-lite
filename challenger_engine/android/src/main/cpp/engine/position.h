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

#ifndef POSITION_H_INCLUDED
#define POSITION_H_INCLUDED

#include <cassert>
#include <cstddef>

#include "bitboard.h"
#include "types.h"


namespace Postion{
    extern void init_psq_value();
}



/// The checkInfo struct is initialized at c'tor time and keeps info used
/// to detect if a move gives check.
class Position;
struct Thread;

struct CheckInfo {

  explicit CheckInfo(const Position&);

  Bitboard dcCandidates;
  Bitboard forbid;
  Bitboard pinned;
  Bitboard checkSq[PIECE_TYPE_NB];
  Square ksq;
};


/// The StateInfo struct stores information we need to restore a Position
/// object to its previous state when we retract a move. Whenever a move
/// is made on the board (by calling Position::do_move), a StateInfo object
/// must be passed as a parameter.

struct StateInfo {
  Key pawnKey, materialKey;
  Value npMaterial[COLOR_NB];
  Value npAttackMaterial[COLOR_NB];
  int rule50, pliesFromNull;
  Score psq;
 

  Key key;
  Bitboard checkersBB;
  PieceType capturedType;
  StateInfo* previous;
};


/// When making a move the current StateInfo up to 'key' excluded is copied to
/// the new one. Here we calculate the quad words (64bits) needed to be copied.
const size_t StateCopySize64 = offsetof(StateInfo, key) / sizeof(uint64_t) + 1;


/// The position data structure. A position consists of the following data:
///
///    * For each piece type, a bitboard representing the squares occupied
///      by pieces of that type.
///    * For each color, a bitboard representing the squares occupied by
///      pieces of that color.
///    * A bitboard of all occupied squares.
///    * A bitboard of all checking pieces.
///    * A 64-entry array of pieces, indexed by the squares of the board.
///    * The current side to move.
///    * Information about the castling rights for both sides.
///    * The initial files of the kings and both pairs of rooks. This is
///      used to implement the Chess960 castling rules.
///    * The en passant square (which is SQ_NONE if no en passant capture is
///      possible).
///    * The squares of the kings for both sides.
///    * Hash keys for the position itself, the current pawn structure, and
///      the current material situation.
///    * Hash keys for all previous positions in the game for detecting
///      repetition draws.
///    * A counter for detecting 50 move rule draws.

class Position {
public:
  Position() {}
  Position(const Position& p, Thread* t) { *this = p; thisThread = t; }
  Position(const std::string& f, bool c960, Thread* t) { set(f, c960, t); }
  Position& operator=(const Position&);
  static void init();

  // Text input/output
  void set(const std::string& fen, bool isChess960, Thread* th);
  const std::string fen() const;
  const std::string pretty(Move m = MOVE_NONE) const;

  // Position representation
  Bitboard pieces() const;
  Bitboard piecesl90()const;
  Bitboard pieces(PieceType pt) const;
  Bitboard pieces(PieceType pt1, PieceType pt2) const;
  Bitboard pieces(Color c) const;
  Bitboard pieces(Color c, PieceType pt) const;
  Bitboard pieces(Color c, PieceType pt1, PieceType pt2) const;
  Piece piece_on(Square s) const;
  Square king_square(Color c) const;
  Square ep_square() const;
  bool is_empty(Square s) const;
  template<PieceType Pt> int count(Color c) const;
  template<PieceType Pt> const Square* list(Color c) const;

  // Checking
  Bitboard checkers() const;
  Bitboard discovered_check_candidates() const;
  Bitboard pinned_pieces() const;
  Bitboard cannon_forbid_bb(Color c) const;

  // Attacks to/from a given square
  Bitboard attackers_to(Square s) const;
  Bitboard attackers_to(Square s, Bitboard occ, Bitboard occl90) const;
  Bitboard attacks_from(Piece p, Square s) const;
  static Bitboard attacks_from(Piece p, Square s, Bitboard occ, Bitboard occl90);
  template<PieceType> Bitboard attacks_from(Square s) const;
  template<PieceType> Bitboard attacks_from(Square s, Color c) const;
  Bitboard attacks_from_pawn_nomask(Square s, Color c) const;

  // Properties of moves
  bool move_gives_check(Move m, const CheckInfo& ci) const;
  bool pl_move_is_legal(Move m, Bitboard pinned) const;
  bool is_pseudo_legal(const Move m) const;
  bool is_capture(Move m) const;
 
  bool is_passed_pawn_push(Move m) const;
  Piece piece_moved(Move m) const;
  PieceType captured_piece_type() const;
  bool is_in_check()const;
  int  is_repeat()const;

  // Piece specific
  bool pawn_is_passed(Color c, Square s) const;
  bool pawn_on_7th(Color c) const;
  bool opposite_bishops() const;
  bool bishop_pair(Color c) const;

  // Doing and undoing moves
  void do_move(Move m, StateInfo& st);
  void do_move(Move m, StateInfo& st, const CheckInfo& ci, bool moveIsCheck);
  void undo_move(Move m);
  void do_null_move(StateInfo& st);
  void undo_null_move();

  // Static exchange evaluation
  int see(Move m, int asymmThreshold = 0) const;
  int see_sign(Move m) const;

  // Accessing hash keys
  Key key() const;
  Key exclusion_key() const;
  Key pawn_key() const;
  Key material_key() const;

  // Incremental piece-square evaluation
  Score psq_score() const;
  Value non_pawn_material(Color c) const;
  Value attack_material(Color c)const;

  // Other properties of the position
  Color side_to_move() const;
  int game_ply() const;
  bool is_chess960() const;
  Thread* this_thread() const;
  int64_t nodes_searched() const;
  void set_nodes_searched(int64_t n);
  bool is_draw() const;

  // Position consistency check, for debugging
  bool pos_is_ok(int* failedStep = NULL) const;
  void flip();

private:
  // Initialization helpers (used while setting up a position)
  void clear();

  // Helper functions 
  Bitboard hidden_checkers(Square ksq, Color c) const;
  void put_piece(Square s, Color c, PieceType pt);
  void remove_piece(Square s, Color c, PieceType pt);
  void move_piece(Square from, Square to, Color c, PieceType pt);

  // Computing hash keys from scratch (for initialization and debugging)
  Key compute_key() const;
  Key compute_pawn_key() const;
  Key compute_material_key() const;

  // Computing incremental evaluation scores and material counts
  Score compute_psq_score() const;
  Value compute_non_pawn_material(Color c) const;
  Value compute_attack_material(Color c) const;

  public:
	  //后面添加的，为了处理rook和cannon的根据行或列一次构建招法位棋盘；
	  Bitboard occupied, occupied_rl90;

  private:

	  // Board and pieces
	  Piece board[SQUARE_NB];
	  Bitboard byTypeBB[PIECE_TYPE_NB];
	  Bitboard byColorBB[COLOR_NB];
	  int pieceCount[COLOR_NB][PIECE_TYPE_NB];
	  Square pieceList[COLOR_NB][PIECE_TYPE_NB][16];
	  int index[SQUARE_NB];

	  // Other info
	  StateInfo startState;
	  int64_t nodes;
	  int gamePly;
	  Color sideToMove;
	  Thread* thisThread;
	  StateInfo* st;
	  int chess960;
};

inline int64_t Position::nodes_searched() const {
  return nodes;
}

inline void Position::set_nodes_searched(int64_t n) {
  nodes = n;
}

inline Piece Position::piece_on(Square s) const {
  return board[s];
}

inline Piece Position::piece_moved(Move m) const {
  return board[from_sq(m)];
}

inline bool Position::is_empty(Square s) const {
  return board[s] == NO_PIECE;
}

inline Color Position::side_to_move() const {
  return sideToMove;
}

inline Bitboard Position::pieces() const {
  return byTypeBB[ALL_PIECES];
}

inline Bitboard Position::piecesl90()const{
  return occupied_rl90;
}
inline Bitboard Position::pieces(PieceType pt) const {
  return byTypeBB[pt];
}

inline Bitboard Position::pieces(PieceType pt1, PieceType pt2) const {
  return byTypeBB[pt1] | byTypeBB[pt2];
}

inline Bitboard Position::pieces(Color c) const {
  return byColorBB[c];
}

inline Bitboard Position::pieces(Color c, PieceType pt) const {
  return byColorBB[c] & byTypeBB[pt];
}

inline Bitboard Position::pieces(Color c, PieceType pt1, PieceType pt2) const {
  return byColorBB[c] & (byTypeBB[pt1] | byTypeBB[pt2]);
}

template<PieceType Pt> inline int Position::count(Color c) const {
  return pieceCount[c][Pt];
}

template<PieceType Pt> inline const Square* Position::list(Color c) const{
  return pieceList[c][Pt];
}


inline Square Position::king_square(Color c) const {
  return pieceList[c][KING][0];
}

//由于子有对称性，R_ROOK与B_ROOK这种，用哪个计算都没有关系，但是像BISHOP, ADVISOR, PAWN, KING这种，不具有位置
//的对称性，这样计算会出现问题；
//判断某个子是否受到攻击，往往采用：假设这个子是某种类型的子，反过来计算攻击位置，不具有对称性的子
//会得到错误的结果，防止误用，干脆分别实例化
//template<PieceType Pt>
//inline Bitboard Position::attacks_from(Square s) const {
//
//  //return  Pt == BISHOP || Pt == ROOK ? attacks_bb<Pt>(s, pieces())
//  //      : Pt == QUEEN  ? attacks_from<ROOK>(s) | attacks_from<BISHOP>(s)
//  //      : StepAttacksBB[Pt][s];
//
//	assert(Pt != KING);
//	assert(Pt != ADVISOR);
//	assert(Pt != BISHOP);
//	assert(Pt != PAWN);
//	return Pt == ROOK ? rook_attacks_bb(s, occupied, occupied_rl90)
//		:  Pt == CANNON ? cannon_control_bb(s, occupied, occupied_rl90)
//		:  Pt == KNIGHT ? knight_attacks_bb(s,occupied) 
//		:  Pt == BISHOP ? bishop_attacks_bb(s,occupied) 
//		:  StepAttacksBB[Pt][s];//如果是pawn，advisor,bishop，不具有对称性?
//}

template<>
inline Bitboard Position::attacks_from<ROOK>(Square s) const
{
	return rook_attacks_bb(s, occupied, occupied_rl90);
}

template<>
inline Bitboard Position::attacks_from<CANNON>(Square s) const
{
	return cannon_control_bb(s, occupied, occupied_rl90);
}

template<>
inline Bitboard Position::attacks_from<KNIGHT>(Square s) const
{
	return knight_attacks_bb(s,occupied);
}

template<>
inline Bitboard Position::attacks_from<ADVISOR>(Square s, Color c) const {
  return StepAttacksBB[make_piece(c, ADVISOR)][s];
}

template<>
inline Bitboard Position::attacks_from<BISHOP>(Square s, Color c) const {
  return bishop_attacks_bb(s,occupied);
}

template<>
inline Bitboard Position::attacks_from<KING>(Square s, Color c) const {
  return StepAttacksBB[make_piece(c, KING)][s];
}

template<>
inline Bitboard Position::attacks_from<PAWN>(Square s, Color c) const {
  return StepAttacksBB[make_piece(c, PAWN)][s];
}

inline Bitboard Position::attacks_from_pawn_nomask(Square s, Color c) const {
  return PawnNoMaskStepAttacksBB[c][s];
}

inline Bitboard Position::attacks_from(Piece p, Square s) const {
  return attacks_from(p, s, byTypeBB[ALL_PIECES], occupied_rl90);//byTypeBB[ALL_PIECES]===occupied
}

inline Bitboard Position::attackers_to(Square s) const {
  return attackers_to(s, byTypeBB[ALL_PIECES], occupied_rl90);//byTypeBB[ALL_PIECES]===occupied
}

inline Bitboard Position::checkers() const {
  return st->checkersBB;
}

inline Bitboard Position::discovered_check_candidates() const {
  return hidden_checkers(king_square(~sideToMove), sideToMove);//还要增加充当炮架子的子,处理起来复杂
}

inline Bitboard Position::pinned_pieces() const {

	Bitboard b, pinners, result;
	Square ksq = king_square(sideToMove);

	// Pinners are sliders that give check when a pinned piece is removed

	//rook
	pinners = pieces(~sideToMove, ROOK) & PseudoAttacks[ROOK][ksq];
	while (pinners) {
		b = between_bb(ksq, pop_lsb(&pinners)) & pieces();

		if (!more_than_one(b))
			result |= b & pieces(sideToMove);
	}

	//cannon
	pinners = pieces(~sideToMove, CANNON) & PseudoAttacks[ROOK][ksq];
	while (pinners) {
		b = between_bb(ksq, pop_lsb(&pinners)) & pieces();

		if (equal_to_two(b))
			result |= b & pieces(sideToMove);
	}

	//knight
	pinners = pieces(~sideToMove, KNIGHT);
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

	//king, face to face
	pinners = pieces(~sideToMove, KING) & PseudoAttacks[ROOK][ksq];
	while (pinners) {
		b = between_bb(ksq, pop_lsb(&pinners)) & pieces();

		if (!more_than_one(b))
			result |= b & pieces(sideToMove);
	}

	return result;
}

inline Bitboard Position::cannon_forbid_bb(Color c) const
{
    Square ksq =  king_square(c);
	Bitboard forbids = pieces(~c, CANNON) & PseudoAttacks[ROOK][ksq];
	Bitboard b, result;

	while(forbids)
	{
        b = between_bb(ksq, pop_lsb(&forbids));
		if(b)
		{
            if( !(b & pieces()) )
			{ 
               result |= b;
			}
		}
	}

	return result;
}

inline bool Position::pawn_is_passed(Color c, Square s) const {
  return !(pieces(~c, PAWN) & passed_pawn_mask(c, s));
}

inline Key Position::key() const {
  return st->key;
}

inline Key Position::pawn_key() const {
  return st->pawnKey;
}

inline Key Position::material_key() const {
  return st->materialKey;
}

inline Score Position::psq_score() const {
  return st->psq;
}

inline Value Position::non_pawn_material(Color c) const {
  return st->npMaterial[c];
}

inline Value Position::attack_material(Color c) const {
	return st->npAttackMaterial[c];
}

inline bool Position::is_passed_pawn_push(Move m) const {

  return   type_of(piece_moved(m)) == PAWN
        && pawn_is_passed(sideToMove, to_sq(m));
}

inline int Position::game_ply() const {
  return gamePly;
}

inline bool Position::opposite_bishops() const {

  return   pieceCount[WHITE][BISHOP] == 1
        && pieceCount[BLACK][BISHOP] == 1
        && opposite_colors(pieceList[WHITE][BISHOP][0], pieceList[BLACK][BISHOP][0]);
}

inline bool Position::bishop_pair(Color c) const {

  return   pieceCount[c][BISHOP] >= 2
        && opposite_colors(pieceList[c][BISHOP][0], pieceList[c][BISHOP][1]);
}

inline bool Position::pawn_on_7th(Color c) const {
  return pieces(c, PAWN) & rank_bb(relative_rank(c, RANK_7));
}

inline bool Position::is_chess960() const {
  return chess960;
}


inline bool Position::is_capture(Move m) const {
 
  assert(is_ok(m));
  
  return !is_empty(to_sq(m));
}

inline PieceType Position::captured_piece_type() const {
  return st->capturedType;
}

inline Thread* Position::this_thread() const {
  return thisThread;
}

inline void Position::put_piece(Square s, Color c, PieceType pt) {

  board[s] = make_piece(c, pt);
  byTypeBB[ALL_PIECES] |= s;
  byTypeBB[pt] |= s;
  byColorBB[c] |= s;
  index[s] = pieceCount[c][pt]++;
  pieceList[c][pt][index[s]] = s;

  occupied      ^= s;
  occupied_rl90 ^= square_rotate_l90_bb(s);
}

inline void Position::move_piece(Square from, Square to, Color c, PieceType pt) {

  // index[from] is not updated and becomes stale. This works as long
  // as index[] is accessed just by known occupied squares.
  Bitboard from_to_bb = SquareBB[from] ^ SquareBB[to];
  byTypeBB[ALL_PIECES] ^= from_to_bb;
  byTypeBB[pt] ^= from_to_bb;
  byColorBB[c] ^= from_to_bb;
  board[from] = NO_PIECE;
  board[to] = make_piece(c, pt);
  index[to] = index[from];
  pieceList[c][pt][index[to]] = to;

  occupied      ^= from;
  occupied      ^= to;
  occupied_rl90 ^= square_rotate_l90_bb(from);
  occupied_rl90 ^= square_rotate_l90_bb(to);
}

inline void Position::remove_piece(Square s, Color c, PieceType pt) {

  // WARNING: This is not a reversible operation. If we remove a piece in
  // do_move() and then replace it in undo_move() we will put it at the end of
  // the list and not in its original place, it means index[] and pieceList[]
  // are not guaranteed to be invariant to a do_move() + undo_move() sequence.
  byTypeBB[ALL_PIECES] ^= s;
  byTypeBB[pt] ^= s;
  byColorBB[c] ^= s;
  /* board[s] = NO_PIECE; */ // Not needed, will be overwritten by capturing
  Square lastSquare = pieceList[c][pt][--pieceCount[c][pt]];
  index[lastSquare] = index[s];
  pieceList[c][pt][index[lastSquare]] = lastSquare;
  pieceList[c][pt][pieceCount[c][pt]] = SQ_NONE;

  occupied      ^= s;
  occupied_rl90 ^= square_rotate_l90_bb(s);
}

extern void test_position();

#endif // #ifndef POSITION_H_INCLUDED
