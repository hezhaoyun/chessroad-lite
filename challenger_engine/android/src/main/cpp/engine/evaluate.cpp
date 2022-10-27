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
#include <algorithm>

#include "bitcount.h"
#include "evaluate.h"
#include "material.h"
#include "pawns.h"
#include "thread.h"
#include "ucioption.h"

namespace {

	enum ExtendedPieceType { // Used for tracing
		PST = 8, IMBALANCE, MOBILITY, THREAT, PASSED, SPACE, STRUCTURE,TOTAL
	};

	namespace Tracing {

		Score scores[COLOR_NB][TOTAL + 1];
		std::stringstream stream;

		void add(int idx, Score term_w, Score term_b = SCORE_ZERO);
		void row(const char* name, int idx);
		std::string do_trace(const Position& pos);
	}

	// Struct EvalInfo contains various information computed and collected
	// by the evaluation functions.
	struct EvalInfo {

		// Pointers to material and pawn hash table entries
		Material::Entry* mi;
		Pawns::Entry* pi;

		// attackedBy[color][piece type] is a bitboard representing all squares
		// attacked by a given color and piece type, attackedBy[color][ALL_PIECES]
		// contains all squares attacked by the given color.
		Bitboard attackedBy[COLOR_NB][PIECE_TYPE_NB];

		// kingRing[color] is the zone around the king which is considered
		// by the king safety evaluation. This consists of the squares directly
		// adjacent to the king, and the three (or two, for a king on an edge file)
		// squares two ranks in front of the king. For instance, if black's king
		// is on g8, kingRing[BLACK] is a bitboard containing the squares f8, h8,
		// f7, g7, h7, f6, g6 and h6.
		Bitboard kingRing[COLOR_NB];

		// kingAttackersCount[color] is the number of pieces of the given color
		// which attack a square in the kingRing of the enemy king.
		int kingAttackersCount[COLOR_NB];

		// kingAttackersWeight[color] is the sum of the "weight" of the pieces of the
		// given color which attack a square in the kingRing of the enemy king. The
		// weights of the individual piece types are given by the variables
		// QueenAttackWeight, RookAttackWeight, BishopAttackWeight and
		// KnightAttackWeight in evaluate.cpp
		int kingAttackersWeight[COLOR_NB];

		// kingAdjacentZoneAttacksCount[color] is the number of attacks to squares
		// directly adjacent to the king of the given color. Pieces which attack
		// more than one square are counted multiple times. For instance, if black's
		// king is on g8 and there's a white knight on g5, this knight adds
		// 2 to kingAdjacentZoneAttacksCount[BLACK].
		int kingAdjacentZoneAttacksCount[COLOR_NB];

		Bitboard pinnedPieces[COLOR_NB];
	};

	// Evaluation grain size, must be a power of 2
	const int GrainSize = 4;

	// Evaluation weights, initialized from UCI options
	enum { Mobility, PawnStructure, PassedPawns, Space, KingDangerUs, KingDangerThem, PieceStructure };
	Score Weights[7];

	typedef Value V;
#define S(mg, eg) make_score(mg, eg)

	// Internal evaluation weights. These are applied on top of the evaluation
	// weights read from UCI parameters. The purpose is to be able to change
	// the evaluation weights while keeping the default values of the UCI
	// parameters at 100, which looks prettier.

	const Score WeightsInternal[] = {
		S(289, 344), S(233, 201), S(221, 273), S(46, 0), S(271, 0), S(307, 0), S(221, 273)	  
	};

	// MobilityBonus[PieceType][attacked] contains bonuses for middle and end
	// game, indexed by piece type and number of attacked squares not occupied by
	// friendly pieces.
	//PAWN, BISHOP, ADVISOR, KNIGHT, CANNON, ROOK, KING
	Score MobilityBonus[][32] = {
		{}, {},//Pawn
		{ S( 0, 0), S( 0,  0 ), S( 0,  0), S(0, 0),   S(0, 0)},// Bishops
		{ S( 0, 0), S( 0,  0 ), S( 0,  0), S(0, 0),   S(0, 0)},// Advisor
		{ S(-35,-30), S(-30,-25), S(-20,-20), S( 0,  0), S(10, 10), S(15, 15),S( 20, 20), S( 25, 25), S(25, 25) },//knight
		{ S( -10, -10), S( 2,  4), S( 4,  4), S(6, 6), S(8, 8),S(10, 10),S(12, 12),S(12, 12),S(12, 12),S(12, 12),S(12, 12),S(12, 12),S(12, 12),S(12, 12),S(12, 12),S(12, 12),S(12, 12),S(12, 12)},// Cannon
		{ S(-20,-20), S(-18,-18), S(-16,-16), S( -10,-10), S( -8,-8), S(-4,-4),S( 0, 0), S( 4, 2), S(8, 4), S(12,6), S(16,8), S(20,10),S( 24,12), S( 24,12), S(24,12), S(24,12), S(24,12), S(24,12)}, // Rooks 
	};

	// Outpost[PieceType][Square] contains bonuses of knights and bishops, indexed
	// by piece type and square (from white's point of view).
	const Value Outpost[][SQUARE_NB] = {
		{
			//  A     B     C     D     E     F     G     H    I
			V(0), V(0), V(0), V(0), V(0), V(0),  V(0), V(0),  V(0),
				V(0), V(0), V(0), V(0), V(0), V(0),  V(0), V(0),  V(0),
				V(0), V(0), V(15),V(0), V(0), V(0),  V(15), V(0),  V(0),
				V(0), V(0), V(0), V(0), V(15),V(0),  V(0), V(0), V(0),
				V(0),V(15), V(15),V(15),V(15),V(15), V(15),V(15), V(0),


				V(0), V(15), V(8), V(15),V(15),V(15),V(8), V(15),  V(0),
				V(0), V(15),V(15),V(15),V(15), V(15),V(15),V(15), V(0),
				V(0), V(0), V(12),V(0), V(0), V(0), V(12),V(0),  V(0),
				V(0), V(0), V(15), V(0), V(0), V(0), V(15), V(0),  V(0),
				V(0), V(0), V(0), V(0), V(0), V(0), V(0), V(0),  V(0), 
		}
	};

