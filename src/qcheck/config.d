module qcheck.config;

import std.bitmanip;

struct Config
{
    enum Ctors { Any, DefaultOnly, }

    mixin template Property(T, string name, T init=T.init)
    {
        mixin(`@property T `~name~`() const { return _`~name~`; }`);
        mixin(`@property Config `~name~`(T val) { _`~name~` = val; return this; }`);
        mixin(`T _`~name~` = init;`);
    }

    mixin Property!(Ctors, "ctors");
    mixin Property!(bool, "randomizeFields");
    mixin Property!(bool, "keepGoing");
    mixin Property!(size_t, "maxSuccess", 100);
    mixin Property!(size_t, "maxFails", 100);
    mixin Property!(size_t, "maxSize", 100);
    mixin Property!(double, "minValue", -1e6);
    mixin Property!(double, "maxValue", 1e6);
}
