/**
   Random generators
   Template wrappers around std.random.
*/
module quickcheck.detail.random;

private {
  import std.random;
  import std.traits;
  debug import std.stdio : writeln, writefln;

  import quickcheck.detail.conv;
}

package:
// debug=RANDOM;

T unitRandom(T)() if(isFloatingPoint!T) {
  real res = sGen.front;
  sGen.popFront;
  res /= (UIntType.max - UIntType.min);
  debug(RANDOM) writefln("randomNumeric!%s res:%s", typeid(T), res);
  return res;
}

T randomNumeric(T, T2)(T2 min, T2 max) if(isNumeric!T && !is(T == T2)) {
  auto res = unitRandom!(real);
  res = res * max - res * min + min;
  return clipTo!T(res);
}
T randomNumeric(T)() if(isNumeric!T) {
  return randomNumeric!(T)(T.min, T.max);
}
T randomNumeric(T)(T min, T max) if(isNumeric!T) {
  auto res = unitRandom!(real);
  res = res * max - res * min + min;
  return clipTo!T(res);
}

T randomChar(T)() {
  T res;
  do {
    res = clipTo!T(randomNumeric(cast(uint)T.min, cast(uint)T.max));
  } while (res == T.init);
  return res;
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
