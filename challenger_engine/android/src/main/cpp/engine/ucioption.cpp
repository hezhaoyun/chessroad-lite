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
#include <cstdlib>
#include <sstream>

#include "evaluate.h"
#include "misc.h"
#include "thread.h"
#include "tt.h"
#include "ucioption.h"
#include "psqtab.h"

using std::string;

UCI::OptionsMap Options; // Global object

namespace UCI {

/// 'On change' actions, triggered by an option's value change
void on_logger(const Option& o) { start_logger(o); }
void on_eval(const Option&) { Eval::init(); }
void on_threads(const Option&) { Threads.read_uci_options(); }
void on_hash_size(const Option& o) { TT.set_size(o); }
void on_clear_hash(const Option&) { TT.clear(); }

void on_material(const Option&) { Material::init(); }
void on_pst_value(const Option&) { Postion::init_psq_value();}
void on_eval_variables(const Option&) { Eval::init_variables(); }


/// Our case insensitive less() function as required by UCI protocol
bool ci_less(char c1, char c2) { return tolower(c1) < tolower(c2); }

bool CaseInsensitiveLess::operator() (const string& s1, const string& s2) const {
  return std::lexicographical_compare(s1.begin(), s1.end(), s2.begin(), s2.end(), ci_less);
}


/// init() initializes the UCI options to their hard coded default values

void init(OptionsMap& o) {

  o["Write Debug Log"]             = Option(false, on_logger);
  o["Write Search Log"]            = Option(false);
  o["Search Log Filename"]         = Option("SearchLog.txt");
  o["Book File"]                   = Option("book.bin");
  o["Best Book Move"]              = Option(false);
  o["Contempt Factor"]             = Option(0, -50,  50);
  o["Mobility (Midgame)"]          = Option(100, 0, 200, on_eval);
  o["Mobility (Endgame)"]          = Option(100, 0, 200, on_eval);
  o["Pawn Structure (Midgame)"]    = Option(100, 0, 200, on_eval);
  o["Pawn Structure (Endgame)"]    = Option(100, 0, 200, on_eval);
  o["Passed Pawns (Midgame)"]      = Option(100, 0, 200, on_eval);
  o["Passed Pawns (Endgame)"]      = Option(100, 0, 200, on_eval);
  o["Space"]                       = Option(100, 0, 200, on_eval);
  o["Aggressiveness"]              = Option(100, 0, 200, on_eval);
  o["Cowardice"]                   = Option(100, 0, 200, on_eval);
  o["Min Split Depth"]             = Option(0, 0, 12, on_threads);
  o["Max Threads per Split Point"] = Option(5, 4,  8, on_threads);
  o["Threads"]                     = Option(1, 1, MAX_THREADS, on_threads);
  o["Idle Threads Sleep"]          = Option(true);
  o["Hash"]                        = Option(128, 1, 8192, on_hash_size);
  o["Clear Hash"]                  = Option(on_clear_hash);
  o["Ponder"]                      = Option(true);
  o["OwnBook"]                     = Option(false);
  o["MultiPV"]                     = Option(1, 1, 500);
  o["Skill Level"]                 = Option(20, 0, 20);
  o["Emergency Move Horizon"]      = Option(40, 0, 50);
  o["Emergency Base Time"]         = Option(50, 0, 30000);
  o["Emergency Move Time"]         = Option(20, 0, 5000);
  o["Minimum Thinking Time"]       = Option(20, 0, 5000);
  o["Slow Mover"]                  = Option(50, 10, 1000);
  o["UCI_Chess960"]                = Option(false);
  o["UCI_AnalyseMode"]             = Option(false, on_eval);
  o["Piece Structure"]             = Option(100, 0, 200, on_eval);

  typedef Value V;
#define S(mg, eg) make_score(mg, eg)

  //用于产生tuner文件
  //Log log;

  //log<<"name,   init,  max,  min,  c_end,  r_end,  elod"<<std::endl;

  //PAWN, BISHOP, ADVISOR, KNIGHT, CANNON, ROOK, KING
  const Score MobilityBonus[][32] = {
	  {}, {},//Pawn
	  { S( 0, 0), S( 0,  0 ), S( 0,  0), S(0, 0),   S(0, 0)},// Bishops
	  { S( 0, 0), S( 0,  0 ), S( 0,  0), S(0, 0),   S(0, 0)},// Advisor
	  { S(-35,-30), S(-20,-20), S(-20,-20), S( 0,  0), S(0, 0), S(15, 10),S( 15, 10), S( 25, 12), S(25, 12) },//knight
	  { S( -10, -10), S( 2,  4), S( 4,  4), S(6, 6), S(8, 8),S(10, 10),S(12, 12),S(12, 12),S(12, 12),S(12, 12),S(12, 12),S(12, 12),S(12, 12),S(12, 12),S(12, 12),S(12, 12),S(12, 12),S(12, 12)},// Cannon
	  { S(-20,-20), S(-18,-18), S(-16,-16), S( -10,-10), S( -8,-8), S(-4,-4),S( 0, 0), S( 4, 2), S(8, 4), S(12,6), S(16,8), S(20,10),S( 24,12), S( 24,12), S(24,12), S(24,12), S(24,12), S(24,12)}, // Rooks 
  };
  for (int pt1 = KNIGHT; pt1 <= ROOK; ++pt1)
  {
	  for (int c = 0; c <= 17; ++c)
	  {

		  int min = -40;
		  int max = 40;

		  if (pt1 == KNIGHT)
		  {
              min = -50;
			  max = 50;
		  }
		  if (pt1 == CANNON)
		  {
			  min = 0;
			  max = 20;
		  }
		  if (pt1 == ROOK)
		  {
			  min = -30;
			  max = 30;
		  }

		  int m = (int)mg_value(MobilityBonus[pt1][c]);
		  int e = (int)eg_value(MobilityBonus[pt1][c]);


		  char buf[256] = {0};
		  char text[1024]={0};

		  sprintf(buf, "MobilityBonusM[%d][%d]",pt1,c);
		  o[buf] = Option(m, min, max, on_eval_variables);

		  //sprintf(text, "%s,%d,%d,%d,%d,%d,%d",buf, m, max,min,8, 1, 0);
		  //log<<text<<std::endl;

		  //------

		  sprintf(buf, "MobilityBonusE[%d][%d]",pt1,c);
		  o[buf] = Option(e, min, max, on_eval_variables);		  

		  //sprintf(text, "%s,%d,%d,%d,%d,%d,%d",buf, e, max,min,8, 1, 0);
		  //log<<text<<std::endl;

	  }
  }



  const Score RookPin          = make_score(26, 31);
  const Score CannonPin        = make_score(16, 11);

  const Score RookOnPawn       = make_score(10, 28);
  const Score RookOpenFile     = make_score(53, 21);

  const Score RookPinRook      = make_score(20, 20);

  const Score CannonPinRook    = make_score(10, 10);
  const Score CannonPinKnight  = make_score(10, 10);
  const Score CannonPinBishop  = make_score(5, 3);

  const Score KnightLegPawn    = make_score(16,  0);

  {
	  char buf[256] = {0};
	  char text[1024]={0};

	  int min = -50;
	  int max = 50;

	  int m = 0;
	  int e = 0;

#define GEN_CODE(namem,namee, v, minv, maxv) {\
	  m = (int)mg_value((v));\
	  e = (int)eg_value((v));\
      min = minv;\
      max = maxv;\
	  o[namem]= Option(m, min, max, on_eval_variables);\
	  o[namee]= Option(e, min, max, on_eval_variables);\
	  }
	  //sprintf(text, "%s,%d,%d,%d,%d,%d,%d",(namem), m, max,min,8, 1, 0);\
	  //log<<text<<std::endl;\
	  //sprintf(text, "%s,%d,%d,%d,%d,%d,%d",(namee), e, max,min,8, 1, 0);\
	  //log<<text<<std::endl;\
	  }

