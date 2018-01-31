qcheck [![Build Status](https://travis-ci.org/MartinNowak/qcheck.svg?branch=master)](https://travis-ci.org/MartinNowak/qcheck) [![Coverage](https://codecov.io/gh/MartinNowak/qcheck/branch/master/graph/badge.svg)](https://codecov.io/gh/MartinNowak/qcheck) [![Dub](https://img.shields.io/dub/v/qcheck.svg)](http://code.dlang.org/packages/qcheck)
=====

A library for automatic random testing, inspired by Haskell's excellent [QuickCheck](http://www.cse.chalmers.se/~rjmh/QuickCheck/).

# [Documentation](http://martinnowak.github.io/qcheck)

# Example Usage

```d
int[] mysort(int[] arr)
{
    // ...
    return arr;
}

unittest
{
    import qcheck;
    import std.algorithm;

    quickCheck!((int[] a) => mysort(a.dup).equal(a.sort()));
}
```

# Generate Random data

The library can also just be used to generate random data, see [`getArbitrary`](http://martinnowak.github.io/qcheck/qcheck/arbitrary/getArbitrary.html).

```d
unittest
{
    import qcheck.arbitrary;

    auto sarray = getArbitrary!(int[4])();
    auto array = getArbitrary!(float[])();
    auto aarray = getArbitrary!(int[string])();
}
```