	const Value AttackEnergy[]={
		//  A     B     C     D     E     F     G     H    I
		V(0), V(0), V(0), V(0), V(0), V(0), V(0), V(0),  V(0), 
		V(0), V(0), V(0), V(0), V(0), V(0), V(0), V(0),  V(0),
		V(0), V(0), V(0), V(0), V(0), V(0), V(0), V(0),  V(0),
		V(0), V(0), V(0), V(0), V(0), V(0), V(0), V(0),  V(0),
		V(0), V(0), V(0), V(0), V(0), V(0), V(0), V(0),  V(0),

		V(0), V(1), V(1), V(1), V(2), V(1),  V(1), V(1),  V(0),
		V(0), V(1), V(1), V(2), V(3), V(2),  V(1), V(1),  V(0),
		V(0), V(1), V(2), V(3), V(4), V(3),  V(2), V(1),  V(0),
		V(0), V(2), V(3), V(4), V(5), V(4),  V(3), V(2),  V(0),
		V(1), V(2), V(4), V(5), V(6), V(5),  V(4), V(2),  V(1),
	};
	const int AttackEnergyWeight[]={ 0, 3, 0, 0, 2, 2, 1};


	// Threat[attacking][attacked] contains bonuses according to which piece
	// type attacks which one.
	const Score Threat[][PIECE_TYPE_NB] = {
		//NONE     PAWN        BISHOP    ADVISOR    KNIGHT     CANNON     ROOK
		{ S(0, 0), S( 7, 7), S(24, 49), S(24, 49), S(41,100), S(41,100), S(41,100)}, // Minor
		{ S(0, 0), S( 7, 7), S(15, 15), S(15, 15), S(35, 35), S(15, 35), S(24, 49)}  // Major
	};

	// Hanging[side to move] contains a bonus for each enemy hanging piece
	const Score Hanging[2] = { S(10, 20) , S(15, 25) };

	// ThreatenedByPawn[PieceType] contains a penalty according to which piece
	// type is attacked by an enemy pawn.
	const Score ThreatenedByPawn[] = {
		//NONE   //PAWN     //BISHOP   //ADVISOR  //KNIGHT   //CANNON   //ROOK
		S(0, 0), S(0, 0), S(10, 10), S(15, 15),   S(26, 29), S(6, 9), S(0, 0)
	};

	//空头炮
	const Score ShortGunDistance[] = {S(0, 0), S(0, 0),S(0, 0), S(2, 2),S(4, 4), S(6, 6),S(8, 8), S(10, 10),S(10, 10), S(10, 10)};
	const int   ShortGunPieceCount[] = {0, 0, 0, 0, 10, 8, 15, 0};

#undef S

	const Score Tempo            = make_score(24, 11);

	Score RookPin          = make_score(26, 31);
	Score CannonPin        = make_score(26, 21);

	Score RookOnPawn       = make_score(10, 18);
	Score RookOpenFile     = make_score(53, 0);

	Score RookPinRook      = make_score(50, 50);

	Score CannonPinRook    = make_score(10, 5);
	Score CannonPinKnight  = make_score(10, 10);
	Score CannonPinBishop  = make_score(2, 0);

	Score KnightLegPawn    = make_score(16,  0);

	//////////////////////////////////////////////////////////////////////////

	// The SpaceMask[Color] contains the area of the board which is considered
	// by the space evaluation. In the middle game, each side is given a bonus
	// based on how many squares inside this area are safe and available for
	// friendly minor pieces.
	const Bitboard SpaceMask[] = {
		(FileCBB | FileDBB | FileEBB | FileFBB | FileGBB) & (Rank0BB |Rank1BB |Rank2BB | Rank3BB | Rank4BB | Rank5BB | Rank6BB),
		(FileCBB | FileDBB | FileEBB | FileFBB | FileGBB) & (Rank9BB |Rank8BB |Rank7BB | Rank6BB | Rank5BB | Rank4BB | Rank3BB)
	};

	// King danger constants and variables. The king danger scores are taken
	// from the KingDanger[]. Various little "meta-bonuses" measuring
	// the strength of the enemy attack are added up into an integer, which
	// is used as an index to KingDanger[].
	//
	// KingAttackWeights[PieceType] contains king attack weights by piece type
	//NONE   //PAWN     //BISHOP   //ADVISOR  //KNIGHT   //CANNON   //ROOK
	const int KingAttackWeights[] = { 0, 2, 0, 0, 1, 1, 2 };

	// Bonuses for enemy's safe checks
	const int RookContactCheck  = 6;
	const int RookCheck         = 6;
	const int KnightCheck       = 3;
	const int CannonCheck       = 3;
	const int PawnCheck         = 6;

	// KingExposed[Square] contains penalties based on the position of the
	// defending king, indexed by king's square (from white's point of view).
	const int KingExposed[] = {
		0,  0,  0,  0,  0,  0,  0,  0,  0,
		0,  0,  0,  0,  0,  0,  0,  0,  0,
		0,  0,  0,  0,  0,  0,  0,  0,  0,
		0,  0,  0,  0,  0,  0,  0,  0,  0,
		0,  0,  0,  0,  0,  0,  0,  0,  0,
		0,  0,  0,  0,  0,  0,  0,  0,  0,
		0,  0,  0,  0,  0,  0,  0,  0,  0,
		0,  0,  0,  4,  4,  4,  0,  0,  0,
		0,  0,  0,  2,  2,  2,  0,  0,  0,
		0,  0,  0,  0,  0,  0,  0,  0,  0
	};

