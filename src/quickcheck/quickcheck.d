module quickcheck.quickcheck;

private {
  import std.traits;
  import std.typecons;
  import std.typetuple;
  import std.stdio;
  import std.exception;
  import core.exception : AssertError;

  import quickcheck.arbitrary;
  import quickcheck.exceptions;
  import quickcheck.policies;
}

bool quickCheck(alias Testee, TL...)() {
  alias TypeTuple!(staticMap!(Unqual, ParameterTypeTuple!Testee)) TP;
  enum TestCount = CountT!(TL).val;
  enum KeepGoing = hasPolicy!(Policies.KeepGoing, TL);

  auto i = 0;
  alias Tuple!(size_t, Tuple!TP, string) FailPair;

  FailPair[] failingParams;
  Tuple!TP params;

  while (i < TestCount) {
    try {
      params = getArbitraryTuple!(Tuple!TP, TL)();
      // TODO: add parameter predicate
      if (!Testee(params.tupleof))
        failingParams ~= FailPair(i, params, Identifier!Testee ~ " false");
      writef("prop %s: %s \r", Identifier!Testee, i);
      stdout.flush();
      ++i;
    } catch(AssertError e) {
      failingParams ~= FailPair(i, params, to!string(e));
      if (!KeepGoing) break;
    } catch(Exception e) {
      failingParams ~= FailPair(i, params, to!string(e));
      if (!KeepGoing) break;
    }
  }
  if (failingParams.length == 0) {
    writef("prop %s: %s passed \n", Identifier!Testee, i);
    return true;
  } else {
    writef("prop %s: failed \n", Identifier!Testee);
    writeln("Failing parameters ", failingParams);
    return false;
  }
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
