module qcheck.config;

import std.bitmanip;

struct Config
{
    enum Ctors { Any, DefaultOnly, }

    Ctors ctors; /// restrict usage of constructors
    bool randomizeFields = true; /// random initialize test data
    bool keepGoing; /// continue on test error
    size_t maxSuccess = 100; /// stop test after maxSuccess
    size_t maxFails = 100; /// stop test after maxFails
    size_t maxSize = 100; /// maximal random number of array elements tested
    double minValue = -1e6; /// minimal random number tested
    double maxValue = 1e6; /// maximal random number tested
}