	// KingDanger[Color][attackUnits] contains the actual king danger weighted
	// scores, indexed by color and by a calculated integer number.
	Score KingDanger[COLOR_NB][128];

	// Function prototypes
	template<bool Trace>
	Value do_evaluate(const Position& pos, Value& margin);

	template<Color Us>
	void init_eval_info(const Position& pos, EvalInfo& ei);

	template<Color Us, bool Trace>
	Score evaluate_pieces_of_color(const Position& pos, EvalInfo& ei, Score& mobility);

	template<Color Us, bool Trace>
	Score evaluate_king(const Position& pos, const EvalInfo& ei, Value margins[]);

	template<Color Us, bool Trace>
	Score evaluate_threats(const Position& pos, const EvalInfo& ei);

	template<Color Us, bool Trace>
	Score evaluate_passed_pawns(const Position& pos, const EvalInfo& ei);

	template<Color Us>
	int evaluate_space(const Position& pos, const EvalInfo& ei);  

	template<Color Us, bool Trace>
	Score evaluate_structure(const Position& pos, const EvalInfo& ei) ;
	template<PieceType Piece,Color Us, bool Trace>
	Score evaluate_piece_structure(const Position& pos, const EvalInfo& ei);

	Value interpolate(const Score& v, Phase ph, ScaleFactor sf);
	Score apply_weight(Score v, Score w);
	Score weight_option(const std::string& mgOpt, const std::string& egOpt, Score internalWeight);
	double to_cp(Value v);
}


namespace Eval {

	/// evaluate() is the main evaluation function. It always computes two
	/// values, an endgame score and a middle game score, and interpolates
	/// between them based on the remaining material.

	Value evaluate(const Position& pos, Value& margin) {
		return do_evaluate<false>(pos, margin);
	}


	/// trace() is like evaluate() but instead of a value returns a string suitable
	/// to be print on stdout with the detailed descriptions and values of each
	/// evaluation term. Used mainly for debugging.
	std::string trace(const Position& pos) {
		return Tracing::do_trace(pos);
	}


	/// init() computes evaluation weights from the corresponding UCI parameters
	/// and setup king tables.

	void init() {

		Weights[Mobility]       = weight_option("Mobility (Midgame)", "Mobility (Endgame)", WeightsInternal[Mobility]);
		Weights[PawnStructure]  = weight_option("Pawn Structure (Midgame)", "Pawn Structure (Endgame)", WeightsInternal[PawnStructure]);
		Weights[PassedPawns]    = weight_option("Passed Pawns (Midgame)", "Passed Pawns (Endgame)", WeightsInternal[PassedPawns]);
		Weights[Space]          = weight_option("Space", "Space", WeightsInternal[Space]);
		Weights[KingDangerUs]   = weight_option("Cowardice", "Cowardice", WeightsInternal[KingDangerUs]);
		Weights[KingDangerThem] = weight_option("Aggressiveness", "Aggressiveness", WeightsInternal[KingDangerThem]);
		Weights[PieceStructure] = weight_option("Piece Structure", "Piece Structure", WeightsInternal[PieceStructure]);

		const int MaxSlope = 30;
		const int Peak = 1280;

		for (int t = 0, i = 1; i < 100; ++i)
		{
			t = std::min(Peak, std::min(int(0.4 * i * i), t + MaxSlope));		

			KingDanger[1][i] = apply_weight(make_score(t, 0), Weights[KingDangerUs]);
			KingDanger[0][i] = apply_weight(make_score(t, 0), Weights[KingDangerThem]);
		}
	}

	void init_variables()
	{
		for (int pt1 = KNIGHT; pt1 <= ROOK; ++pt1)
		{
			for (int c = 0; c <= 17; ++c)
			{
				int m = 0;
				int e = 0;

				char buf[256] = {0};
				char text[1024]={0};

				sprintf(buf, "MobilityBonusM[%d][%d]",pt1,c);
				m = (int)Options[buf];

				sprintf(buf, "MobilityBonusE[%d][%d]",pt1,c);
				e = (int)Options[buf];

				MobilityBonus[pt1][c] = make_score(m, e);

			}
		}

		{

#define GEN_CODE(namem,namee,gdata) {int m = (int)Options[namem];int e = (int)Options[namee];gdata = make_score(m, e);}

			GEN_CODE("RookPinM","RookPinE", RookPin);
			GEN_CODE("CannonPinM","CannonPinE", CannonPin);
			GEN_CODE("RookOnPawnM","RookOnPawnE", RookOnPawn);
			GEN_CODE("RookOpenFileM","RookOpenFileE", RookOpenFile);
			GEN_CODE("RookPinRookM","RookPinRookE", RookPinRook);
			GEN_CODE("CannonPinRookM","CannonPinRookE", CannonPinRook);
			GEN_CODE("CannonPinKnightM","CannonPinKnightE", CannonPinKnight);
			GEN_CODE("CannonPinBishopM","CannonPinBishopE", CannonPinBishop);
			GEN_CODE("KnightLegPawnM","KnightLegPawnE", KnightLegPawn);


		}
	}

} // namespace Eval


namespace {

