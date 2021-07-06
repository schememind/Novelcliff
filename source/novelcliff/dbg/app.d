/**
* Module for step-by-step game state debugging.
*/
module novelcliff.dbg;

import novelcliff.core;
import std.stdio;
import core.time : MonoTime, Duration;

void main()
{
    string input;
    Game game = new Game("path/to/any/text/file.txt");
    writeln(game.renderString);
    while (true)
    {
        input = readln();
        
        const MonoTime before = MonoTime.currTime;

        if (input[0] == 'q') {
            return;
        }
        else if (input[0] == 'a')
        {
            game.registerSignal(InputSignal.LEFT_PRESS);
        }
        else if (input[0] == 'A')
        {
            game.registerSignal(InputSignal.LEFT_RELEASE);
        }
        else if (input[0] == 'd')
        {
            game.registerSignal(InputSignal.RIGHT_PRESS);
        }
        else if (input[0] == 'D')
        {
            game.registerSignal(InputSignal.RIGHT_RELEASE);
        }
        else if (input[0] == 'w')
        {
            game.registerSignal(InputSignal.JUMP_PRESS);
        }
        else if (input[0] == 'W')
        {
            game.registerSignal(InputSignal.JUMP_RELEASE);
        }
        else if (input[0] == 'z')
        {
            game.registerSignal(InputSignal.USE_PRESS);
        }
        else if (input[0] == 'Z')
        {
            game.registerSignal(InputSignal.USE_RELEASE);
        }
        else
        {
            writeln("Unknown input: ", input);
        }
        
        game.update;
        const MonoTime afterUpdate = MonoTime.currTime;

        writeln(game.renderDstring);
        const MonoTime afterRendering = MonoTime.currTime;

        Duration updateTime = afterUpdate - before;
        Duration renderingTime = afterRendering - afterUpdate;
        Duration totalTime = afterRendering - before;

        writeln("\n==========================");
        writeln("Update time: ", updateTime);
        writeln("Render time: ", renderingTime);
        writeln("Total time elapsed: ", totalTime);
    }
}