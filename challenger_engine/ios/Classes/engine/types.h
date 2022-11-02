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

#ifndef TYPES_H_INCLUDED
#define TYPES_H_INCLUDED

/// For Linux and OSX configuration is done automatically using Makefile. To get
/// started type 'make help'.
///
/// For Windows, part of the configuration is detected automatically, but some
/// switches need to be set manually:
///
/// -DNDEBUG      | Disable debugging mode. Use always.
///
/// -DNO_PREFETCH | Disable use of prefetch asm-instruction. A must if you want
///               | the executable to run on some very old machines.
///
/// -DUSE_POPCNT  | Add runtime support for use of popcnt asm-instruction. Works
///               | only in 64-bit mode. For compiling requires hardware with
///               | popcnt support.

#include <cassert>
#include <cctype>
#include <climits>
#include <cstdlib>

#include "platform.h"
#include "boardtype.h"

#define unlikely(x) (x) // For code annotation purposes

#if defined(_WIN64) && !defined(IS_64BIT)
#  include <intrin.h> // MSVC popcnt and bsfq instrinsics
#  define IS_64BIT

#endif

#if defined(USE_POPCNT) && defined(_MSC_VER) && defined(__INTEL_COMPILER)
#  include <nmmintrin.h> // Intel header for _mm_popcnt_u64() intrinsic
#endif

#  if !defined(NO_PREFETCH) && (defined(__INTEL_COMPILER) || defined(_MSC_VER))
#   include <xmmintrin.h> // Intel and Microsoft header for _mm_prefetch()
#  endif

#define CACHE_LINE_SIZE 64
#if defined(_MSC_VER) || defined(__INTEL_COMPILER)
#  define CACHE_LINE_ALIGNMENT __declspec(align(CACHE_LINE_SIZE))
#else
#  define CACHE_LINE_ALIGNMENT  __attribute__ ((aligned(CACHE_LINE_SIZE)))
#endif

#ifdef _MSC_VER
#  define FORCE_INLINE  __forceinline
#elif defined(__GNUC__)
#  define FORCE_INLINE  inline __attribute__((always_inline))
#else
#  define FORCE_INLINE  inline
#endif

#ifdef USE_POPCNT
const bool HasPopCnt = true;
#else
const bool HasPopCnt = false;
#endif

#ifdef IS_64BIT
const bool Is64Bit = true;
#else
const bool Is64Bit = false;
#endif

typedef uint64_t     Key;
typedef bitboardtype Bitboard;

const int MAX_MOVES      = 192;
const int MAX_PLY        = 100;
const int MAX_PLY_PLUS_6 = MAX_PLY + 6;

/// A move needs 16 bits to be stored
///
/// bit  0- 7: destination square (from 0 to 63)
/// bit  8-15: origin square (from 0 to 63)

/// Special cases are MOVE_NONE and MOVE_NULL. We can sneak these in because in
/// any normal move destination square is always different from origin square
/// while MOVE_NONE and MOVE_NULL have the same origin and destination square.

enum Move {
  MOVE_NONE,
  MOVE_NULL = 89
};

enum MoveType {
  NORMAL,
};

enum Phase {
  PHASE_ENDGAME,
  PHASE_MIDGAME = 128,
  MG = 0, EG = 1, PHASE_NB = 2
};

enum ScaleFactor {
  SCALE_FACTOR_DRAW   = 0,
  SCALE_FACTOR_NORMAL = 64,
  SCALE_FACTOR_MAX    = 128,
  SCALE_FACTOR_NONE   = 255
};

enum Bound {
  BOUND_NONE,
  BOUND_UPPER,
  BOUND_LOWER,
  BOUND_EXACT = BOUND_UPPER | BOUND_LOWER
};

enum Value {
  VALUE_ZERO      = 0,
  VALUE_DRAW      = 0,
  VALUE_KNOWN_WIN = 15000,
  VALUE_REPEAT    = 25000,
  VALUE_MATE      = 30000,
  VALUE_INFINITE  = 30001,
  VALUE_NONE      = 30002,

  VALUE_MATE_IN_MAX_PLY  =  VALUE_MATE - MAX_PLY,
  VALUE_MATED_IN_MAX_PLY = -VALUE_MATE + MAX_PLY,

  VALUE_ENSURE_INTEGER_SIZE_P = INT_MAX,
  VALUE_ENSURE_INTEGER_SIZE_N = INT_MIN,