	template<bool Trace>
	Value do_evaluate(const Position& pos, Value& margin) {

		//assert(!pos.checkers());//for do_eval when begin search

		EvalInfo ei;
		Value margins[COLOR_NB];
		Score score, mobilityWhite, mobilityBlack;
		Thread* th = pos.this_thread();

		// margins[] store the uncertainty estimation of position's evaluation
		// that typically is used by the search for pruning decisions.
		margins[WHITE] = margins[BLACK] = VALUE_ZERO;

		// Initialize score by reading the incrementally updated scores included
		// in the position object (material + piece square tables) and adding
		// Tempo bonus. Score is computed from the point of view of white.
		score = pos.psq_score() + (pos.side_to_move() == WHITE ? Tempo : -Tempo);

		// Probe the material hash table
		ei.mi = Material::probe(pos, th->materialTable, th->endgames);
		score += ei.mi->material_value();


		// If we have a specialized evaluation function for the current material
		// configuration, call it and return.
		if (ei.mi->specialized_eval_exists())
		{
			margin = VALUE_ZERO;
			return ei.mi->evaluate(pos);
		}

		// Probe the pawn hash table
		ei.pi = Pawns::probe(pos, th->pawnsTable);
		score += apply_weight(ei.pi->pawns_value(), Weights[PawnStructure]);


		// Initialize attack and king safety bitboards
		init_eval_info<WHITE>(pos, ei);
		init_eval_info<BLACK>(pos, ei);

		// Evaluate pieces and mobility
		score +=  evaluate_pieces_of_color<WHITE, Trace>(pos, ei, mobilityWhite)
			- evaluate_pieces_of_color<BLACK, Trace>(pos, ei, mobilityBlack);

		score += apply_weight(mobilityWhite - mobilityBlack, Weights[Mobility]);


		// Evaluate kings after all other pieces because we need complete attack
		// information when computing the king safety evaluation.
		score +=  evaluate_king<WHITE, Trace>(pos, ei, margins)
			- evaluate_king<BLACK, Trace>(pos, ei, margins);


		// Evaluate tactical threats, we need full attack information including king
		score +=  evaluate_threats<WHITE, Trace>(pos, ei)
			- evaluate_threats<BLACK, Trace>(pos, ei);


		// Evaluate passed pawns, we need full attack information including king
		score +=  evaluate_passed_pawns<WHITE, Trace>(pos, ei)
			- evaluate_passed_pawns<BLACK, Trace>(pos, ei);

		// Evaluate space for both sides, only in middle-game.
		if (ei.mi->space_weight())
		{
			int s = evaluate_space<WHITE>(pos, ei) - evaluate_space<BLACK>(pos, ei);
			score += apply_weight(s * ei.mi->space_weight(), Weights[Space]);
		}


		// Evaluate piece structure for both sides,
		score +=  evaluate_structure<WHITE, Trace>(pos, ei) - evaluate_structure<BLACK, Trace>(pos, ei);

		// Scale winning side if position is more drawish that what it appears
		ScaleFactor sf = eg_value(score) > VALUE_DRAW ? ei.mi->scale_factor(pos, WHITE)
			: ei.mi->scale_factor(pos, BLACK); 

		margin = margins[pos.side_to_move()];
		Value v = interpolate(score, ei.mi->game_phase(), sf);

		// In case of tracing add all single evaluation contributions for both white and black
		if (Trace)
		{
			Tracing::add(PST, pos.psq_score());
			Tracing::add(IMBALANCE, ei.mi->material_value());
			Tracing::add(PAWN, ei.pi->pawns_value());
			Score w = ei.mi->space_weight() * evaluate_space<WHITE>(pos, ei);
			Score b = ei.mi->space_weight() * evaluate_space<BLACK>(pos, ei);
			Tracing::add(SPACE, apply_weight(w, Weights[Space]), apply_weight(b, Weights[Space]));
			Tracing::add(TOTAL, score);
			Tracing::stream << "\nUncertainty margin: White: " << to_cp(margins[WHITE])
				<< ", Black: " << to_cp(margins[BLACK])
				<< "\nScaling: " << std::noshowpos
				<< std::setw(6) << 100.0 * ei.mi->game_phase() / 128.0 << "% MG, "
				<< std::setw(6) << 100.0 * (1.0 - ei.mi->game_phase() / 128.0) << "% * "
				<< std::setw(6) << (100.0 * sf) / SCALE_FACTOR_NORMAL << "% EG.\n"
				<< "Total evaluation: " << to_cp(v);
		}


		return pos.side_to_move() == WHITE ? v : -v;
	}


	// init_eval_info() initializes king bitboards for given color adding
	// pawn attacks. To be done at the beginning of the evaluation.

	template<Color Us>
	void init_eval_info(const Position& pos, EvalInfo& ei) {

		const Color  Them = (Us == WHITE ? BLACK : WHITE);
		const Square Down = (Us == WHITE ? DELTA_S : DELTA_N);
		const Square Up    = (Us == WHITE ? DELTA_N  : DELTA_S);
		const Square Right = (Us == WHITE ? DELTA_E : DELTA_W);
		const Square Left  = (Us == WHITE ? DELTA_W : DELTA_E);


		Square ksq = pos.king_square(Them);

		ei.pinnedPieces[Us] = pos.pinned_pieces();

		ei.attackedBy[Them][KING] = pos.attacks_from<KING>(ksq,Them);
		ei.attackedBy[Us][ALL_PIECES] = ei.attackedBy[Us][PAWN] = ei.pi->pawn_attacks(Us);

		//attacks_from<KING> can only calc sq in city
		Bitboard b = (shift_bb<Right>(SquareBB[ksq]) | shift_bb<Left>(SquareBB[ksq])|shift_bb<Up>(SquareBB[ksq])|shift_bb<Down>(SquareBB[ksq]));

		// Init king safety tables only if we are going to use them
		ei.kingRing[Them] = b | shift_bb<Down>(b)/*|shift_bb<Right>(b)|shift_bb<Left>(b)|shift_bb<Up>(b)*/;
		b &= ei.attackedBy[Us][PAWN];
		ei.kingAttackersCount[Us] = b ? popcount<CNT_90>(b): 0;
		ei.kingAdjacentZoneAttacksCount[Us] = ei.kingAttackersWeight[Us] = 0;

	}


	// evaluate_outposts() evaluates bishop and knight outposts squares

