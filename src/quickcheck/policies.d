module quickcheck.policies;

private {
  import std.typetuple;
  import std.typecons;
}

public:

enum Policies
{
  AnyCtor,     // Will randomly call any available constructor.
  DefaultCtorsOnly, // Will only construct default constructible structs/classes.
  RandomizeMember,
}

package:

alias TypeTuple!(Policies.AnyCtor) DefaultPolicies;

template PoliciesT(TL...) {
  static if (is(typeof(TL[0]) == Policies)) {
    alias TypeTuple!(TL[0], PoliciesT!(TL[1..$])) PoliciesT;
  }
  else {
    alias PoliciesT!(Erase!TL) PoliciesT;
  }
}
template PoliciesT() {
  alias TypeTuple!() PoliciesT;
}

template NonPoliciesT(TL...) {
  static if (!is(typeof(TL[0]) == Policies))
    alias TypeTuple!(TL[0], NonPoliciesT!(TL[1..$])) NonPoliciesT;
  else
  alias NonPoliciesT!(Erase!TL) NonPoliciesT;
}

template NonPoliciesT() {
  alias TypeTuple!() NonPoliciesT;
}

template hasPolicy(alias Policy, Policies...) {
  enum hasPolicy = staticIndexOf!(Policy, Policies) != -1;
}

unittest {
  alias PoliciesT!(bool, Policies.AnyCtor, Policies.RandomizeMember, 5) test;
}