	  GEN_CODE("RookPinM","RookPinE", RookPin, 0, 50);
	  GEN_CODE("CannonPinM","CannonPinE", CannonPin, 0, 50);
	  GEN_CODE("RookOnPawnM","RookOnPawnE", RookOnPawn, 0, 50);
	  GEN_CODE("RookOpenFileM","RookOpenFileE", RookOpenFile, 0, 50);
	  GEN_CODE("RookPinRookM","RookPinRookE", RookPinRook, 0, 50);
	  GEN_CODE("CannonPinRookM","CannonPinRookE", CannonPinRook, 0, 50);
	  GEN_CODE("CannonPinKnightM","CannonPinKnightE", CannonPinKnight, 0, 50);
	  GEN_CODE("CannonPinBishopM","CannonPinBishopE", CannonPinBishop, 0, 50);
	  GEN_CODE("KnightLegPawnM","KnightLegPawnE", KnightLegPawn, 0, 50);


  }

  //o["PawnValueMg"] = Option(198, 50, 500, on_pst_value);
  //o["PawnValueEg"] = Option(258, 50, 500, on_pst_value);
  //o["BishopValueMg"] = Option(416, 200, 800, on_pst_value);
  //o["BishopValueEg"] = Option(437, 200, 800, on_pst_value);
  //o["AdvisorValueMg"] = Option(424, 200, 800, on_pst_value);
  //o["AdvisorValueEg"] = Option(447, 200, 800, on_pst_value);
  //o["KnightValueMg"] = Option(817, 500, 1500, on_pst_value);
  //o["KnightValueEg"] = Option(846, 500, 1500, on_pst_value);
  //o["CannonValueMg"] = Option(836, 500, 1500, on_pst_value);
  //o["CannonValueEg"] = Option(857, 500, 1500, on_pst_value);
  //o["RookValueMg"] = Option(2021, 1000, 2800, on_pst_value);
  //o["RookValueEg"] = Option(2058, 1000, 2800, on_pst_value);

  //const int LinearCoefficients[7] = { 0,   -162, -190,   -190,   -1000,   105,   26 };
  //for (int pt1 = PAWN; pt1 <= ROOK; ++pt1)
  //{
	 // char buf[256] = {0};
	 // sprintf(buf, "LinearCoefficients[%d]",pt1);
	 // o[buf] = Option(LinearCoefficients[pt1], -1000, 1000, on_material);

	 // //char text[1024]={0};
	 // //sprintf(text, "%s,%d,%d,%d,%d,%d,%d",buf, LinearCoefficients[pt1], 1000,-1000,50, 1, 0);
	 // //log<<text<<std::endl;
  //}

  //const int QuadraticCoefficientsSameColor[][PIECE_TYPE_NB] = {
	 // // pair pawn Bishop Advisor knight cannon rook 
	 // {  0,                                       }, // Bishop pair
	 // {  0,   2,                                  }, // Pawn
	 // {  0,   3,    46,                           }, //Bishop
	 // {  0,   0,    0,    45,                     }, //Advisor
	 // {  0,   17,   0,    44,    20,              }, // Knight
	 // {  0,   5,  11,    5,      50,     18,      }, // cannon
	 // {  0,  15,   6,    7,      15,     30,    40}, // Rook

  //};

  //for (int pt1 = PAWN; pt1 <= ROOK; ++pt1)
  //{
	 // for (int pt2 = PAWN; pt2<= pt1; ++pt2)
	 // {
  //        char buf[256] = {0};
  //        sprintf(buf, "QuadraticCoefficientsSameColor[%d][%d]",pt1, pt2);

  //        o[buf] = Option(QuadraticCoefficientsSameColor[pt1][pt2], -100, 100, on_material);

		//  //char text[1024]={0};
		//  //sprintf(text, "%s,%d,%d,%d,%d,%d,%d",buf, QuadraticCoefficientsSameColor[pt1][pt2], 1000,-1000,50, 1, 0);
		//  //log<<text<<std::endl;
	 // }
	 // 
  //}

  //const int QuadraticCoefficientsOppositeColor[][PIECE_TYPE_NB] = {
	 // // pair pawn Bishop Advisor knight cannon rook 
	 // {  0                                              }, // Bishop pair
	 // {  0,   41,                                       }, // Pawn
	 // {  0,   -8,    0                                  }, // Bishop 
	 // {  0,   -8,    0,    0                            }, // Advisor
	 // {  0,   6,    -5,   -5,     41                    }, // Knight      OUR PIECES
	 // {  0,   22,   -20,  -10,    -5,    41             }, // cannon
	 // {  0,   40,   30,   30,     50,    6,   41        }, // Rook

  //};

  //for (int pt1 = PAWN; pt1 <= ROOK; ++pt1)
  //{
	 // for (int pt2 = PAWN; pt2<= pt1; ++pt2)
	 // {
		//  char buf[256] = {0};
		//  sprintf(buf, "QuadraticCoefficientsOppositeColor[%d][%d]",pt1, pt2);

		//  o[buf] = Option(QuadraticCoefficientsOppositeColor[pt1][pt2], -100, 100, on_material);

		//  //char text[1024]={0};
		//  //sprintf(text, "%s,%d,%d,%d,%d,%d,%d",buf, QuadraticCoefficientsOppositeColor[pt1][pt2], 1000,-1000,50, 1, 0);
		//  //log<<text<<std::endl;
	 // }

  //}
  


  //for (PieceType pt = PAWN; pt <= KING; ++pt)
  //{
	 // for (Square sq = SQ_A0; sq < SQUARE_NB; ++sq)
	 // {

		//  char buf[256] = {0};
		//  sprintf(buf, "PSQT_MG[%d][%d]",pt, sq);

		//  int v = (int)mg_value(PSQT[pt][sq]);
  //        o[buf] = Option(v, -200,200);
		//  sprintf(buf, "PSQT_EG[%d][%d]",pt, sq);

		//  v = (int)eg_value(PSQT[pt][sq]);
		//  o[buf] = Option(v, -200,200);
	 // }
	 // 
  //}
  
}


