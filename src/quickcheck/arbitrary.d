module quickcheck.arbitrary;

private {
  import std.algorithm;
  import std.array;
  import std.traits;
  import std.typecons;
  import std.typetuple;
  import std.conv : to;
  debug import std.stdio;

  import quickcheck.detail.random;
}

public:

enum Ctor
{
  Any,     // Will randomly call any available constructor.
  Default, // Will only construct default constructible structs/classes.
}

enum Init
{
  Params, // Will only initialize paramteres need for constructor.
  Members, // Will randomly initialize all members.
}

T getArbitrary
(T, Ctor cp = Ctor.Any, Init ip = Init.Params)
()
in {
  auto info = typeid(T);
  assert(sRecursed.find(info).empty,
         "Recursive call of getArbitrary!("~
         to!string(typeid(T))~")()");
  sRecursed ~= info;
}
out {
  sRecursed.popBack;
}
body {
  mixin arbitraryM!(T, cp, ip);
  return get();
}

/**
 * To check cyclic calls at runtime.
 */
debug static TypeInfo[] sRecursed;

mixin template arbitraryM
(T, Ctor cp = Ctor.Any, Init ip = Init.Params)
{
  T get() {
    static if (is(typeof(arbitraryU!T()) : T)) {
      return arbitraryU!T();
    } else {
      mixin arbitraryLM!(T, cp, ip);
      return get();
    }
  }
}

T constructTuple
(Ctor cp, Init ip, T)
()
if(isTypeTuple!T)
{
  T res;
  initTuple!(cp, ip)(res);
  return res;
}

void initTuple
(Ctor cp, Init ip, T...)
(ref T ts)
{
  foreach(i, _; ts) {
    mixin arbitraryM!(T[i], cp, ip);
    ts[i] = get();
  }
}

mixin template arbitraryLM
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

mixin template arbitraryLM
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

  auto ctorParams = constructTuple!(cp, ip, TP)();
  return new T(ctorParams);
}


version(unittest) {
class TestClass {
  uint val;
  this(Tuple!(uint)) {
    this.val = 1;
  }
  this(Tuple!(uint, uint)) {
    this.val = 2;
  }
  this(Tuple!(uint, uint, uint)) {
    this.val = 3;
  }
  this(Tuple!(uint, uint, uint, uint)) {
    this.val = 4;
  }
}
}
unittest {
  auto inst1 = getArbitrary!(TestClass)();
  auto i = 0;
  while (inst1.val == getArbitrary!(TestClass)().val) {
    //! very unlikely
    assert(++i < 100);
  }
}

////////////////////////////////////////////////////////////////////////////////
// Interface implementation, tries at runtime to find default
// constructible implementations of interface.
////////////////////////////////////////////////////////////////////////////////

mixin template arbitraryLM
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

mixin template arbitraryLM
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

mixin template arbitraryLM
(T : bool, Ctor cp, Init ip)
{
  bool get() {
    return randomNumeric!(int)() < 0;
  }
}
