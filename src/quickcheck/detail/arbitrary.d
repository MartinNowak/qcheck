module quickcheck.detail.arbitrary;

private {
  //  import std.algorithm;
  import std.array;
  import std.traits;
  import std.typecons;
  import std.typetuple;
  import std.conv : to;
  debug import std.stdio;

  import quickcheck.detail.random;
  import quickcheck.detail.tuple;
  import quickcheck.policies;
}

/**
 * To check cyclic calls at runtime.
 */
debug static TypeInfo[] sRecursed;

template arbitrary
(T, Ctor cp = Ctor.Any, Init ip = Init.Params)
{
  T get() {
    static if (is(typeof(arbitraryU!T()) : T)) {
      return arbitraryU!T();
    } else {
      return arbitraryL!(T, cp, ip).get();
    }
  }
}

template arbitraryL
(T, Ctor cp, Init ip)
if(is(T == struct))
{
  T get() {
    // TODO: implement struct ctor lookup
    T t;
    static if (ip == Init.Members)
      initTuple!(cp, ip)(t.tupleof);
    return t;
  }
}


////////////////////////////////////////////////////////////////////////////////
// Instantiating a class, choose a random ctor overload.
////////////////////////////////////////////////////////////////////////////////

template ctorOverloadSet
(T)
{
  static if (__traits(hasMember, T, "__ctor"))
    alias typeof(__traits(getOverloads, T, "__ctor")) ctorOverloadSet;
  else
    alias TypeTuple!() ctorOverloadSet; // empty
}

template Filter
(Ctor cp, TL...)
{
  static if (cp == Ctor.Any)
    alias TL Filter;
  else
    alias EraseNonDefault!TL Filter;
}
template EraseNonDefault
(TL...)
{
  static if (ParameterTypeTuple!(TL[0]).length > 0)
    alias Erase!TL EraseNonDefault;
  else
    alias TL EraseNonDefault;
}

template arbitraryL
(T, Ctor cp, Init ip)
if(is(T == class))
{
  T get() {
    auto newInst = makeInstance!(cp, ip, T)();
    return initInstance!(cp, ip, T)(newInst);
  }
}

T makeInstance
(Ctor cp, Init ip, T)
()
{
  alias ctorOverloadSet!(T) overloads;
  static if (!overloads.length)
    return new T();

  alias Filter!(cp, overloads) Ctors;

  auto which = randomNumeric(0u, Ctors.length - 1);
  return callOverload!(T, cp, ip, Ctors)(which);
}

T initInstance
(Ctor cp, Init ip, T)
(T newInst)
{
  static if (ip == Init.Members) {
    if (newInst) {
      initTuple!(cp, ip)(newInst.tupleof);
    }
  }
  return newInst;
}

T callOverload
(T, Ctor cp, Init ip, Overloads...)
(uint idx)
{
  foreach(i,ctor; Overloads) {
    if (i == idx)
      return callCtor!(T, cp, ip, ctor)();
  }
  assert(0);
}

T callCtor
(T, Ctor cp, Init ip, ctorType)
()
{
  alias staticMap!(Unqual, ParameterTypeTuple!(ctorType)) TP;

  static if (TP.length == 0)
    return new T;
  else {
    auto ctorParams = constructTuple!(cp, ip, TP)();
    return new T(ctorParams.tupleof);
  }
}


////////////////////////////////////////////////////////////////////////////////
// Interface implementation, tries at runtime to find default
// constructible implementations of interface.
////////////////////////////////////////////////////////////////////////////////

template arbitraryL
(T, Ctor cp, Init ip)
if(is(T == interface))
{
  //! Might return null, if not implemented or not default
  //! constructible.
  T get() {
    auto implementors =
      findClasses((ClassInfo ci) { return inherits(ci, T.classinfo); } );

    if (!implementors.length)
      return null;

    auto rndIdx = randomNumeric(0u, implementors.length - 1);

    auto name = implementors[rndIdx].name;
    return cast(T)Object.factory(name);
  }
}

////////////////////////////////////////////////////////////////////////////////
// Default numerical types
////////////////////////////////////////////////////////////////////////////////

template arbitraryL
(T, Ctor cp, Init ip)
if(isNumeric!T)
{
  T get() {
    return randomNumeric!(T)();
  }
}

////////////////////////////////////////////////////////////////////////////////
// Bool type
////////////////////////////////////////////////////////////////////////////////

template arbitraryL
(T : bool, Ctor cp, Init ip)
{
  bool get() {
    return randomNumeric!(int)() < 0;
  }
}

////////////////////////////////////////////////////////////////////////////////
// Enums
////////////////////////////////////////////////////////////////////////////////

template arbitraryL
(T, Ctor cp, Init ip)
if(is(T == enum))
{
  T get() {
    alias EnumMembers!T EnumTuple;
    auto idx = randomNumeric!(size_t)(0u, EnumMembers!T.length - 1);
    foreach(i, v; EnumMembers!T) {
      if (i == idx)
        return v;
    }
    assert(0);
  }
}
