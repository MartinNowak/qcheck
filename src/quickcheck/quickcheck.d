module quickcheck.quickcheck;

private {
  import std.traits;
  import std.typecons;
  import std.typetuple;
  import std.stdio;

  import quickcheck.arbitrary;
  import quickcheck.exceptions;
  import quickcheck.policies;
}

void quickCheck(alias Testee, TL...)() {
  alias TypeTuple!(staticMap!(Unqual, ParameterTypeTuple!Testee)) TP;

  enum TestCount = 1_000;
  auto i = 0;
  while (i < TestCount) {
    auto params = getArbitrary!(Tuple!TP, TL, Policies.RandomizeMembers)();
    // TODO: add parameter predicate
    if (!Testee(params.tupleof)) {
      throw new PropertyException(formatErrMessage(Identifier!Testee, Arguments(params), i));
    }
    writef("prop %s: %s \r", Identifier!Testee, i);
    stdout.flush();
    ++i;
  }
  writef("prop %s: %s passed \n", Identifier!Testee, i);
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
