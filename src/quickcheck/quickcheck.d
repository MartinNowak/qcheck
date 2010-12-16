module quickcheck.quickcheck;

private {
  import std.traits;
  import std.typecons;
  import std.typetuple : staticMap;
  import std.stdio;

  import quickcheck.arbitrary;
  import quickcheck.exceptions;
}

void quickCheck(alias Testee, TL...)() {
  alias Tuple!(staticMap!(Unqual, ParameterTypeTuple!Testee)) TP;

  enum TestCount = 1_000;
  auto i = 0;
  while (i < TestCount) {
    auto params = getArbitrary!(TP, TL)();
    // TODO: add parameter predicate
    if (!Testee(params.tupleof)) {
      throw new PropertyException(formatErrMessage(Identifier!Testee, Arguments(params), i));
    }
    ++i;
  }
  writeln(formatSuccessMessage(Identifier!Testee, TestCount));
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
    "\" at run: " ~ to!string(count) ~ " with arguments:" ~ params;
}

string formatSuccessMessage(string identifier, int count) {
  return "Passed property: \"" ~ identifier ~
    "\" after: " ~ to!string(count) ~ " tests";
}