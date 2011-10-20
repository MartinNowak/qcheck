module qcheck.config;

import std.bitmanip;

struct Config
{
    enum Ctors { Any, DefaultOnly, }

    Ctors ctors;
    bool randomizeFields;
    bool keepGoing;
    size_t maxSuccess = 100;
    size_t maxFails = 100;
    size_t maxSize  = 100;
    double minValue = -1e6;
    double maxValue = 1e6;
}
