/**
   Random Testing with arbitrary data.
 */
module qcheck.quickcheck;

import std.conv, std.datetime, std.exception, std.traits, std.typecons, std.typetuple, std.stdio;
import core.exception : AssertError;
import qcheck.arbitrary, qcheck.config, qcheck.exceptions;

/// Result of a testee. It is okay for a testee to just return a boolean result.
enum QCheckResult
{
    discard = -1, /// discard input
    pass = true, /// test succeeded
    ok = pass, /// alias for pass
    fail = false, /// test failed
}

/**
   Feed testee with arbitrary data to check that it behaves correctly.
 */
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

/// comparing sort algorithms
unittest
{
    // https://rosettacode.org/wiki/Sorting_algorithms/Bubble_sort#D
    static T[] bubbleSort(T)(T[] data) pure nothrow
    {
        import std.algorithm : swap;
        foreach_reverse (n; 0 .. data.length)
        {
            bool swapped;
            foreach (i; 0 .. n)
                if (data[i] > data[i + 1]) {
                    swap(data[i], data[i + 1]);
                    swapped = true;
                }
            if (!swapped)
                break;
        }
        return data;
    }

    /// random data is injected into testee arguments
    static bool testee(ubyte[] data)
    {
        import std.algorithm : equal, sort;

        return bubbleSort(data.dup).equal(data.sort());
    }

    quickCheck!testee;
}

/// testee can reject random arguments to enforce additional constraints
unittest
{
    static QCheckResult testee(string haystack, string needle)
    {
        import std.algorithm : canFind, boyerMooreFinder;

        if (needle.length < haystack.length)
            return QCheckResult.discard;

        auto bmFinder = boyerMooreFinder(needle);
        immutable found = !!bmFinder.beFound(haystack).length;
        return found == haystack.canFind(needle) ? QCheckResult.pass : QCheckResult.fail;
    }

    randomSeed = 42;
    quickCheck!testee;
}

private:

template Identifier(alias Testee)
{
    enum Identifier = __traits(identifier, Testee);
}
