/**
   Random generators
   Template wrappers around std.random.
*/
module qcheck.detail.random;

private {
  import std.random;
  import std.traits;
  debug import std.stdio : writeln, writefln;

  import qcheck.detail.conv;
}

@property void randomSeed(uint seed)
{
    sGen = Random(seed);
}

package:
// debug=RANDOM;

T randomNumeric(T)() if(isNumeric!T) {
  return randomNumeric!(T)(T.min, T.max);
}

T randomNumeric(T)(T lo, T hi) if(isNumeric!T)
in {
  assert(hi >= lo);
 } body {
  return hi == lo ? hi : uniform!"[]"(lo, hi, sGen);
}

T randomChar(T)() {
  T res;
  do {
    res = clipTo!T(randomNumeric(cast(uint)T.min, cast(uint)T.max));
  } while (res == T.init);
  return res;
}

private:

static Random sGen;

static this()
{
    sGen = Random(unpredictableSeed);
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
