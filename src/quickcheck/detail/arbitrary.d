module quickcheck.detail.arbitrary;

private {
  import std.algorithm : find;
  import std.array;
  import std.traits;
  import std.typecons;
  import std.typetuple;
  import std.conv : to;
  debug import std.stdio;

  import quickcheck.detail.random;
  import quickcheck.detail.conv;
  import quickcheck.policies;
  import quickcheck.exceptions;
}


struct Builder(T, TL...)
{
  alias PoliciesT!(TypeTuple!(TL, DefaultPolicies)) Poli;
  alias CallablesT!TL UserCtors;
  enum SizeV = SizeT!(TL).val;
  enum MinValueV = MinValueT!(TL).val;
  enum MaxValueV = MaxValueT!(TL).val;

  static if (UserCtors.length)
    alias staticMap!(ReturnType, UserCtors) UserTypes;
  else
    alias TypeTuple!() UserTypes;

  //! To detect recursive calls at runtime
  TypeInfo[] sRecursed;

  T get() {
    return internalGet!(T)();
  }

  T2 internalGet(T2)() {
    auto info = typeid(T2);
    if (!this.sRecursed.find(info).empty)
      throw new CyclicDepException("Recursive call of getArbitrary!("~
                                   to!string(typeid(T))~")()");
    this.sRecursed ~= info;
    scope(exit) this.sRecursed.popBack;

    enum UserIdx = staticIndexOf!(T2, UserTypes);
    static if (UserIdx != -1) {
      alias UserCtors[UserIdx] Ctor;
      static assert(isCallable!(Ctor), to!string(Ctor)~" is not callable");
      return callUserFunc!(T2, Ctor)();
    } else {
      return arbitraryL!(T2).get();
    }
  }

  /**
   * Call a user defined function to instantiate a T.
   */
  T callUserFunc(T, alias Ctor)() {
    alias staticMap!(Unqual, ParameterTypeTuple!(Ctor)) TP;

    static if (TP.length == 0)
      return Ctor();
    else {
      auto ctorParams = constructTuple!(TP)();
      return Ctor(ctorParams.tupleof);
    }
  }

  /**
   * Instante a struct, choose a random ctor overload.
   */
  template arbitraryL(T) if(is(T == struct)) {
    T get() {
      auto t = newStructInstance!(T)();
      static if (hasPolicy!(Policies.RandomizeMembers, Poli))
        this.initTuple(t.tupleof);
      return t;
    }
  }

  /**
   * Instante a class, choose a random ctor overload.
   */
  template arbitraryL(T) if(is(T == class)) {
    T get() {
      auto newInst = newClassInstance!(T)();
      static if (hasPolicy!(Policies.RandomizeMembers, Poli)) {
        if (newInst) {
          initTuple(newInst.tupleof);
        }
      }
      return newInst;
    }
  }

