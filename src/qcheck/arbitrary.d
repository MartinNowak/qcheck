module qcheck.arbitrary;

import std.array, std.algorithm, std.typetuple;
import qcheck.detail.arbitrary, qcheck.detail.random,  qcheck.config;

T getArbitrary(T, Generators...)(Config config=Config.init)
{
    auto builder = Builder!(T, Generators)(config);
    return builder.get();
}

Tup getArbitraryTuple(Tup, Generators...)(Config config=Config.init)
{
    Tup tup;
    auto builder = Builder!(Tup, Generators)(config);
    builder.initTuple(tup.tupleof);
    return tup;
}

T[] getArbitraryArray(T, Generators...)(size_t len, Config config=Config.init)
{
    T[] result;
    auto builder = Builder!(T, Generators)(config);
    foreach(_; 0 .. len)
        result ~= builder.get();
    return result;
}

/*
 * Set the random seed for the random generator used by the qcheck
 * library. This is useful to gain reproducible results.
 */
alias qcheck.detail.random.randomSeed randomSeed;