	template<PieceType Piece, Color Us>
	Score evaluate_outposts(const Position& pos, EvalInfo& ei, Square s) {

		const Color Them = (Us == WHITE ? BLACK : WHITE);

		assert (Piece == KNIGHT);

		// Initial bonus based on square
		Value bonus = Outpost[0][relative_square(Us, s)];

		//不能被对方pawn攻击，否则不计分
		if (bonus && (!ei.attackedBy[Them][PAWN] & s))
		{
			if (!(ei.attackedBy[Them][BISHOP] & s) &&
				!(ei.attackedBy[Them][ADVISOR] & s))
			{

				if (!(ei.attackedBy[Them][CANNON] & s) &&
					!(ei.attackedBy[Them][KNIGHT] & s))
				{
					if ((ei.attackedBy[Us][ROOK] & s) ||
						(ei.attackedBy[Us][KNIGHT] & s) ||
						(ei.attackedBy[Us][CANNON] & s) ||
						(ei.attackedBy[Us][PAWN] & s))
					{
						bonus += bonus ;
					}
					else if (!(ei.attackedBy[Them][ROOK] & s))
					{
						bonus += bonus;
					}				
				}
				else
				{
					if (ei.attackedBy[Us][PAWN] & s)
					{
						bonus += bonus/2;
					}
					else if ((ei.attackedBy[Us][KNIGHT] & s) ||
						(ei.attackedBy[Us][CANNON] & s))
					{
						bonus += bonus/4;
					}
				}
			}
		}

		return make_score(bonus, bonus);
	}


	// evaluate_pieces<>() assigns bonuses and penalties to the pieces of a given color

	template<PieceType Piece, Color Us, bool Trace>
	Score evaluate_pieces(const Position& pos, EvalInfo& ei, Score& mobility, Bitboard mobilityArea) {

		Bitboard b;
		Square s;
		Score score = SCORE_ZERO;

		const Color Them = (Us == WHITE ? BLACK : WHITE);
		const Square* pl = pos.list<Piece>(Us);

		ei.attackedBy[Us][Piece] = Bitboard();

		//Bitboard occ, occl90;

		//occ    = pos.pieces();
		//occl90 = pos.piecesl90();

		while ((s = *pl++) != SQ_NONE)
		{
			if(Piece ==  ROOK)
				b = pos.attacks_from<ROOK>(s);
			else if(Piece ==  CANNON)
				b = pos.attacks_from<CANNON>(s);
			else if(Piece ==  KNIGHT)
				b = pos.attacks_from<KNIGHT>(s);
			else if(Piece ==  BISHOP)
				b = pos.attacks_from<BISHOP>(s, Us);
			else if(Piece == ADVISOR)
				b = pos.attacks_from<ADVISOR>(s, Us);
			else if(Piece == KING)
				b = pos.attacks_from<KING>(s, Us);
			else if(Piece == PAWN)
				b = pos.attacks_from<PAWN>(s, Us);

			if (ei.pinnedPieces[Us] & s)
			{
				if(file_of(s) == file_of(pos.king_square(Us)))
			 {
				 b &= FileBB[file_of(s)];
			 }

				if (rank_of(s) == rank_of(pos.king_square(Us)))
			 {
				 b &= RankBB[rank_of(s)];
			 }

			}

			ei.attackedBy[Us][Piece] |= b;

			if (b & ei.kingRing[Them])
			{
				ei.kingAttackersCount[Us]++;
				ei.kingAttackersWeight[Us] += KingAttackWeights[Piece];
				Bitboard bb = (b & ei.attackedBy[Them][KING]);
				if (bb)
					ei.kingAdjacentZoneAttacksCount[Us] += popcount<CNT_90>(bb);
			}

			int mob = popcount<CNT_90>(b & mobilityArea);			

			mobility += MobilityBonus[Piece][mob];

			// Decrease score if we are attacked by an enemy pawn. Remaining part
			// of threat evaluation must be done later when we have full attack info.
			if (ei.attackedBy[Them][PAWN] & s)
			{
				score -= ThreatenedByPawn[Piece];
			}

			// Otherwise give a bonus if we can pin a piece or can
			// give a discovered check through an x-ray attack.
			else if ( Piece == ROOK)
			{         
				//牵制对方的king
				if ((PseudoAttacks[Piece][pos.king_square(Them)] & s) && !more_than_one(BetweenBB[s][pos.king_square(Them)] & pos.pieces()))
				{
					score += RookPin;
				}

				//牵制对方的ROOK
				if (cannon_control_bb(s, pos.occupied, pos.occupied_rl90) & pos.pieces(Them, ROOK))
				{
					score += RookPinRook;
				}

				//在卒林线
				if (relative_rank(Us, s) >= RANK_5)
				{
					// Major piece attacking enemy pawns on the same rank/file
					Bitboard pawns = pos.pieces(Them, PAWN) & PseudoAttacks[ROOK][s];
					if (pawns)
						score += popcount<CNT_90>(pawns) * (RookOnPawn);
				}

				//通路车
				if (popcount<CNT_90>(FileBB[file_of(s)] & b) > 4)
				{
					score += RookOpenFile;
				}			

			}
			//炮的牵制
			else if( Piece == CANNON)
			{

				//炮的牵制king 
				if((PseudoAttacks[Piece][pos.king_square(Them)] & s))
				{
					Bitboard pin = BetweenBB[s][pos.king_square(Them)] & pos.pieces();
					if(equal_to_two(pin))
					{
						score += CannonPin;
					}
					if (!pin)//空头炮
					{
						if(pos.count<ROOK>(Us) + pos.count<CANNON>(Us) + pos.count<KNIGHT>(Us) > 0)
						{
							score += ShortGunDistance[ std::max( file_distance(s,pos.king_square(Them)), rank_distance(s,pos.king_square(Them))) ];

							int bonus = ShortGunPieceCount[ROOK]*pos.count<ROOK>(Us) + ShortGunPieceCount[CANNON]*pos.count<ROOK>(Us) + ShortGunPieceCount[CANNON]*pos.count<ROOK>(Us);					
							score += make_score(bonus,bonus);
						}
					}
				}

				Bitboard pin = cannon_supper_pin_bb(s, pos.occupied, pos.occupied_rl90);
				//炮牵制车
				if (pin & pos.pieces(Them, ROOK))
				{
					score += CannonPinRook;
				}

				//炮牵制马
				if (pin & pos.pieces(Them, KNIGHT))
				{
					score += CannonPinKnight;
				}
				//炮牵制相
				if (pin & pos.pieces(Them, BISHOP))
				{
					score += CannonPinBishop;
				}

			}
			else if (Piece == KNIGHT)
			{
				//不被对方pawn威胁
				//knight outposts squares			
				if(  !(pos.pieces(Them, PAWN)&(s + pawn_push(Us) )) )				
				{
					score += evaluate_outposts<Piece, Us>(pos, ei, s);
				}

				// Bishop or knight behind a pawn
				if (    relative_rank(Us, s) < RANK_5
					&& (pos.pieces(PAWN) & (s + pawn_push(Us))))
				{	
					score -= KnightLegPawn;//我方兵把马腿憋住了，所以要减去
				}

				//Traped
			}

		}

		if (Trace)
			Tracing::scores[Us][Piece] = score;

		return score;
	}