  /**
   * Interface implementation, tries at runtime to find default
   * constructible implementations of interface.
   */
  template arbitraryL(T) if(is(T == interface)) {
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

  /**
   * Instante a static array.
   */
  template arbitraryL(T) if(isStaticArray!T) {
    T get() {
      alias Unqual!(typeof(T[0])) ElemT;

      auto count = T.length;
      T res;
      while (count--) {
        res[count] = internalGet!(ElemT)();
      }
      return res;
    }
  }

  /**
   * Instante an array.
   */
  template arbitraryL(T) if(isDynamicArray!T) {
    T get() {
      alias Unqual!(typeof(T[0])) ElemT;

      auto count = randomNumeric(0u, SizeV);
      T res;
      while (count--) {
        res ~= internalGet!(ElemT)();
      }
      return res;
    }
  }

  /**
   * Instante an array.
   */
  template arbitraryL(T) if(isAssociativeArray!T) {
    T get() {
      alias typeof(T.init.keys[0]) KeyT;
      alias typeof(T.init.values[0]) ValueT;

      auto count = randomNumeric(0u, SizeV);
      T res;
      while (count--) {
        auto key = internalGet!(KeyT)();
        auto value = internalGet!(ValueT)();
        res[key] = value;
      }
      return res;
    }
  }

  /**
   * Default char
   */
  template arbitraryL(T) if(is(T == dchar) || is(T == wchar)
                            || is(T == char)) {
    T get() {
      return randomChar!(T)();
    }
  }

  /**
   * Default numerical types
   */
  template arbitraryL(T) if(isNumeric!T) {
    T get() {
      return randomNumeric!(T)(clipTo!T(MinValueV), clipTo!T(MaxValueV));
    }
  }

  /**
   * Bool type
   */
  template arbitraryL(T) if(is(T == bool)) {
    bool get() {
      return randomNumeric!(int)() < 0;
    }
  }

  /**
   * Enums
   */
  template arbitraryL(T) if(is(T == enum)) {
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

private:

  // struct instantiation helper

  T newStructInstance(T)() {
    alias ctorOverloadSet!(T) overloads;

    static if (hasPolicy!(Policies.AnyCtor, Poli))
      alias overloads Ctors;
    else
      alias FilterDefaultCtor!(overloads) Ctors;

    auto which = randomNumeric(0u, Ctors.length - 1);
    return this.callStructCtorOverload!(T, Ctors)(which);
  }

  T callStructCtorOverload(T)(uint idx) {
    return T();
  }

  T callStructCtorOverload(T, Overloads...)(uint idx) {
    foreach(i,ctor; Overloads) {
      if (i == idx)
        return callStructCtor!(T, ctor)();
    }
    assert(0, "ctor index out of range");
  }

  T callStructCtor(T, ctorType)() {
    alias staticMap!(Unqual, ParameterTypeTuple!(ctorType)) TP;

    static if (TP.length == 0)
      return T();
    else {
      auto ctorParams = constructTuple!(TP)();
      return T(ctorParams.tupleof);
    }
  }

  // class instantiation helper

  T newClassInstance(T)() {
    alias ctorOverloadSet!(T) overloads;

    static if (hasPolicy!(Policies.AnyCtor, Poli))
      alias overloads Ctors;
    else
      alias FilterDefaultCtor!(overloads) Ctors;

    auto which = randomNumeric(0u, Ctors.length - 1);
    return callClassCtorOverload!(T, Ctors)(which);
  }

  T callClassCtorOverload(T)(uint idx) {
    return new T();
  }

  T callClassCtorOverload(T, Overloads...)(uint idx) {
    foreach(i,ctor; Overloads) {
      if (i == idx)
        return callClassCtor!(T, ctor)();
    }
    assert(0, "ctor index out of range");
  }

  T callClassCtor(T, ctorType)() {
    alias staticMap!(Unqual, ParameterTypeTuple!(ctorType)) TP;

    static if (TP.length == 0)
      return new T();
    else {
      auto ctorParams = constructTuple!(TP)();
      return new T(ctorParams.tupleof);
    }
  }

  // Tuple helpers

  Tuple!T constructTuple(T...)() if(isTypeTuple!T) {
    Tuple!T res;
    initTuple(res);
    return res;
  }

  /**
   * For empty parameter type tuples
   */
  void constructTuple()() {
  }

  void initTuple(T...)(ref T ts) {
    foreach(i, _; ts) {
      ts[i] = internalGet!(T[i])();
    }
  }

}

private:

template ctorOverloadSet
(T)
{
  static if (__traits(hasMember, T, "__ctor"))
    alias typeof(__traits(getOverloads, T, "__ctor")) ctorOverloadSet;
  else
    alias TypeTuple!() ctorOverloadSet; // empty
}

template FilterDefaultCtor
(TL...)
{
  static if (TL.length) {
    static if (ParameterTypeTuple!(TL[0]).length > 0)
      alias FilterDefaultCtor!(Erase!TL) FilterDefaultCtor;
    else
      alias TypeTuple!(TL[0], FilterDefaultCtor!TL[1..$]) FilterDefaultCtor;
  }
  else {
    alias TypeTuple!() FilterDefaultCtor;
  }
}