  PawnValueMg   = 89,   PawnValueEg   = 305,
  BishopValueMg = 335,   BishopValueEg = 400,
  AdvisorValueMg= 400,   AdvisorValueEg= 380,
  KnightValueMg = 802,   KnightValueEg = 865,
  CannonValueMg = 865,   CannonValueEg = 842,
  RookValueMg   = 1891,  RookValueEg   = 2020,
};

enum RepeatType {
	REPEATE_NONE = 0,
	REPEATE_TRUE = 1,
	REPEATE_ME_CHECK = 2,
	REPEATE_OPP_CHECK= 4
};

enum PieceType {
  NO_PIECE_TYPE, PAWN, BISHOP, ADVISOR, KNIGHT, CANNON, ROOK, KING,
  ALL_PIECES = 0,
  PIECE_TYPE_NB = 8
};

enum Piece {
  NO_PIECE,
  W_PAWN = 1, W_BISHOP, W_ADVISOR, W_KNIGHT, W_CANNON, W_ROOK, W_KING,
  B_PAWN = 9, B_BISHOP, B_ADVISOR, B_KNIGHT, B_CANNON, B_ROOK, B_KING,
  PIECE_NB = 16
};

enum Color {
  WHITE, BLACK, NO_COLOR, COLOR_NB = 2
};

enum Depth {

  ONE_PLY = 2,

  DEPTH_ZERO          =  0 * ONE_PLY,
  DEPTH_QS_CHECKS     = -1 * ONE_PLY,
  DEPTH_QS_NO_CHECKS  = -2 * ONE_PLY,
  DEPTH_QS_RECAPTURES = -5 * ONE_PLY,

  DEPTH_NONE = -127 * ONE_PLY
};

enum Square {
  SQ_A0, SQ_B0, SQ_C0, SQ_D0, SQ_E0, SQ_F0, SQ_G0, SQ_H0, SQ_I0,
  SQ_A1, SQ_B1, SQ_C1, SQ_D1, SQ_E1, SQ_F1, SQ_G1, SQ_H1, SQ_I1,
  SQ_A2, SQ_B2, SQ_C2, SQ_D2, SQ_E2, SQ_F2, SQ_G2, SQ_H2, SQ_I2,
  SQ_A3, SQ_B3, SQ_C3, SQ_D3, SQ_E3, SQ_F3, SQ_G3, SQ_H3, SQ_I3,
  SQ_A4, SQ_B4, SQ_C4, SQ_D4, SQ_E4, SQ_F4, SQ_G4, SQ_H4, SQ_I4,
  SQ_A5, SQ_B5, SQ_C5, SQ_D5, SQ_E5, SQ_F5, SQ_G5, SQ_H5, SQ_I5,
  SQ_A6, SQ_B6, SQ_C6, SQ_D6, SQ_E6, SQ_F6, SQ_G6, SQ_H6, SQ_I6,
  SQ_A7, SQ_B7, SQ_C7, SQ_D7, SQ_E7, SQ_F7, SQ_G7, SQ_H7, SQ_I7,
  SQ_A8, SQ_B8, SQ_C8, SQ_D8, SQ_E8, SQ_F8, SQ_G8, SQ_H8, SQ_I8,
  SQ_A9, SQ_B9, SQ_C9, SQ_D9, SQ_E9, SQ_F9, SQ_G9, SQ_H9, SQ_I9,
  SQ_NONE,

  SQUARE_NB = 90,

  DELTA_N =  9,
  DELTA_E =  1,
  DELTA_S = -9,
  DELTA_W = -1,

  DELTA_NN = DELTA_N + DELTA_N,
  DELTA_NE = DELTA_N + DELTA_E,
  DELTA_SE = DELTA_S + DELTA_E,
  DELTA_SS = DELTA_S + DELTA_S,
  DELTA_SW = DELTA_S + DELTA_W,
  DELTA_NW = DELTA_N + DELTA_W
};

enum File {
  FILE_A, FILE_B, FILE_C, FILE_D, FILE_E, FILE_F, FILE_G, FILE_H, FILE_I, FILE_NB
};

enum Rank {
  RANK_0, RANK_1, RANK_2, RANK_3, RANK_4, RANK_5, RANK_6, RANK_7, RANK_8, RANK_9, RANK_NB
};


/// Score enum keeps a midgame and an endgame value in a single integer (enum),
/// first LSB 16 bits are used to store endgame value, while upper bits are used
/// for midgame value. Compiler is free to choose the enum type as long as can
/// keep its data, so ensure Score to be an integer type.
enum Score {
  SCORE_ZERO,
  SCORE_ENSURE_INTEGER_SIZE_P = INT_MAX,
  SCORE_ENSURE_INTEGER_SIZE_N = INT_MIN
};

