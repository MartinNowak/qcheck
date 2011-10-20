import qcheck._;

unittest
{
    static struct A
    {
        byte m;
        bool testMe(A a2) const
        {
            return &this != &a2;
        }
    }

    static bool testFunc(A a1, A a2)
    {
        return &a1 != &a2;
    }

    Config config;
    config.randomizeFields = true;
    quickCheck!(testFunc)(config);
    A a;
    auto dg = &a.testMe;
    a.m = 10;
    quickCheck!(dg)(config);
}
