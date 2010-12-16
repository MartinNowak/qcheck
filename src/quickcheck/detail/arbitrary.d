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
  import quickcheck.policies;
  import quickcheck.exceptions;
}


struct Builder(T, Ctor ctorPolicy, Init initPolicy, UserBuilder...)
{
  alias staticMap!(ReturnType, UserBuilder) UserTypes;

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
    scope(exit) sRecursed.popBack;

    enum UserIdx = staticIndexOf!(T2, UserTypes);
    static if (UserIdx != -1) {
      alias UserBuilder[UserIdx] Ctor;
      static assert(isCallable!(Ctor), to!string(Ctor)~" is not callable");
      return UserBuilder[UserIdx]();
    } else {
      return arbitraryL!(T2).get();
    }
  }

  template arbitraryL(T) if(is(T == struct)) {
    T get() {
      auto t = newStructInstance!(T)();
      static if (initPolicy == Init.Members)
        initTuple(t.tupleof);
      return t;
    }
  }

  /**
   * Instantiating a class, choose a random ctor overload.
   */
  template arbitraryL(T) if(is(T == class)) {
    T get() {
      auto newInst = newClassInstance!(T)();
      static if (initPolicy == Init.Members) {
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
   * Default numerical types
   */
  template arbitraryL(T) if(isNumeric!T) {
    T get() {
      return randomNumeric!(T)();
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
    alias Filter!(ctorPolicy, overloads) Ctors;

    auto which = randomNumeric(0u, Ctors.length - 1);
    return callStructCtorOverload!(T, Ctors)(which);
  }

  T callStructCtorOverload(T, Overloads...)(uint idx) {
    static if (Overloads.length == 0)
      return T();
    else {
      foreach(i,ctor; Overloads) {
        if (i == idx)
          return callStructCtor!(T, ctor)();
      }
      assert(0);
    }
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
    alias Filter!(ctorPolicy, overloads) Ctors;

    auto which = randomNumeric(0u, Ctors.length - 1);
    return callClassCtorOverload!(T, Ctors)(which);
  }

  T callClassCtorOverload(T, Overloads...)(uint idx) {
    static if (Overloads.length == 0)
      return new T();
    else {
      foreach(i,ctor; Overloads) {
        if (i == idx)
          return callClassCtor!(T, ctor)();
      }
      assert(0);
    }
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
