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
    tup = builder.getTuple!(typeof(tup.tupleof))();
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


enum IntEnum
{
    A = 10,
    B = 20,
    C = 30,
    D = 40,
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

unittest
{
    IntEnum val = getArbitrary!IntEnum();
    assert(cast(int)val % 10 == 0);
}

class TestClass
{
    ClassWCtor val;

    override @property string toString() {
        return "TestClass val:" ~ to!string(val);
    }
}

struct TestStruct
{
    ClassWCtor val;
}

class ClassWOCtor
{
    int m;
}

class ClassWCtor
{
    this()
    {
    }

    int m;
}

unittest
{
    Config config;
    config.randomizeFields = false;
    auto cl = getArbitrary!TestClass(config);
    assert(cl.val is null);
    cl = getArbitrary!(TestClass)();
    assert(!(cl.val is null));
}


class MultiCtors
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

unittest
{
  auto inst1 = getArbitrary!(MultiCtors)();
  auto i = 0;
  while (inst1.val == getArbitrary!(MultiCtors)().val) {
    //! very unlikely
    assert(++i < 100);
  }
}

static struct Entry
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

static struct Cyclic
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
    static struct Tuple { TypeTuple!(uint, float) vals; alias vals this; }
    Config config;
    config.randomizeFields = false;
    auto val = getArbitrary!(Tuple)(config);
    assert(val[0] == uint.init);
    assert(isNaN(val[1]));
}

struct UserStruct
{
    this(int val) { this.val = val; }
    int val;
}

struct UserStructHolder
{
    this(UserStruct val) { this.val = val; }
    UserStruct val;
}

struct UserStructInit
{
    UserStruct val;
}

UserStruct generator()
{
    return UserStruct(10);
}

unittest
{
    auto val = getArbitrary!(UserStruct, generator)();
    assert(val.val == 10);

    auto val2 = getArbitrary!(UserStructHolder, generator)();
    assert(val2.val.val == 10);

    auto val3 = getArbitrary!(UserStructInit, generator)();
    assert(val3.val.val == 10);
}

unittest
{
    auto sarray = getArbitrary!(int[4])();
    auto array = getArbitrary!(float[])();
    auto aarray = getArbitrary!(int[string])();
}

bool testFloat(float f)
{
    return -1000 < f && f < 1000;
}

bool testArray(int K)(byte[] ary)
{
    return ary.length <= K;
}

unittest
{
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
