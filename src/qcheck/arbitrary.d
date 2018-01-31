/// generate arbitrary random data
module qcheck.arbitrary;

import std.array, std.algorithm, std.typetuple;
import qcheck.detail.arbitrary, qcheck.detail.random,  qcheck.config;

/**
   Get a random value of type `T`.
   Randomly generates necessary ctor arguments.

   Depending on `Config.randomizeFields`, all fields of structs and classes are random initialized.

   Params:
     Generators = custom factory functions for specific types
     config = Configuration for random generation

   Throws:
     CyclicDependencyException - when ctor arguments cyclically depend on each other
*/
T getArbitrary(T, Generators...)(Config config=Config.init)
{
    auto builder = Builder!(T, Generators)(config);
    return builder.get();
}

/// basic usage
unittest
{
    auto sarray = getArbitrary!(int[4])();
    auto array = getArbitrary!(float[])();
    auto aarray = getArbitrary!(int[string])();
}

/// fields not randomized
unittest
{
    static struct Tuple { TypeTuple!(uint, float) vals; alias vals this; }
    Config config;
    config.randomizeFields = false;
    auto val = getArbitrary!(Tuple)(config);
    assert(val[0] == uint.init);
    assert(isNaN(val[1]));
}

/// complex example with ctor arguments and generators
unittest
{
    static struct UserStruct
    {
        this(int val) { this.val = val; }
        int val;
    }

    static struct UserStructHolder
    {
        this(UserStruct val) { this.val = val; }
        UserStruct val;
    }

    static struct UserStructInit
    {
        UserStruct val;
    }

    static UserStruct generator()
    {
        return UserStruct(10);
    }

    auto val = getArbitrary!(UserStruct, generator)();
    assert(val.val == 10);

    auto val2 = getArbitrary!(UserStructHolder, generator)();
    assert(val2.val.val == 10);

    auto val3 = getArbitrary!(UserStructInit, generator)();
    assert(val3.val.val == 10);
}

/// picks a random ctor
unittest
{
    static class MultiCtors
    {
        uint val;

        this(uint)
        {
            this.val = 1;
        }

        this(uint, uint)
        {
            this.val = 2;
        }

        this(uint, uint, uint)
        {
            this.val = 3;
        }

        this(uint, uint, uint, uint)
        {
            this.val = 4;
        }
    }

  auto initial = getArbitrary!(MultiCtors)();
  auto i = 0;
  while (initial.val == getArbitrary!(MultiCtors)().val)
      assert(++i < 100);
}

/// field can be configured to be non-random
unittest
{
    static class ClassWCtor
    {
        this()
        {
        }

        int m;
    }

    static class TestClass
    {
        ClassWCtor val;
    }

    static struct TestStruct
    {
        ClassWCtor val;
    }

    static class ClassWOCtor
    {
        int m;
    }

    Config config;
    config.randomizeFields = false;
    auto cl = getArbitrary!TestClass(config);
    assert(cl.val is null);
    cl = getArbitrary!(TestClass)();
    assert(!(cl.val is null));
}

/** Randomly initialize all fields of tuple `Tup`.

    See_also: getArbitrary
*/
Tup getArbitraryTuple(Tup, Generators...)(Config config=Config.init)
{
    Tup tup;
    auto builder = Builder!(Tup, Generators)(config);
    tup = builder.getTuple!(typeof(tup.tupleof))();
    return tup;
}

/** Randomly initialize an array of `len`

    See_also: getArbitrary
 */
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
public alias randomSeed = qcheck.detail.random.randomSeed;

version (unittest):

import std.conv : to, roundTo;
import std.stdio : writeln, writefln;
import std.math;
import std.traits;
import std.typecons;
import std.typetuple;
import qcheck;

// debug=ARBITRARY;

template maxIt(T) if(isFloatingPoint!T)
{
    enum maxIt = 0;
}

template maxIt(T) if(isSigned!T && isIntegral!T)
{
     enum maxIt = maxIt!(Unsigned!T);
}

template maxIt(T) if(is(T == ulong)) { enum maxIt = 0; }
template maxIt(T) if(is(T == uint)) { enum maxIt = 0; }
template maxIt(T) if(is(T == ushort)) { enum maxIt = 1; }
template maxIt(T) if(is(T == ubyte)) { enum maxIt = 1; }
template maxIt(T) if(is(T == bool)) { enum maxIt = 10; }

template testNumeric(T)
{
    void run()
    {
        auto b0 = getArbitrary!T();
        size_t i;
        while (b0 == getArbitrary!T())
        {
            assert(i <= maxIt!T);
            ++i;
        }
    }
}


unittest
{
    testNumeric!bool.run();
    testNumeric!ulong.run();
    testNumeric!long.run();
    testNumeric!uint.run();
    testNumeric!int.run();
    testNumeric!ushort.run();
    testNumeric!short.run();
    testNumeric!ubyte.run();
    testNumeric!byte.run();
    testNumeric!float.run();
    testNumeric!double.run();
    testNumeric!real.run();
}


enum BoolNum : bool
{
    FALSE = false,
    TRUE = true,
}

struct EnumStruct
{
    this(string name)
    {
        this.name = name;
    }

    string name;
}

///
unittest
{
    static struct S
    {
        string name; // fields are randomized by default
    }

    assert(getArbitrary!S().name != getArbitrary!S().name);
}

///
unittest
{
    enum Enum
    {
        A = 10,
        B = 20,
        C = 30,
        D = 40,
    }

    Enum val = getArbitrary!Enum();
    assert(cast(int)val % 10 == 0);
}

struct Entry
{
    this(Second val)
    {
        this.val = val;
    }
    Second val;
}

class Second
{
    this(Cyclic val)
    {
        this.val = val;
    }
    Cyclic val;
}

struct Cyclic
{
    this(Entry val)
    {
        this.val = val;
    }
    Entry val;
}

unittest
{
    bool succeeded = false;
    try
    {
        auto val = getArbitrary!(Entry)();
    }
    catch (CyclicDependencyException e)
    {
        succeeded = true;
    }
    assert(succeeded);
}

unittest
{
    static bool testFloat(float f)
    {
        return -1000 < f && f < 1000;
    }

    static bool testArray(int K)(byte[] ary)
    {
        return ary.length <= K;
    }

    Config config;
    config.minValue = -1000;
    config.maxValue = 1000;

    quickCheck!testFloat(config);

    config.maxSize = 10;
    quickCheck!(testArray!10)(config);

    config.minValue = -2;
    config.maxValue = 2;
    config.maxSize = 5;
    quickCheck!(testArray!5)(config);
}
