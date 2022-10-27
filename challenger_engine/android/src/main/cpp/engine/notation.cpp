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
#include <iomanip>
#include <sstream>
#include <stack>

#include "movegen.h"
#include "notation.h"
#include "position.h"

using namespace std;

static const char* PieceToChar[COLOR_NB] = { " PBANCRK", " pbancrk" };

static std::string piece_to_chinese(char p)
{
	switch(p)
	{
	case ' ': return std::string(" ");
	case 'P': return std::string("兵");
	case 'p': return std::string("卒");
	case 'B': return std::string("相");
	case 'b': return std::string("象");
	case 'A': return std::string("士");
	case 'a': return std::string("侍");
	case 'N': return std::string("马");
	case 'n': return std::string("馬");
	case 'C': return std::string("炮");
	case 'c': return std::string("包");
	case 'R': return std::string("车");
	case 'r': return std::string("車");
	case 'K': return std::string("帅");
	case 'k': return std::string("将");
	}

	return std::string();
}

/// score_to_uci() converts a value to a string suitable for use with the UCI
/// protocol specifications:
///
/// cp <x>     The score from the engine's point of view in centipawns.
/// mate <y>   Mate in y moves, not plies. If the engine is getting mated
///            use negative values for y.

string score_to_uci(Value v, Value alpha, Value beta) {

  stringstream s;

  if (abs(v) < VALUE_MATE_IN_MAX_PLY)
      s << /*"cp " << */v * 100 / int(PawnValueMg);
  else
      s << "mate " << (v > 0 ? VALUE_MATE - v + 1 : -VALUE_MATE - v) / 2;

  s << (v >= beta ? " lowerbound" : v <= alpha ? " upperbound" : "");

  return s.str();
}


/// move_to_uci() converts a move to a string in coordinate notation
/// (g1f3, a7a8q, etc.). The only special case is castling moves, where we print
/// in the e1g1 notation in normal chess mode, and in e1h1 notation in chess960
/// mode. Internally castle moves are always coded as "king captures rook".

const string move_to_uci(Move m, bool chess960) {

  Square from = from_sq(m);
  Square to = to_sq(m);

  if (m == MOVE_NONE)
      return "(none)";

  if (m == MOVE_NULL)
      return "0000";

  string move = square_to_string(from) + square_to_string(to);

  return move;
}


/// move_from_uci() takes a position and a string representing a move in
/// simple coordinate notation and returns an equivalent legal Move if any.

Move move_from_uci(const Position& pos, string& str) {

  if (str.length() == 5)
      str[4] = char(tolower(str[4]));

  for (MoveList<LEGAL> it(pos); *it; ++it)
      if (str == move_to_uci(*it, pos.is_chess960()))
          return *it;

  return MOVE_NONE;
}


/// move_to_san() takes a position and a legal Move as input and returns its
/// short algebraic notation representation.

const string move_to_san(Position& pos, Move m) {

  if (m == MOVE_NONE)
      return "(none)";

  if (m == MOVE_NULL)
      return "(null)";

  assert(MoveList<LEGAL>(pos).contains(m));

  Bitboard others, b;
  string san;
  Color us = pos.side_to_move();
  Square from = from_sq(m);
  Square to = to_sq(m);
  Piece pc = pos.piece_on(from);
  PieceType pt = type_of(pc);

  {
      if (pt != PAWN)
      {
          san = PieceToChar[WHITE][pt]; // Upper case

          // Disambiguation if we have more then one piece of type 'pt' that can
          // reach 'to' with a legal move.
          others = b = (pos.attacks_from(pc, to) & pos.pieces(us, pt)) ^ from;

          while (b)
          {
              Move move = make_move(pop_lsb(&b), to);
              if (!pos.pl_move_is_legal(move, pos.pinned_pieces()))
                  others ^= from_sq(move);
          }

          if (others)
          {
              if (!(others & file_bb(from)))
                  san += file_to_char(file_of(from));

              else if (!(others & rank_bb(from)))
                  san += rank_to_char(rank_of(from));

              else
                  san += square_to_string(from);
          }
      }
      else if (pos.is_capture(m))
          san = file_to_char(file_of(from));

      if (pos.is_capture(m))
          san += 'x';

      san += square_to_string(to);


  }

  if (pos.move_gives_check(m, CheckInfo(pos)))
  {
      StateInfo st;
      pos.do_move(m, st);
      san += MoveList<LEGAL>(pos).size() ? "+" : "#";
      pos.undo_move(m);
  } 

  return move_to_chinese(pos, m);  
}

std::string move_to_chinese(const Position& pos, Move m)
{
  Color us = pos.side_to_move();
  Square from = from_sq(m);
  Square to = to_sq(m);
  Piece pc = pos.piece_on(from);
  PieceType pt = type_of(pc);

  char p = PieceToChar[us][pt];

  std::string move = "\n";

  move += piece_to_chinese(p);
  move += square_to_string(from);
  move += square_to_string(to);

  return move;
}


/// pretty_pv() formats human-readable search information, typically to be
/// appended to the search log file. It uses the two helpers below to pretty
/// format time and score respectively.

static string time_to_string(int64_t msecs) {

  const int MSecMinute = 1000 * 60;
  const int MSecHour   = 1000 * 60 * 60;

  int64_t hours   =   msecs / MSecHour;
  int64_t minutes =  (msecs % MSecHour) / MSecMinute;
  int64_t seconds = ((msecs % MSecHour) % MSecMinute) / 1000;

  stringstream s;

  if (hours)
      s << hours << ':';

  s << setfill('0') << setw(2) << minutes << ':' << setw(2) << seconds;

  return s.str();
}

static string score_to_string(Value v) {

  stringstream s;

  if (v >= VALUE_MATE_IN_MAX_PLY)
      s << "#" << (VALUE_MATE - v + 1) / 2;

  else if (v <= VALUE_MATED_IN_MAX_PLY)
      s << "-#" << (VALUE_MATE + v) / 2;

  else
      s << setprecision(2) << fixed << showpos << float(v) / PawnValueMg;

  return s.str();
}

string pretty_pv(Position& pos, int depth, Value value, int64_t msecs, Move pv[]) {

  const int64_t K = 1000;
  const int64_t M = 1000000;

  std::stack<StateInfo> st;
  Move* m = pv;
  string san, padding;
  size_t length;
  stringstream s;

  s << setw(2) << depth
    << setw(8) << score_to_string(value)
    << setw(8) << time_to_string(msecs);

  if (pos.nodes_searched() < M)
      s << setw(8) << pos.nodes_searched() / 1 << "  ";

  else if (pos.nodes_searched() < K * M)
      s << setw(7) << pos.nodes_searched() / K << "K  ";

  else
      s << setw(7) << pos.nodes_searched() / M << "M  ";

  padding = string(s.str().length(), ' ');
  length = padding.length();

  while (*m != MOVE_NONE)
  {
      san = move_to_san(pos, *m);

      if (length + san.length() > 80)
      {
          s << "\n" + padding;
          length = padding.length();
      }

      s << san << ' ';
      length += san.length() + 1;

      st.push(StateInfo());
      pos.do_move(*m++, st.top());
  }

  while (m != pv)
      pos.undo_move(*--m);

  return s.str();
}