//Vertical flip
const int8_t VerticalFlip[SQUARE_NB] =
{ 
	SQ_A9, SQ_B9, SQ_C9, SQ_D9, SQ_E9, SQ_F9, SQ_G9, SQ_H9, SQ_I9,
	SQ_A8, SQ_B8, SQ_C8, SQ_D8, SQ_E8, SQ_F8, SQ_G8, SQ_H8, SQ_I8,
	SQ_A7, SQ_B7, SQ_C7, SQ_D7, SQ_E7, SQ_F7, SQ_G7, SQ_H7, SQ_I7,
	SQ_A6, SQ_B6, SQ_C6, SQ_D6, SQ_E6, SQ_F6, SQ_G6, SQ_H6, SQ_I6,
	SQ_A5, SQ_B5, SQ_C5, SQ_D5, SQ_E5, SQ_F5, SQ_G5, SQ_H5, SQ_I5,
	SQ_A4, SQ_B4, SQ_C4, SQ_D4, SQ_E4, SQ_F4, SQ_G4, SQ_H4, SQ_I4,
	SQ_A3, SQ_B3, SQ_C3, SQ_D3, SQ_E3, SQ_F3, SQ_G3, SQ_H3, SQ_I3,
	SQ_A2, SQ_B2, SQ_C2, SQ_D2, SQ_E2, SQ_F2, SQ_G2, SQ_H2, SQ_I2,
	SQ_A1, SQ_B1, SQ_C1, SQ_D1, SQ_E1, SQ_F1, SQ_G1, SQ_H1, SQ_I1,
	SQ_A0, SQ_B0, SQ_C0, SQ_D0, SQ_E0, SQ_F0, SQ_G0, SQ_H0, SQ_I0,
};
//Horizontal flip
const int8_t HorizontalFlip[SQUARE_NB] =
{ 
  SQ_I0, SQ_H0, SQ_G0, SQ_F0, SQ_E0, SQ_D0, SQ_C0, SQ_B0, SQ_A0,
  SQ_I1, SQ_H1, SQ_G1, SQ_F1, SQ_E1, SQ_D1, SQ_C1, SQ_B1, SQ_A1,
  SQ_I2, SQ_H2, SQ_G2, SQ_F2, SQ_E2, SQ_D2, SQ_C2, SQ_B2, SQ_A2,
  SQ_I3, SQ_H3, SQ_G3, SQ_F3, SQ_E3, SQ_D3, SQ_C3, SQ_B3, SQ_A3,
  SQ_I4, SQ_H4, SQ_G4, SQ_F4, SQ_E4, SQ_D4, SQ_C4, SQ_B4, SQ_A4,
  SQ_I5, SQ_H5, SQ_G5, SQ_F5, SQ_E5, SQ_D5, SQ_C5, SQ_B5, SQ_A5,
  SQ_I6, SQ_H6, SQ_G6, SQ_F6, SQ_E6, SQ_D6, SQ_C6, SQ_B6, SQ_A6,
  SQ_I7, SQ_H7, SQ_G7, SQ_F7, SQ_E7, SQ_D7, SQ_C7, SQ_B7, SQ_A7,
  SQ_I8, SQ_H8, SQ_G8, SQ_F8, SQ_E8, SQ_D8, SQ_C8, SQ_B8, SQ_A8,
  SQ_I9, SQ_H9, SQ_G9, SQ_F9, SQ_E9, SQ_D9, SQ_C9, SQ_B9, SQ_A9,
};

//SQUARE
const int8_t SquareMake[RANK_NB][FILE_NB] = 
{
  SQ_A0, SQ_B0, SQ_C0, SQ_D0, SQ_E0, SQ_F0, SQ_G0, SQ_H0, SQ_I0,
  SQ_A1, SQ_B1, SQ_C1, SQ_D1, SQ_E1, SQ_F1, SQ_G1, SQ_H1, SQ_I1,
  SQ_A2, SQ_B2, SQ_C2, SQ_D2, SQ_E2, SQ_F2, SQ_G2, SQ_H2, SQ_I2,
  SQ_A3, SQ_B3, SQ_C3, SQ_D3, SQ_E3, SQ_F3, SQ_G3, SQ_H3, SQ_I3,
  SQ_A4, SQ_B4, SQ_C4, SQ_D4, SQ_E4, SQ_F4, SQ_G4, SQ_H4, SQ_I4,
  SQ_A5, SQ_B5, SQ_C5, SQ_D5, SQ_E5, SQ_F5, SQ_G5, SQ_H5, SQ_I5,
  SQ_A6, SQ_B6, SQ_C6, SQ_D6, SQ_E6, SQ_F6, SQ_G6, SQ_H6, SQ_I6,
  SQ_A7, SQ_B7, SQ_C7, SQ_D7, SQ_E7, SQ_F7, SQ_G7, SQ_H7, SQ_I7,
  SQ_A8, SQ_B8, SQ_C8, SQ_D8, SQ_E8, SQ_F8, SQ_G8, SQ_H8, SQ_I8,
  SQ_A9, SQ_B9, SQ_C9, SQ_D9, SQ_E9, SQ_F9, SQ_G9, SQ_H9, SQ_I9,
};

