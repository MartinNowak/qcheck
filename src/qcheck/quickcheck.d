module qcheck.quickcheck;

import std.conv, std.datetime, std.exception, std.traits, std.typecons, std.typetuple, std.stdio;
import core.exception : AssertError;
import qcheck.arbitrary, qcheck.config, qcheck.exceptions;

/*
 * Result of a testee. It is okay for a testee to return a boolean
 * result.
 */
enum QCheckResult
{
    Discard = -1,
    DISCARD = Discard,
    discard = Discard,
    Ok = true,
    OK = Ok,
    ok = Ok,
    Success = Ok,
    SUCCESS = Ok,
    success = Ok,
    Fail = false,
    FAIL = Fail,
    fail = Fail,
}

bool quickCheck(alias Testee, Generators...)(Config config=Config.init)
{
    alias TypeTuple!(staticMap!(Unqual, ParameterTypeTuple!Testee)) TP;

    size_t succeeded, failed, discarded;

    alias Tuple!(size_t, Tuple!TP, string) FailPair;

    FailPair[] failingParams;
    Tuple!TP params;

    StopWatch sw;
    double totalTime = 0;
    while (succeeded < config.maxSuccess && discarded + failed < config.maxFails)
    {
        try
        {
            params = getArbitraryTuple!(Tuple!TP, Generators)(config);
            sw.reset();
            sw.start();
            auto result = Testee(params.tupleof);
            sw.stop();

            if (result == QCheckResult.Fail)
            {
                failingParams ~= FailPair(succeeded + failed, params, Identifier!Testee ~ " false");
                ++failed;
            }
            else if (result == QCheckResult.Ok)
            {
                writef("prop %s: %s \r", Identifier!Testee, succeeded + failed);
                stdout.flush();
                totalTime += sw.peek.hnsecs;
                ++succeeded;
            }
            else if (result == QCheckResult.Discard)
            {
                ++discarded;
            }
            else
            {
                assert(0, "Unexpected return value " ~ to!string(result));
            }
        }
        catch(AssertError e)
        {
            failingParams ~= FailPair(succeeded + failed, params, to!string(e));
            if (!config.keepGoing)
                break;
        }
        catch(Exception e)
        {
            failingParams ~= FailPair(succeeded + failed, params, to!string(e));
            if (!config.keepGoing)
                break;
        }
    }

    if (!failed)
    {
        auto total = succeeded + discarded;
        writef("prop %s: passed (%s/%s), discarded (%s/%s) OK \n",
               Identifier!Testee, succeeded, total, discarded, total);
    }
    else
    {
        writef("prop %s: failed \n", Identifier!Testee);
        writeln("Failing parameters ", failingParams);
    }

    if (succeeded)
        writefln("avgTime: %f hnsecs", totalTime / succeeded);

    return failingParams.length == 0;
}

private:

template Identifier(alias Testee)
{
    enum Identifier = __traits(identifier, Testee);
}
