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

#ifndef ENDGAME_H_INCLUDED
#define ENDGAME_H_INCLUDED

#include <map>
#include <string>

#include "position.h"
#include "types.h"


//在endgame时的evaluation或者Scaling function
enum EndgameType {

  KdKd,//没有attack的子

  SCALE_FUNS,

  KdaKd,
  KdaKda,

};


/// Endgame functions can be of two types according if return a Value or a
/// ScaleFactor. Type eg_fun<int>::type equals to either ScaleFactor or Value
/// depending if the template parameter is 0 or 1.

template<int> struct eg_fun { typedef Value type; };
template<> struct eg_fun<1> { typedef ScaleFactor type; };


/// Base and derived templates for endgame evaluation and scaling functions

template<typename T>
struct EndgameBase {

  virtual ~EndgameBase() {}
  virtual Color color() const = 0;
  virtual T operator()(const Position&) const = 0;
};


template<EndgameType E, typename T = typename eg_fun<(E > SCALE_FUNS)>::type>
struct Endgame : public EndgameBase<T> {

  explicit Endgame(Color c) : strongerSide(c), weakerSide(~c) {}
  Color color() const { return strongerSide; }
  T operator()(const Position&) const;

private:
  Color strongerSide, weakerSide;
};


/// Endgames class stores in two std::map the pointers to endgame evaluation
/// and scaling base objects. Then we use polymorphism to invoke the actual
/// endgame function calling its operator() that is virtual.

class Endgames {

  typedef std::map<Key, EndgameBase<eg_fun<0>::type>*> M1;
  typedef std::map<Key, EndgameBase<eg_fun<1>::type>*> M2;

  M1 m1;
  M2 m2;

  M1& map(M1::mapped_type) { return m1; }
  M2& map(M2::mapped_type) { return m2; }

  template<EndgameType E> void add(const std::string& code);

public:
  Endgames();
 ~Endgames();

  template<typename T> T probe(Key key, T& eg)
  { return eg = map(eg).count(key) ? map(eg)[key] : NULL; }
};

#endif // #ifndef ENDGAME_H_INCLUDED