//SQUARE_FILE
const int8_t SquareFile[SQUARE_NB] = 
{
  0, 1, 2, 3, 4, 5, 6, 7, 8,
  0, 1, 2, 3, 4, 5, 6, 7, 8,
  0, 1, 2, 3, 4, 5, 6, 7, 8,
  0, 1, 2, 3, 4, 5, 6, 7, 8,
  0, 1, 2, 3, 4, 5, 6, 7, 8,
  0, 1, 2, 3, 4, 5, 6, 7, 8,
  0, 1, 2, 3, 4, 5, 6, 7, 8,
  0, 1, 2, 3, 4, 5, 6, 7, 8,
  0, 1, 2, 3, 4, 5, 6, 7, 8,
  0, 1, 2, 3, 4, 5, 6, 7, 8,
};
//SQUARE_RANK
const int8_t SquareRank[SQUARE_NB] = 
{
  0, 0, 0, 0, 0, 0, 0, 0, 0,
  1, 1, 1, 1, 1, 1, 1, 1, 1,
  2, 2, 2, 2, 2, 2, 2, 2, 2,
  3, 3, 3, 3, 3, 3, 3, 3, 3,
  4, 4, 4, 4, 4, 4, 4, 4, 4,
  5, 5, 5, 5, 5, 5, 5, 5, 5,
  6, 6, 6, 6, 6, 6, 6, 6, 6,
  7, 7, 7, 7, 7, 7, 7, 7, 7,
  8, 8, 8, 8, 8, 8, 8, 8, 8,
  9, 9, 9, 9, 9, 9, 9, 9, 9,
};

inline Score make_score(int mg, int eg) { return Score((mg << 16) + eg); }

/// Extracting the signed lower and upper 16 bits it not so trivial because
/// according to the standard a simple cast to short is implementation defined
/// and so is a right shift of a signed integer.

inline Value mg_value(Score s) {
	return Value(((s + 0x8000) & ~0xffff) / 0x10000);
}

/// On Intel 64 bit we have a small speed regression with the standard conforming
/// version, so use a faster code in this case that, although not 100% standard
/// compliant it seems to work for Intel and MSVC.
#if defined(IS_64BIT) && (!defined(__GNUC__) || defined(__INTEL_COMPILER))

inline Value eg_value(Score s) { return Value(int16_t(s & 0xffff)); }

#else

inline Value eg_value(Score s) {
  return Value((int)(unsigned(s) & 0x7fffu) - (int)(unsigned(s) & 0x8000u));
}

#endif

#define ENABLE_SAFE_OPERATORS_ON(T)                                         \
inline T operator+(const T d1, const T d2) { return T(int(d1) + int(d2)); } \
inline T operator-(const T d1, const T d2) { return T(int(d1) - int(d2)); } \
inline T operator*(int i, const T d) { return T(i * int(d)); }              \
inline T operator*(const T d, int i) { return T(int(d) * i); }              \
inline T operator-(const T d) { return T(-int(d)); }                        \
inline T& operator+=(T& d1, const T d2) { return d1 = d1 + d2; }            \
inline T& operator-=(T& d1, const T d2) { return d1 = d1 - d2; }            \
inline T& operator*=(T& d, int i) { return d = T(int(d) * i); }

#define ENABLE_OPERATORS_ON(T) ENABLE_SAFE_OPERATORS_ON(T)                  \
inline T& operator++(T& d) { return d = T(int(d) + 1); }                    \
inline T& operator--(T& d) { return d = T(int(d) - 1); }                    \
inline T operator/(const T d, int i) { return T(int(d) / i); }              \
inline T& operator/=(T& d, int i) { return d = T(int(d) / i); }

ENABLE_OPERATORS_ON(Value)
ENABLE_OPERATORS_ON(PieceType)
ENABLE_OPERATORS_ON(Piece)
ENABLE_OPERATORS_ON(Color)
ENABLE_OPERATORS_ON(Depth)
ENABLE_OPERATORS_ON(Square)
ENABLE_OPERATORS_ON(File)
ENABLE_OPERATORS_ON(Rank)