/// operator<<() is used to print all the options default values in chronological
/// insertion order (the idx field) and in the format defined by the UCI protocol.

std::ostream& operator<<(std::ostream& os, const OptionsMap& om) {

  for (size_t idx = 0; idx < om.size(); idx++)
      for (OptionsMap::const_iterator it = om.begin(); it != om.end(); ++it)
          if (it->second.idx == idx)
          {
              const Option& o = it->second;

			  if(it->first != "UCI_Chess960")
			  {
				  os << "\noption name " << it->first << " type " << o.type;

				  if (o.type != "button")
					  os << " default " << o.defaultValue;

				  if (o.type == "spin")
					  os << " min " << o.min << " max " << o.max;
			  }

              break;
          }
  return os;
}


/// Option c'tors and conversion operators

Option::Option(const char* v, Fn* f) : type("string"), min(0), max(0), idx(Options.size()), on_change(f)
{ defaultValue = currentValue = v; }

Option::Option(bool v, Fn* f) : type("check"), min(0), max(0), idx(Options.size()), on_change(f)
{ defaultValue = currentValue = (v ? "true" : "false"); }

Option::Option(Fn* f) : type("button"), min(0), max(0), idx(Options.size()), on_change(f)
{}

Option::Option(int v, int minv, int maxv, Fn* f) : type("spin"), min(minv), max(maxv), idx(Options.size()), on_change(f)
{ std::ostringstream ss; ss << v; defaultValue = currentValue = ss.str(); }


Option::operator int() const {
  assert(type == "check" || type == "spin");
  return (type == "spin" ? atoi(currentValue.c_str()) : currentValue == "true");
}

Option::operator std::string() const {
  assert(type == "string");
  return currentValue;
}


/// operator=() updates currentValue and triggers on_change() action. It's up to
/// the GUI to check for option's limits, but we could receive the new value from
/// the user by console window, so let's check the bounds anyway.

Option& Option::operator=(const string& v) {

  assert(!type.empty());


  if ((type != "button" && v.empty())
      || (type == "check" && v != "true" && v != "false")
      || (type == "spin" && (atoi(v.c_str()) < min || atoi(v.c_str()) > max)))
      return *this;

  if (type != "button")
      currentValue = v;


  if (on_change)
      (*on_change)(*this);

  return *this;
}

} // namespace UCI
