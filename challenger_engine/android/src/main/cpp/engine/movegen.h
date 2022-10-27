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

#ifndef MOVEGEN_H_INCLUDED
#define MOVEGEN_H_INCLUDED

#include "types.h"

enum GenType {
  CAPTURES,
  QUIETS,
  QUIET_CHECKS,
  EVASIONS,
  NON_EVASIONS,
  LEGAL
};

class Position;

template<GenType>
ExtMove* generate(const Position& pos, ExtMove* mlist);

/// The MoveList struct is a simple wrapper around generate(), sometimes comes
/// handy to use this class instead of the low level generate() function.
template<GenType T>
struct MoveList {

  explicit MoveList(const Position& pos) : cur(mlist), last(generate<T>(pos, mlist)) { last->move = MOVE_NONE; }
  void operator++() { cur++; }
  Move operator*() const { return cur->move; }
  size_t size() const { return last - mlist; }
  bool contains(Move m) const {
    for (const ExtMove* it(mlist); it != last; ++it) if (it->move == m) return true;
    return false;
  }

private:
  ExtMove mlist[MAX_MOVES];
  ExtMove *cur, *last;
};
extern bool move_is_legal(const Position& pos, Move move);
extern bool move_is_check(const Position& pos, Move move);

extern void test_move_gen(Position& pos);
#endif // #ifndef MOVEGEN_H_INCLUDED