	// evaluate_threats<>() assigns bonuses according to the type of attacking piece
	// and the type of attacked one.

	template<Color Us, bool Trace>
	Score evaluate_threats(const Position& pos, const EvalInfo& ei) {

		const Color Them = (Us == WHITE ? BLACK : WHITE);

		Bitboard b, weakEnemies;
		Score score = SCORE_ZERO;

		// Enemy pieces not defended by a pawn and under our attack
		weakEnemies =  pos.pieces(Them)
			& ~ei.attackedBy[Them][PAWN]
		& ei.attackedBy[Us][ALL_PIECES];

		// Add bonus according to type of attacked enemy piece and to the
		// type of attacking piece, from knights to queens. Kings are not
		// considered because are already handled in king evaluation.
		if (weakEnemies)
		{

			b = weakEnemies & (ei.attackedBy[Us][PAWN] | ei.attackedBy[Us][ADVISOR] | ei.attackedBy[Us][BISHOP]);
			if (b)
				score += Threat[0][type_of(pos.piece_on(lsb(b)))];

			b = weakEnemies & (ei.attackedBy[Us][ROOK] | ei.attackedBy[Us][KNIGHT]| ei.attackedBy[Us][CANNON]);
			if (b)
				score += Threat[1][type_of(pos.piece_on(lsb(b)))];

			b = weakEnemies & ~ei.attackedBy[Them][ALL_PIECES];
			if (b)
				score += more_than_one(b) ? Hanging[Us != pos.side_to_move()] * popcount<CNT_90>(b)
				: Hanging[Us == pos.side_to_move()];
		}

		if (Trace)
			Tracing::scores[Us][THREAT] = score;

		return score;
	}


	// evaluate_pieces_of_color<>() assigns bonuses and penalties to all the
	// pieces of a given color.

	template<Color Us, bool Trace>
	Score evaluate_pieces_of_color(const Position& pos, EvalInfo& ei, Score& mobility) {

		const Color Them = (Us == WHITE ? BLACK : WHITE);

		Score score = mobility = SCORE_ZERO;

		// Do not include in mobility squares protected by enemy pawns or occupied by our pieces
		const Bitboard mobilityArea = ~(ei.attackedBy[Them][PAWN] | pos.pieces(Us));

		score += evaluate_pieces<BISHOP, Us, Trace>(pos, ei, mobility, mobilityArea);
		score += evaluate_pieces<ADVISOR, Us, Trace>(pos, ei, mobility, mobilityArea);   
		score += evaluate_pieces<CANNON, Us, Trace>(pos, ei, mobility, mobilityArea);
		score += evaluate_pieces<ROOK,   Us, Trace>(pos, ei, mobility, mobilityArea);
		score += evaluate_pieces<KNIGHT, Us, Trace>(pos, ei, mobility, mobilityArea);

		// Sum up all attacked squares
		ei.attackedBy[Us][ALL_PIECES] =   ei.attackedBy[Us][PAWN]   | ei.attackedBy[Us][KNIGHT]
		| ei.attackedBy[Us][BISHOP] |  ei.attackedBy[Us][ADVISOR] 
		| ei.attackedBy[Us][ROOK]   | ei.attackedBy[Us][CANNON]
		| ei.attackedBy[Us][KING];
		if (Trace)
			Tracing::scores[Us][MOBILITY] = apply_weight(mobility, Weights[Mobility]);

		return score;
	}


	// evaluate_king<>() assigns bonuses and penalties to a king of a given color