/// Added operators for adding integers to a Value
inline Value operator+(Value v, int i) { return Value(int(v) + i); }
inline Value operator-(Value v, int i) { return Value(int(v) - i); }

ENABLE_SAFE_OPERATORS_ON(Score)

/// Only declared but not defined. We don't want to multiply two scores due to
/// a very high risk of overflow. So user should explicitly convert to integer.
inline Score operator*(Score s1, Score s2);

/// Division of a Score must be handled separately for each term
inline Score operator/(Score s, int i) {
  return make_score(mg_value(s) / i, eg_value(s) / i);
}

#undef ENABLE_OPERATORS_ON
#undef ENABLE_SAFE_OPERATORS_ON

extern Value PieceValue[PHASE_NB][PIECE_NB];

struct ExtMove {
  Move move;
  int score;
};

inline bool operator<(const ExtMove& f, const ExtMove& s) {
  return f.score < s.score;
}

inline Color operator~(Color c) {
  return Color(c ^ 1);
}

inline Square operator~(Square s) {
  return Square(VerticalFlip[s]);//Square(s ^ 56); // Vertical flip SQ_A0 -> SQ_A9
}

inline Square operator|(File f, Rank r) {
  return Square(SquareMake[r][f]);//Square((r << 3) | f);
}

inline Value mate_in(int ply) {
  return VALUE_MATE - ply;
}

inline Value mated_in(int ply) {
  return -VALUE_MATE + ply;
}

inline Value repeat_value(int ply, int reptype) {
	int v;
	v = (reptype & REPEATE_ME_CHECK) ? (-VALUE_REPEAT + ply) : 0 + (reptype & REPEATE_OPP_CHECK) ? (VALUE_REPEAT - ply) : 0;
	return Value(v == 0 ? VALUE_DRAW : v);
}

inline Piece make_piece(Color c, PieceType pt) {
  return Piece((c << 3) | pt);
}

inline PieceType type_of(Piece p)  {
  return PieceType(p & 7);
}

inline Color color_of(Piece p) {
  assert(p != NO_PIECE);
  return Color(p >> 3);
}

inline bool is_ok(Square s) {
  return s >= SQ_A0 && s <= SQ_I9;
}

inline bool is_ok(int s){
	return s >= SQ_A0 && s <= SQ_I9;
}

inline File file_of(Square s) {
  return File(SquareFile[s]);//File(s & 7);
}

inline Rank rank_of(Square s) {
  return Rank(SquareRank[s]);//Rank(s >> 3);
}

inline Square mirror(Square s) {
  return Square(HorizontalFlip[s]);//Square(s ^ 7); // Horizontal flip SQ_A1 -> SQ_H1
}

inline Square relative_square(Color c, Square s) {
  //return Square(s ^ (c * 56));
  return c ? (Square(VerticalFlip[s])) : (s);
}

inline Rank relative_rank(Color c, Rank r) {
 // return Rank(r ^ (c * 7));
  return c ? (Rank(9 - r)) : (r);
}

inline Rank relative_rank(Color c, Square s) {
  return relative_rank(c, rank_of(s));	
}

inline Color square_color(Square s){
  return Color(((int)rank_of(s)) > RANK_4);
}

inline bool opposite_colors(Square s1, Square s2) {
  return  square_color(s1) != square_color(s2);
}

inline char file_to_char(File f, bool tolower = true) {
  return char(f - FILE_A + (tolower ? 'a' : 'A'));
}

inline char rank_to_char(Rank r) {
  return char(r - RANK_0 + '0');
}

inline Square pawn_push(Color c) {
  return c == WHITE ? DELTA_N : DELTA_S;
}

inline Square from_sq(Move m) {
  return Square((m >> 8));
}

inline Square to_sq(Move m) {
  return Square(m & 0xFF);
}

inline MoveType type_of(Move m) {
  return NORMAL;//chinese chess, all is normal
}

inline Move make_move(Square from, Square to) {
  return Move(to | (from << 8));
}

template<MoveType T>
inline Move make(Square from, Square to, PieceType pt = KNIGHT) {
  return Move(to | (from << 8));
}

inline bool is_ok(Move m) {
  return from_sq(m) != to_sq(m); // Catches also MOVE_NULL and MOVE_NONE
}

#include <string>

inline const std::string square_to_string(Square s) {
  char ch[] = { file_to_char(file_of(s)), rank_to_char(rank_of(s)), 0 };
  return ch;
}

#endif // #ifndef TYPES_H_INCLUDED
