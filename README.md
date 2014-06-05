qcheck [![Build Status](https://travis-ci.org/MartinNowak/qcheck.png?branch=master)](https://travis-ci.org/MartinNowak/qcheck)
====

A library for automatic randomized testing.

==== Usage

```
unittest
{
    import qcheck;

    static void testSort(int[] arr)
    {
        import std.algorithm;
        auto res = sort(arr);
        foreach (i; 1 .. res.length)
            assert(res[i-1] <= res[i]);
    }

    qcheck!testSort();
}
```
