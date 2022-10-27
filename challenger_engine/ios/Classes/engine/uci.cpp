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

#include <iomanip>
#include <iostream>
#include <sstream>
#include <string>

#include "evaluate.h"
#include "notation.h"
#include "position.h"
#include "search.h"
#include "thread.h"
#include "tt.h"
#include "ucioption.h"

#include "challenger-channel.h"

#ifdef _WIN32
#include "windows.h"
static void idle() { Sleep(1); }
#else
#include "unistd.h"
static void idle() { usleep(1000); }
#endif

using namespace std;

extern void benchmark(const Position &pos, istream &is);

namespace
{
    // FEN string of the initial position, normal chess
    const char *StartFEN = "rnbakabnr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RNBAKABNR w - - 0 1";

    // Keep track of position keys along the setup moves (from start position to the
    // position just before to start searching). Needed by repetition draw detection.
    Search::StateStackPtr SetupStates;

    void setoption(istringstream &up);
    void position(Position &pos, istringstream &up);
    void go(const Position &pos, istringstream &up);
}

/// Wait for a command from the user, parse this text string as an UCI command,
/// and call the appropriate functions. Also intercepts EOF from stdin to ensure
/// that we exit gracefully if the GUI dies unexpectedly. In addition to the UCI
/// commands, the function also supports a few debug commands.

void UCI::loop(const string &args)
{
    Position pos(StartFEN, false, Threads.main()); // The root position
    string token, cmd = args;

    do
    {
        char line_str[8192];
        CommandChannel *channel = CommandChannel::getInstance();
        while (!channel->popupCommand(line_str)) idle();
        cmd = line_str;

        istringstream is(cmd);

        is >> skipws >> token;

        if (token == "quit" || token == "stop" || token == "ponderhit")
        {
            // GUI sends 'ponderhit' to tell us to ponder on the same move the
            // opponent has played. In case Signals.stopOnPonderhit is set we are
            // waiting for 'ponderhit' to stop the search (for instance because we
            // already ran out of time), otherwise we should continue searching but
            // switching from pondering to normal search.
            if (token != "ponderhit" || Search::Signals.stopOnPonderhit)
            {
                Search::Signals.stop = true;
                Threads.main()->notify_one(); // Could be sleeping
            }
            else
            {
                Search::Limits.ponder = false;
            }
        }
        else if (token == "perft" && (is >> token)) // Read perft depth
        {
            stringstream ss;

            ss << Options["Hash"] << " "
               << Options["Threads"] << " " << token << " current perft";

            benchmark(pos, ss);
        }
        else if (token == "key")
        {
            // sync_cout << hex << uppercase << setfill('0')
            //           << "position key: " << setw(16) << pos.key()
            //           << "\nmaterial key: " << setw(16) << pos.material_key()
            //           << "\npawn key:     " << setw(16) << pos.pawn_key()
            //           << dec << sync_endl;
            PrintLn("position key: %ld", pos.key());
            PrintLn("material key: %ld", pos.material_key());
            PrintLn("pawn key: %ld", pos.pawn_key());
        }
        else if (token == "ucci")
        {
            // sync_cout << "id name " << engine_info(true)
            //           << "\n"
            //           << Options
            //           << "\nucciok" << sync_endl;

            PrintLn("id name %s", engine_info(true).c_str());

            char buffer[8192];
            std::stringstream ss;
            ss << Options;
            ss >> buffer;

            PrintLn(buffer);

            PrintLn("ucciok");
        }
        else if (token == "eval")
        {
            Search::RootColor = pos.side_to_move(); // Ensure it is set
            // sync_cout << Eval::trace(pos) << sync_endl;
            PrintLn(Eval::trace(pos).c_str());
        }
        else if (token == "ucinewgame")
            TT.clear();
        else if (token == "go")
            go(pos, is);
        else if (token == "position" || token == "fen")
            position(pos, is);
        else if (token == "setoption")
            setoption(is);
        else if (token == "flip")
            pos.flip();
        else if (token == "bench")
            benchmark(pos, is);
        else if (token == "d")
        {
            // sync_cout << pos.pretty() << sync_endl;
            PrintLn(pos.pretty().c_str());
        }
        else if (token == "isready")
        {
            // sync_cout << "readyok" << sync_endl;
            PrintLn("readyok");
        }
        else
        {
            // sync_cout << "Unknown command: " << cmd << sync_endl;
            PrintLn("Unknown command: %s", cmd.c_str());
        }

    } while (token != "quit" && args.empty()); // Args have one-shot behaviour

    PrintLn("bye");

    Threads.wait_for_think_finished(); // Cannot quit while search is running
}

namespace
{
    // position() is called when engine receives the "position" UCI command.
    // The function sets up the position described in the given fen string ("fen")
    // or the starting position ("startpos") and then makes the moves given in the
    // following move list ("moves").

    void position(Position &pos, istringstream &is)
    {
        Move m;
        string token, fen;

        is >> token;

        if (token == "startpos")
        {
            fen = StartFEN;
            is >> token; // Consume "moves" token if any
        }
        else if (token == "fen")
            while (is >> token && token != "moves")
                fen += token + " ";
        else
            while (token != "moves")
            {
                fen += token + " ";
                if (!(is >> token))
                {
                    break;
                }
            }
        // else
        //     return;

        pos.set(fen, Options["UCI_Chess960"], Threads.main());
        SetupStates = Search::StateStackPtr(new std::stack<StateInfo>());

        // Parse move list (if any)
        while (is >> token && (m = move_from_uci(pos, token)) != MOVE_NONE)
        {
            SetupStates->push(StateInfo());
            pos.do_move(m, SetupStates->top());
        }
    }

    // setoption() is called when engine receives the "setoption" UCI command. The
    // function updates the UCI option ("name") to the given value ("value").

    void setoption(istringstream &is)
    {
        string token, name, value;

        is >> token; // Consume "name" token

        // Read option name (can contain spaces)
        while (is >> token && token != "value")
            name += string(" ", !name.empty()) + token;

        // Read option value (can contain spaces)
        while (is >> token)
            value += string(" ", !value.empty()) + token;

        if (Options.count(name))
        {
            Options[name] = value;
        }
        else
        {
            // sync_cout << "No such option: " << name << sync_endl;
            PrintLn("No such option: %s", name.c_str());
        }
    }

    // go() is called when engine receives the "go" UCI command. The function sets
    // the thinking time and other parameters from the input string, and starts
    // the search.

    void go(const Position &pos, istringstream &is)
    {
        Search::LimitsType limits;
        vector<Move> searchMoves;
        string token;

        while (is >> token)
        {
            if (token == "searchmoves")
                while (is >> token)
                    searchMoves.push_back(move_from_uci(pos, token));

            else if (token == "wtime")
                is >> limits.time[WHITE];
            else if (token == "btime")
                is >> limits.time[BLACK];
            else if (token == "winc")
                is >> limits.inc[WHITE];
            else if (token == "binc")
                is >> limits.inc[BLACK];
            else if (token == "movestogo")
                is >> limits.movestogo;
            else if (token == "depth")
                is >> limits.depth;
            else if (token == "nodes")
                is >> limits.nodes;
            else if (token == "movetime")
                is >> limits.movetime;
            else if (token == "mate")
                is >> limits.mate;
            else if (token == "infinite")
                limits.infinite = true;
            else if (token == "ponder")
                limits.ponder = true;
        }

        Threads.start_thinking(pos, limits, searchMoves, SetupStates);
    }
}
