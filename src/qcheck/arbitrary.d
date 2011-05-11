module qcheck.arbitrary;

private {
  import std.array;
  import std.algorithm : find;
  import std.typetuple;
  import std.stdio;
  import qcheck.detail.arbitrary;
  import qcheck.detail.random;
  import qcheck.policies;
}

T getArbitrary
(T, TL...)
()
{
  auto builder = Builder!(T, TL)();
  return builder.get();
}

Tup getArbitraryTuple
(Tup, TL...)
()
{
  Tup tup;
  auto builder = Builder!(Tup, TL)();
  builder.initTuple(tup.tupleof);
  return tup;
}

void setRandomSeed(uint seed) {
  qcheck.detail.random.setRandomSeed(seed);
}