	template<Color Us, bool Trace>
	Score evaluate_king(const Position& pos, const EvalInfo& ei, Value margins[]) {

		const Color Them = (Us == WHITE ? BLACK : WHITE);

		Bitboard undefended, b, b1, b2, safe;
		int attackUnits;
		const Square ksq = pos.king_square(Us);

		Score score = make_score(0,0);

		// King safety. This is quite complicated, and is almost certainly far
		// from optimally tuned.
		if (   ei.kingAttackersCount[Them] >= 2
			&& ei.kingAdjacentZoneAttacksCount[Them])
		{
			// Find the attacked squares around the king which has no defenders
			// apart from the king itself
			undefended = ei.attackedBy[Them][ALL_PIECES] & ei.attackedBy[Us][KING];
			undefended &= ~(  ei.attackedBy[Us][PAWN]   | ei.attackedBy[Us][KNIGHT]
			| ei.attackedBy[Us][BISHOP] | ei.attackedBy[Us][ROOK]
			| ei.attackedBy[Us][CANNON] | ei.attackedBy[Us][ADVISOR]);

			// Initialize the 'attackUnits' variable, which is used later on as an
			// index to the KingDanger[] array. The initial value is based on the
			// number and types of the enemy's attacking pieces, the number of
			// attacked and undefended squares around our king, the square of the
			// king, and the quality of the pawn shelter.
			attackUnits =  std::min(10, (ei.kingAttackersCount[Them] * ei.kingAttackersWeight[Them]) / 2)
				+ 3 * (ei.kingAdjacentZoneAttacksCount[Them] + popcount<CNT_90>(undefended))
				+ KingExposed[relative_square(Us, ksq)]
			- mg_value(score) / 32;

			// Analyse enemy's safe rook contact checks. First find undefended
			// squares around the king attacked by enemy rooks...
			b = undefended & ei.attackedBy[Them][ROOK] & ~pos.pieces(Them);

			// Consider only squares where the enemy rook gives check
			b &= PseudoAttacks[ROOK][ksq];

			if (b)
			{
				// ...then remove squares not supported by another enemy piece
				b &= (  ei.attackedBy[Them][PAWN]   | ei.attackedBy[Them][KNIGHT]
				| ei.attackedBy[Them][BISHOP] | ei.attackedBy[Them][ADVISOR]| ei.attackedBy[Them][CANNON]);
				if (b)
					attackUnits +=  RookContactCheck
					* popcount<CNT_90>(b)
					* (Them == pos.side_to_move() ? 2 : 1);
			}

			// Analyse enemy's safe distance checks for sliders and knights
			safe = ~(pos.pieces(Them) | ei.attackedBy[Us][ALL_PIECES]);

			b1 = pos.attacks_from<ROOK>(ksq) & safe;
			b2 = pos.attacks_from<CANNON>(ksq) & safe;

			// Enemy rooks safe checks
			b = b1 & ei.attackedBy[Them][ROOK];
			if (b)
				attackUnits += RookCheck * popcount<CNT_90>(b);

			// Enemy cannons safe checks
			b = b2 & ei.attackedBy[Them][CANNON];
			if (b)
				attackUnits += CannonCheck * popcount<CNT_90>(b);

			// Enemy knights safe checks
			b = pos.attacks_from<KNIGHT>(ksq) & ei.attackedBy[Them][KNIGHT] & safe;
			if (b)
				attackUnits += KnightCheck * popcount<CNT_90>(b);

			b = pos.attacks_from_pawn_nomask(ksq, Us) & ei.attackedBy[Them][PAWN] & safe;
			if (b)
				attackUnits += PawnCheck * popcount<CNT_90>(b);


			// To index KingDanger[] attackUnits must be in [0, 99] range
			attackUnits = std::min(99, std::max(0, attackUnits));

			// Finally, extract the king danger score from the KingDanger[]
			// array and subtract the score from evaluation. Set also margins[]
			// value that will be used for pruning because this value can sometimes
			// be very big, and so capturing a single attacking piece can therefore
			// result in a score change far bigger than the value of the captured piece.
			score -= KingDanger[Us == Search::RootColor][attackUnits];
			margins[Us] += mg_value(KingDanger[Us == Search::RootColor][attackUnits]);
		}

		if (Trace)
			Tracing::scores[Us][KING] = score;

		return score;
	}

	// evaluate_passed_pawns<>() evaluates the passed pawns of the given color

	template<PieceType Piece,Color Us, bool Trace>
	Score evaluate_piece_structure(const Position& pos, const EvalInfo& ei) {

		Value v = VALUE_ZERO;

		Bitboard b = ei.attackedBy[Us][Piece];

		while(b){
			v += AttackEnergy[relative_square(Us, pop_lsb(&b))];
		}
		v = v*AttackEnergyWeight[Piece];

		Score score= make_score(v, v);

		return score;    

	}

	template<Color Us, bool Trace>
	Score evaluate_structure(const Position& pos, const EvalInfo& ei) 
	{
		Score score = SCORE_ZERO;

		score =  evaluate_piece_structure<ROOK, Us, Trace>(pos, ei) 
			+ evaluate_piece_structure<CANNON, Us, Trace>(pos, ei)
			+ evaluate_piece_structure<KNIGHT, Us, Trace>(pos, ei)
			+ evaluate_piece_structure<PAWN, Us, Trace>(pos, ei);

		if (Trace)
			Tracing::scores[Us][STRUCTURE] = score;

		return apply_weight(score, Weights[PieceStructure]);  
	}
	// evaluate_passed_pawns<>() evaluates the passed pawns of the given color

	template<Color Us, bool Trace>
	Score evaluate_passed_pawns(const Position& pos, const EvalInfo& ei) {

		const Color Them = (Us == WHITE ? BLACK : WHITE);

		Bitboard b, squaresToQueen, defendedSquares, unsafeSquares, supportingPawns;
		Score score = SCORE_ZERO;

		b = ei.pi->passed_pawns(Us);

		while (b)
		{
			Square s = pop_lsb(&b);

			//assert(pos.pawn_is_passed(Us, s));
			int d = 10 -std::max(file_distance(s, pos.king_square(Them)) , rank_distance(s, pos.king_square(Them)));

			if(relative_rank(Us, s) == RANK_9)
			{
				d = 0;				
			}

			// Base bonus based on rank
			Value mbonus = Value(d);
			Value ebonus = Value(2*d);

			// Increase the bonus if the passed pawn is supported by a friendly pawn
			// on the same rank and a bit smaller if it's on the previous rank.
			supportingPawns = pos.pieces(Us, PAWN) & adjacent_files_bb(file_of(s));
			if (supportingPawns & rank_bb(s))
				ebonus += Value(d * 2);

			else if (supportingPawns & rank_bb(s - pawn_push(Us)))
				ebonus += Value(d);


			//ebonus -= Value(d*2)*pos.count<ADVISOR>(Them);

			if (pos.count<ALL_PIECES>(  Us) - pos.count<PAWN>(  Us) - pos.count<BISHOP>(  Us) - pos.count<ADVISOR>(  Us)<
				pos.count<ALL_PIECES>(Them) - pos.count<PAWN>(Them) - pos.count<BISHOP>(Them) - pos.count<ADVISOR>(Them))
				ebonus += ebonus / 4;

			score += make_score(mbonus, ebonus);

		}

		if (Trace)
			Tracing::scores[Us][PASSED] = apply_weight(score, Weights[PassedPawns]);

		// Add the scores to the middle game and endgame eval
		return apply_weight(score, Weights[PassedPawns]);
	}

