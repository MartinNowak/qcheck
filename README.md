qcheck [![Build Status](https://travis-ci.org/MartinNowak/qcheck.png?branch=master)](https://travis-ci.org/MartinNowak/qcheck)
====

A library for automatic randomized testing.

### Usage

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
