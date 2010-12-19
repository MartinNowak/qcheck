module quickcheck.policies;

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
Size size(size_t val) {
  return Size(val);
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

template SizeT() {
  enum SizeT = Size.init;
}
template SizeT(TL...) {
  static if (is(typeof(TL[0]) : Size))
    enum SizeT = TL[0];
  else
    enum SizeT = SizeT!(TL[1..$]);
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

struct Size {
  this(size_t val) {
    this.val = val;
  }
  size_t val = 100;
}
struct Count {
  this(size_t val) {
    this.val = val;
  }
  size_t val = 100;
}
struct MinValue {
  this(real val) {
    this.val = val;
  }
  real val = -1e6;
}
struct MaxValue {
  this(real val) {
    this.val = val;
  }
  real val = 1e6;
}

unittest {
  alias PoliciesT!(bool, Policies.AnyCtor, Policies.RandomizeMembers, 5) test;
}