	// evaluate_space() computes the space evaluation for a given side. The
	// space evaluation is a simple bonus based on the number of safe squares
	// available for minor pieces on the central four files on ranks 2--4. Safe
	// squares one, two or three squares behind a friendly pawn are counted
	// twice. Finally, the space bonus is scaled by a weight taken from the
	// material hash table. The aim is to improve play on game opening.
	template<Color Us>
	int evaluate_space(const Position& pos, const EvalInfo& ei) {

		const Color Them = (Us == WHITE ? BLACK : WHITE);

		// Find the safe squares for our pieces inside the area defined by
		// SpaceMask[]. A square is unsafe if it is attacked by an enemy
		// pawn, or if it is undefended and attacked by an enemy piece.
		Bitboard safe =   SpaceMask[Us]
		& ~pos.pieces(Us, PAWN)
			& ~ei.attackedBy[Them][PAWN]
		& (ei.attackedBy[Us][ALL_PIECES] | ~ei.attackedBy[Them][ALL_PIECES]);

		return popcount<CNT_90>(safe);
	}




	// interpolate() interpolates between a middle game and an endgame score,
	// based on game phase. It also scales the return value by a ScaleFactor array.

	Value interpolate(const Score& v, Phase ph, ScaleFactor sf) {

		assert(mg_value(v) > -VALUE_INFINITE && mg_value(v) < VALUE_INFINITE);
		assert(eg_value(v) > -VALUE_INFINITE && eg_value(v) < VALUE_INFINITE);
		assert(ph >= PHASE_ENDGAME && ph <= PHASE_MIDGAME);

		int e = (eg_value(v) * int(sf)) / SCALE_FACTOR_NORMAL;
		int r = (mg_value(v) * int(ph) + e * int(PHASE_MIDGAME - ph)) / PHASE_MIDGAME;

		assert((r / GrainSize) * GrainSize > -VALUE_INFINITE && (r / GrainSize) * GrainSize < VALUE_INFINITE);
		return Value((r / GrainSize) * GrainSize); // Sign independent
	}

	// apply_weight() weights score v by score w trying to prevent overflow
	Score apply_weight(Score v, Score w) {
		return make_score((int(mg_value(v)) * mg_value(w)) / 0x100,
			(int(eg_value(v)) * eg_value(w)) / 0x100);
	}

	// weight_option() computes the value of an evaluation weight, by combining
	// two UCI-configurable weights (midgame and endgame) with an internal weight.

	Score weight_option(const std::string& mgOpt, const std::string& egOpt, Score internalWeight) {

		// Scale option value from 100 to 256
		int mg = Options[mgOpt] * 256 / 100;
		int eg = Options[egOpt] * 256 / 100;

		return apply_weight(make_score(mg, eg), internalWeight);
	}


	// Tracing functions definitions

	double to_cp(Value v) { return double(v) / double(PawnValueMg); }

	void Tracing::add(int idx, Score wScore, Score bScore) {

		scores[WHITE][idx] = wScore;
		scores[BLACK][idx] = bScore;
	}

	void Tracing::row(const char* name, int idx) {

		Score wScore = scores[WHITE][idx];
		Score bScore = scores[BLACK][idx];

		switch (idx) {
	case PST: case IMBALANCE: case PAWN: case TOTAL:
		stream << std::setw(20) << name << " |   ---   --- |   ---   --- | "
			<< std::setw(6)  << to_cp(mg_value(wScore)) << " "
			<< std::setw(6)  << to_cp(eg_value(wScore)) << " \n";
		break;
	default:
		stream << std::setw(20) << name << " | " << std::noshowpos
			<< std::setw(5)  << to_cp(mg_value(wScore)) << " "
			<< std::setw(5)  << to_cp(eg_value(wScore)) << " | "
			<< std::setw(5)  << to_cp(mg_value(bScore)) << " "
			<< std::setw(5)  << to_cp(eg_value(bScore)) << " | "
			<< std::showpos
			<< std::setw(6)  << to_cp(mg_value(wScore - bScore)) << " "
			<< std::setw(6)  << to_cp(eg_value(wScore - bScore)) << " \n";
		}
	}

	std::string Tracing::do_trace(const Position& pos) {

		stream.str("");
		stream << std::showpoint << std::showpos << std::fixed << std::setprecision(2);
		std::memset(scores, 0, 2 * (TOTAL + 1) * sizeof(Score));

		Value margin;
		do_evaluate<true>(pos, margin);

		std::string totals = stream.str();
		stream.str("");

		stream << std::setw(21) << "Eval term " << "|    White    |    Black    |     Total     \n"
			<<             "                     |   MG    EG  |   MG    EG  |   MG     EG   \n"
			<<             "---------------------+-------------+-------------+---------------\n";
		//PAWN, BISHOP, ADVISOR, KNIGHT, CANNON, ROOK, KING
		row("Material, PST, Tempo", PST);
		row("Material imbalance", IMBALANCE);
		row("Pawns", PAWN);
		row("Bishops", BISHOP);
		row("Advisors", ADVISOR);
		row("Knights", KNIGHT);
		row("Cannons", CANNON);

		row("Rooks", ROOK);

		row("Mobility", MOBILITY);
		row("King safety", KING);
		row("Threats", THREAT);
		row("Passed pawns", PASSED);
		row("Space", SPACE);
		row("Structure", STRUCTURE);
		stream <<             "---------------------+-------------+-------------+---------------\n";
		row("Total", TOTAL);
		stream << totals;

		return stream.str();
	}
}
