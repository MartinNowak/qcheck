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
    discard = -1,
    ok = true,
    fail = false,
}

bool quickCheck(alias Testee, Generators...)(Config config=Config.init)
{
    alias TypeTuple!(staticMap!(Unqual, ParameterTypeTuple!Testee)) TP;

    size_t succeeded, failed, discarded;

    alias Tuple!(size_t, Tuple!TP, string) FailPair;

    FailPair[] failingParams;
    Tuple!TP params;

    string head = Identifier!Testee;
    if (head.length > 16)
        head = head[0 .. 13] ~ "...";
    writef("CHECK: %-16s [                                                  ]\r", head);
    writef("CHECK: %-16s [", head);
    ushort progress;
    while (succeeded < config.maxSuccess && discarded < config.maxDiscarded && failed < config.maxFails)
    {
        try
        {
            params = getArbitraryTuple!(Tuple!TP, Generators)(config);
            auto result = Testee(params.tupleof);

            if (result == QCheckResult.fail)
            {
                failingParams ~= FailPair(succeeded + failed, params, Identifier!Testee ~ " false");
                ++failed;
            }
            else if (result == QCheckResult.ok)
            {
                ++succeeded;
                if (progress < 50 * succeeded / config.maxSuccess)
                {
                    do
                    {
                        write("=");
                    } while (++progress < 50 * succeeded / config.maxSuccess);
                    stdout.flush();
                }
            }
            else if (result == QCheckResult.discard)
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
            ++failed;
            if (!config.keepGoing)
                break;
        }
        catch(Exception e)
        {
            failingParams ~= FailPair(succeeded + failed, params, to!string(e));
            ++failed;
            if (!config.keepGoing)
                break;
        }
    }

    if (!failed && succeeded == config.maxSuccess)
    {
        writeln("] OK");
    }
    else if (!failed)
    {
        assert(succeeded < config.maxSuccess);
        auto total = succeeded + discarded;
        writefln("] FAIL (%s/%s)", succeeded, total);
        writeln("Giving up after too many discards.");
    }
    else
    {
        writeln("] FAIL");
        writeln("Failing Parameters:");
        foreach (p; failingParams)
            writefln("======== %s ========\n%s\n%s", p[]);
    }

    return failingParams.length == 0;
}

private:

template Identifier(alias Testee)
{
    enum Identifier = __traits(identifier, Testee);
}

unittest
{
    static struct A
    {
        byte m;
        bool testMe(A a2) const
        {
            return &this != &a2;
        }
    }

    static bool testFunc(A a1, A a2)
    {
        return &a1 != &a2;
    }

    Config config;
    quickCheck!(testFunc)(config);
    A a;
    auto dg = &a.testMe;
    a.m = 10;
    quickCheck!(dg)(config);
}
