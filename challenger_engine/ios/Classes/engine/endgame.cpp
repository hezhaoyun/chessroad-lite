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
#include "endgame.h"
#include "movegen.h"

using std::string;

namespace {

	//根据"KPK"这样的字符串计算hashkey,这里是取巧的一种方法  
	Key key(const string& code, Color c) {

		assert(code.length() > 0 && code.length() < 8);
		assert(code[0] == 'K');

		//根据c转换字符串，兵构造fen串，最后通过position来计算material key
		//通过这个key来映射在endgame是否个固定的子力对比
		string sides[] = { code.substr(code.find('K', 1)),      // Weaker
			code.substr(0, code.find('K', 1)) }; // Stronger

		std::transform(sides[c].begin(), sides[c].end(), sides[c].begin(), tolower);

		string fen =  sides[0] + char(9 - sides[0].length() + '0') + "/9/9/9/9/9/9/9/9/"
			+ sides[1] + char(9 - sides[1].length() + '0') + " w - - 0 10";

		return Position(fen, false, NULL).material_key();
	}

	template<typename M>
	void delete_endgame(const typename M::value_type& p) { delete p.second; }

} // namespace


/// Endgames members definitions

Endgames::Endgames() {

	//add<KPK>("KPK");
}

Endgames::~Endgames() {

	for_each(m1.begin(), m1.end(), delete_endgame<M1>);
	for_each(m2.begin(), m2.end(), delete_endgame<M2>);
}

template<EndgameType E>
void Endgames::add(const string& code) {
	//init m1 and m2
	map((Endgame<E>*)0)[key(code, WHITE)] = new Endgame<E>(WHITE);
	map((Endgame<E>*)0)[key(code, BLACK)] = new Endgame<E>(BLACK);
}

template<>
Value Endgame<KdKd>::operator()(const Position& pos) const {

	return VALUE_DRAW;
}

template<>
ScaleFactor Endgame<KdaKd>::operator()(const Position& pos) const {

	//PAWN
	//ROOK
	//KNIGHT
	//CANNON

	int sdb = pos.count<BISHOP>(strongerSide);
	int sda = pos.count<ADVISOR>(strongerSide);
	int wdb = pos.count<BISHOP>(weakerSide);
	int wda = pos.count<ADVISOR>(weakerSide);
	Square loserKSq = pos.king_square(weakerSide);

	if(pos.count<PAWN>(strongerSide) == 1)
	{
		if(wdb == 0 && wda == 0)
		{
			//单兵对单将,只要不是底线，不和
			Square psq  = pos.list<PAWN>(strongerSide)[0];
			if(rank_of(psq) == RANK_0 || rank_of(psq) == RANK_9)
			{				
				return  ScaleFactor(SCALE_FACTOR_MAX - 2 * square_distance(psq, loserKSq));
			}

			return SCALE_FACTOR_DRAW;
		}
		else
		{
			return SCALE_FACTOR_DRAW;
		}
	}
	else if(pos.count<ROOK>(strongerSide) == 1)
	{
		if(wdb == 2 && wda == 2)
		{
			return SCALE_FACTOR_DRAW;
		}
		else
		{
			return SCALE_FACTOR_MAX;
		}
	}
	else if(pos.count<KNIGHT>(strongerSide) == 1)
	{
		if(wdb + wda >= 2) return SCALE_FACTOR_DRAW;
		if(wdb + wda < 2)
		{
			return ScaleFactor(SCALE_FACTOR_MAX);
		}
	}
	else if(pos.count<CANNON>(strongerSide) == 1)
	{
		if(wdb + wda >= 2)  return SCALE_FACTOR_DRAW;
		if(sda == 0) return SCALE_FACTOR_DRAW;

		return SCALE_FACTOR_MAX;
	}	

	return SCALE_FACTOR_MAX;
}

template<>
ScaleFactor Endgame<KdaKda>::operator()(const Position& pos) const {

	int sdb = pos.count<BISHOP>(strongerSide);
	int sda = pos.count<ADVISOR>(strongerSide);
	int wdb = pos.count<BISHOP>(weakerSide);
	int wda = pos.count<ADVISOR>(weakerSide);

	//PAWN
	//ROOK
	//KNIGHT
	//CANNON
	if(pos.count<PAWN>(strongerSide) == 1)
	{
		if(pos.count<PAWN>(weakerSide) == 1)
		{  
			return SCALE_FACTOR_DRAW;
		}

	}
	else if(pos.count<ROOK>(strongerSide) == 1)
	{
		if(wdb + wda == 4)
		{   
			return SCALE_FACTOR_DRAW;
		}
		else if (pos.count<ROOK>(weakerSide) == 1)
		{
			return SCALE_FACTOR_DRAW;
		}

	}
	else if(pos.count<KNIGHT>(strongerSide) == 1)
	{
		if(pos.count<PAWN>(weakerSide) == 1)
		{   
			return SCALE_FACTOR_DRAW;
		}
		if(pos.count<KNIGHT>(weakerSide) == 1)
		{   
			return SCALE_FACTOR_DRAW;
		}
		if(pos.count<CANNON>(weakerSide) == 1)
		{
			return SCALE_FACTOR_DRAW;
		}

	}
	else if(pos.count<CANNON>(strongerSide) == 1)
	{

		if(sda == 0 || wdb + wda >= 2)
		{
			if(pos.count<ROOK>(weakerSide) != 1)
			{   
				return SCALE_FACTOR_DRAW;
			}
		}

		if(pos.count<CANNON>(weakerSide) == 1)
		{
			return SCALE_FACTOR_DRAW;
		}
	}

	return SCALE_FACTOR_NORMAL;
} 


