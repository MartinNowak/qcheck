module qcheck.quickcheck;

private {
  import std.conv : to;
  import std.datetime;
  import std.traits;
  import std.typecons;
  import std.typetuple;
  import std.stdio;
  import std.exception;
  import core.exception : AssertError;

  import qcheck.arbitrary;
  import qcheck.exceptions;
  import qcheck.policies;
  import qcheck.predicate;
}

bool quickCheck(alias Testee, TL...)() {
  alias TypeTuple!(staticMap!(Unqual, ParameterTypeTuple!Testee)) TP;
  enum TestCount = CountT!(TL).val;
  enum KeepGoing = hasPolicy!(Policies.KeepGoing, TL);

  size_t tested = 0;
  size_t rejected = 0;
  alias Tuple!(size_t, Tuple!TP, string) FailPair;

  FailPair[] failingParams;
  Tuple!TP params;

  StopWatch sw;
  double totalTime = 0.0;
  while (tested < TestCount) {
    try {
      params = getArbitraryTuple!(Tuple!TP, TL)();
      sw.reset();
      sw.start();
      auto result = Testee(params.tupleof);
      sw.stop();

      if (result == QCheckResult.Fail) {
        failingParams ~= FailPair(tested, params, Identifier!Testee ~ " false");
        totalTime += sw.peek().hnsecs;
        ++tested;
      } else if (result == QCheckResult.Ok) {
        writef("prop %s: %s \r", Identifier!Testee, tested);
        stdout.flush();
        totalTime += sw.peek().hnsecs;
        ++tested;
      } else if (result == QCheckResult.Reject) {
        ++rejected;
      }
      else {
        assert(0, "Unexpected return value " ~ to!string(result));
      }
    } catch(AssertError e) {
      failingParams ~= FailPair(tested, params, to!string(e));
      if (!KeepGoing) break;
    } catch(Exception e) {
      failingParams ~= FailPair(tested, params, to!string(e));
      if (!KeepGoing) break;
    }
  }
  if (failingParams.length == 0) {
    auto total = tested + rejected;
    writef("prop %s: passed (%s/%s), rejected (%s/%s) OK \n",
           Identifier!Testee, tested, total, rejected, total);
  } else {
    writef("prop %s: failed \n", Identifier!Testee);
    writeln("Failing parameters ", failingParams);
  }
  if (tested)
    writefln("avgTime:%f hnsecs", totalTime / tested);

  return failingParams.length == 0;
}

private:

template Identifier(alias Testee) {
  enum Identifier = __traits(identifier, Testee);
}

string Arguments(TP)(TP params) {
  string res;
  foreach (i, e; params.field) {
    res ~= to!string(i) ~ ": " ~ to!string(e) ~ ", ";
  }
  return res;
}

string formatErrMessage(string identifier, string params, int count) {
  return "\nFailed property: \"" ~ identifier ~
    "\" at run: " ~ to!string(count) ~ " with arguments\n" ~ params;
}
