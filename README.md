qcheck [![dub](https://img.shields.io/badge/dub-0.10.0-brightgreen.svg)](http://code.dlang.org/packages/qcheck) [![Build Status](https://img.shields.io/travis/MartinNowak/qcheck.svg)](https://travis-ci.org/MartinNowak/qcheck)
====

A library for automatic randomized testing.

### Usage

Add qcheck to the dependencies of your project.

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

    quickCheck!((int[] a) => assert(equal(sort(arr.dup), mysort(arr.dup))));
}
```
