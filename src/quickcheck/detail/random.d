/**
   Random generators
   Template wrappers around std.random.
*/
module quickcheck.detail.random;

private {
  import std.random;
  import std.traits : isFloatingPoint, isIntegral, isSigned;
  debug import std.stdio : writeln, writefln;

  import quickcheck.detail.conv;
}

package:
// debug=RANDOM;

T randomNumeric(T)() if(isFloatingPoint!T) {
  real res = sGen.front;
  sGen.popFront;
  res /= (UIntType.max - UIntType.min);
  debug(RANDOM) writefln("randomNumeric!%s res:%s", typeid(T), res);
  return res;
}

T randomNumeric(T)(T min, T max) if(isIntegral!T) {
  auto res = randomNumeric!(real);
  res = res * max - res * min + min;
  return clipTo!T(res);
}
T randomNumeric(T)() if(isIntegral!T) {
  return randomNumeric(T.min, T.max);
}

private:

alias uint UIntType;
static Random sGen;

static this() {
  sGen = Mt19937(unpredictableSeed);
  debug(RANDOM) writefln("generator first %s", sGen.front);
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
