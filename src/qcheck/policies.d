module qcheck.policies;

private {
  import std.conv : to;
  import std.typetuple;
  import std.traits : isCallable;
  import std.typecons;
}

public:

enum Policies
{
  AnyCtor,     // Will randomly call any available constructor.
  DefaultCtorsOnly, // Will only construct default constructible structs/classes.
  RandomizeMembers,
  KeepGoing,
}

Count count(size_t val) {
  return Count(val);
}
MaxAlloc maxAlloc(size_t val) {
  return MaxAlloc(val);
}
MinValue minValue(T)(T val) {
  return MinValue(to!real(val));
}
MaxValue maxValue(T)(T val) {
  return MaxValue(to!real(val));
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

template CallablesT(TL...) {
  static if (isCallable!(typeof(TL[0])))
    alias TypeTuple!(TL[0], CallablesT!(TL[1..$])) CallablesT;
  else
    alias CallablesT!(Erase!TL) CallablesT;
}

template CallablesT() {
  alias TypeTuple!() CallablesT;
}

template hasPolicy(alias Policy, Policies...) {
  enum hasPolicy = staticIndexOf!(Policy, Policies) != -1;
}

template CountT() {
  enum CountT = Count.init;
}
template CountT(TL...) {
  static if (is(typeof(TL[0]) : Count))
    enum CountT = TL[0];
  else
    enum CountT = CountT!(TL[1..$]);
}

template MaxAllocT() {
  enum MaxAllocT = MaxAlloc.init;
}
template MaxAllocT(TL...) {
  static if (is(typeof(TL[0]) : MaxAlloc))
    enum MaxAllocT = TL[0];
  else
    enum MaxAllocT = MaxAllocT!(TL[1..$]);
}

template MaxValueT() {
  enum MaxValueT = MaxValue.init;
}
template MaxValueT(TL...) {
  static if (is(typeof(TL[0]) : MaxValue))
    enum MaxValueT = TL[0];
  else
    enum MaxValueT = MaxValueT!(TL[1..$]);
}

template MinValueT() {
  enum MinValueT = MinValue.init;
}
template MinValueT(TL...) {
  static if (is(typeof(TL[0]) : MinValue))
    enum MinValueT = TL[0];
  else
    enum MinValueT = MinValueT!(TL[1..$]);
}

private:

struct MaxAlloc {
  size_t val = 100;
}
struct Count {
  size_t val = 100;
}
struct MinValue {
  real val = -1e6;
}
struct MaxValue {
  real val = 1e6;
}

unittest {
  alias PoliciesT!(bool, Policies.AnyCtor, Policies.RandomizeMembers, 5) test;
}
