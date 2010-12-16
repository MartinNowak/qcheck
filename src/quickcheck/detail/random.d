/**
   Random generators
   Template wrappers around std.random.
*/
module quickcheck.detail.random;

private {
  import std.random;
  import std.traits : isFloatingPoint, isIntegral;

  import quickcheck.detail.conv;
}

// package:

static T randomNumeric(T)() if(isFloatingPoint!T) {
  real res = sGen.front;
  sGen.popFront;
  return res / (UIntType.max - UIntType.min);
}

static T randomNumeric(T)(T min, T max) if(isIntegral!T) {
  auto res = randomNumeric!(real) * (max - min) + min;
  return clipTo!T(res);
}
static T randomNumeric(T)() if(isIntegral!T) {
  return randomNumeric(T.min, T.max);
}

private:

alias uint UIntType;
static Random sGen;

shared static this() {
  sGen = Mt19937(unpredictableSeed);
}

unittest {
  auto GenBackup = sGen.save();
  scope(exit) sGen = GenBackup;

  auto i = 100;
  while(--i) {
    auto val = randomNumeric(0u, 1_000_000_000u);
    assert(val >= 0 && val <= 1_000_000_000u);
  }
  i = 100;
  while(--i) {
    auto val = randomNumeric(-1_000_000_000, 1_000_000_000);
    assert(val >= -1_000_000_000 && val <= 1_000_000_000);
  }
  auto sizetVal = randomNumeric!size_t();
}
