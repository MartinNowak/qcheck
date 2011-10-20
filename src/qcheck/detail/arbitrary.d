module qcheck.detail.arbitrary;

import std.algorithm, std.array, std.conv, std.exception, std.traits, std.typecons, std.typetuple;
import qcheck.detail.conv, qcheck.detail.random, qcheck.config, qcheck.exceptions;

struct Builder(T, Generators...)
{
    Config _config;
    //! To detect recursive calls at runtime
    TypeInfo[] _recursed;

    static if (Generators.length)
        alias staticMap!(ReturnType, Generators) UserTypes;
    else
        alias TypeTuple!() UserTypes;

    /**
     * Construct a randomized instance of T.
     */
    T get()
    {
        return internalGet!(T)();
    }

    T2 internalGet(T2)()
    {
        auto info = typeid(T2);

        // @@ BUG @@
        version (none)
        {
            // clobbers global.errors during speculative instantiation of
            // isBidirectionalRange!(typeof(info))
            enforceEx!CyclicDependencyException(!_recursed.canFind(info),
                                                "Recursive call of getArbitrary!("~T.stringof~")()");
        }
        else
        {
            foreach(ti; _recursed)
            {
                if (ti == info)
                    throw new CyclicDependencyException(
                        "Recursive call of getArbitrary!("~T.stringof~")()");
            }
        }

        _recursed ~= info;
        scope(exit) _recursed.popBack;

        enum UserIdx = staticIndexOf!(T2, UserTypes);
        static if (UserIdx != -1)
        {
            alias Generators[UserIdx] Ctor;
            static assert(isCallable!(Ctor), "Generator "~to!string(Ctor)~" is not callable.");
            return callUserFunc!(T2, Ctor)();
        }
        else
        {
            return arbitraryL!(T2).get();
        }
    }

    /**
     * Call a user defined function to instantiate a T.
     */
    T callUserFunc(T, alias Ctor)()
    {
        alias staticMap!(Unqual, ParameterTypeTuple!(Ctor)) TP;

        static if (TP.length == 0)
            return Ctor();
        else
        {
            auto ctorParams = constructTuple!(TP)();
            return Ctor(ctorParams.tupleof);
        }
    }

    /**
     * Instantiate a struct, choose a random ctor overload.
     */
    template arbitraryL(T) if(is(T == struct))
    {
        T get()
        {
            auto t = newStructInstance!(T)();
            if (_config.randomizeFields)
                this.initTuple(t.tupleof);
            return t;
        }
    }

    /**
     * Instantiate a class, choose a random ctor overload.
     */
    template arbitraryL(T) if(is(T == class))
    {
        T get() {
            T inst = newClassInstance!(T)();
            if (_config.randomizeFields && inst !is null)
            {
                initTuple(inst.tupleof);
            }
            return inst;
        }
    }

    /**
     * Interface implementation, tries at runtime to find default
     * constructible implementations of interface.
     */
    template arbitraryL(T) if(is(T == interface))
    {
        //! Might return null, if not implemented or not default
        //! constructible.
        T get()
        {
            T result;

            auto implementors =
                findClasses((ClassInfo ci) { return inherits(ci, T.classinfo); } );

            if (implementors.length)
            {
                auto rndIdx = randomNumeric(0u, implementors.length - 1);
                auto name = implementors[rndIdx].name;
                result = cast(T)Object.factory(name);
            }
            return result;
        }
    }

    /**
     * Instantiate a static array.
     */
    template arbitraryL(T) if(isStaticArray!T)
    {
        T get()
        {
            alias Unqual!(typeof(T[0])) ElemT;

            auto count = T.length;
            T res = void;
            while (count--)
            {
                ElemT e = internalGet!(ElemT)();
                move(e, res[count]);
            }
            return res;
        }
    }

    /**
     * Instantiate an array.
     */
    template arbitraryL(T) if(isDynamicArray!T)
    {
        T get()
        {
            alias Unqual!(typeof(T[0])) ElemT;

            auto count = randomNumeric(cast(size_t)0, _config.maxSize);
            T res;
            res.reserve(count);
            while (count--)
                res ~= internalGet!(ElemT)();
            return res;
        }
    }

    /**
     * Instantiate an array.
     */
    template arbitraryL(T) if(isAssociativeArray!T)
    {
        T get()
        {
            alias typeof(T.init.keys[0]) KeyT;
            alias typeof(T.init.values[0]) ValueT;

            auto count = randomNumeric(cast(size_t)0, _config.maxSize);
            T res;
            while (count--)
            {
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
  template arbitraryL(T) if(is(T == dchar) || is(T == wchar) || is(T == char))
  {
      T get()
      {
          return randomChar!(T)();
      }
  }

  /**
   * Default numerical types
   */
  template arbitraryL(T) if(isNumeric!T)
  {
      T get()
      {
          return randomNumeric!(T)(clipTo!T(_config.minValue), clipTo!T(_config.maxValue));
      }
  }

    /**
     * Bool type
     */
    template arbitraryL(T) if(is(T == bool))
    {
        bool get()
        {
            return randomNumeric!(int)() < 0;
        }
    }

    /**
     * Enums
     */
    template arbitraryL(T) if(is(T == enum))
    {
        T get() {
            alias EnumMembers!T EnumTuple;
            auto idx = randomNumeric!(size_t)(cast(size_t)0, EnumMembers!T.length - 1);
            switch (idx)
            {
            foreach(i, v; EnumMembers!T)
            case i:
                return v;

            default:
                assert(0);
            }
        }
    }

    /**
     * Complex types
     */
    template isComplex(T)
    {
        enum bool isComplex = staticIndexOf!(Unqual!(T),
                                             cfloat, cdouble, creal) >= 0;
    }

    template arbitraryL(T) if(isComplex!T)
    {
        T get()
        {
            return internalGet!(typeof(T.re))() + 1i * internalGet!(typeof(T.im))();
        }
    }

private:

    // struct instantiation helper
    T newStructInstance(T)()
    {
        if (_config.ctors == Config.Ctors.DefaultOnly)
        {
            static if (is(typeof(T())))
                assert(0, "Can't default construct a " ~ T.stringof);
            else
                return T();
        }
        else if (_config.ctors == Config.Ctors.Any)
        {
            alias ctorOverloadSet!(T) overloads;
            auto which = overloads.length ? randomNumeric(cast(size_t)0, overloads.length - 1) : 0;
            return callStructCtorOverload!(T, overloads)(which);
        }
        else
            assert(0);
    }

    T callStructCtorOverload(T, Overloads...)(size_t idx)
    {
        switch (idx)
        {
        foreach(i,ctor; Overloads)
        case i:
            return callStructCtor!(T, ctor)();

        default:
            assert(0);
        }
    }

    T callStructCtorOverload(T)(size_t idx)
    {
        return T();
    }

    T callStructCtor(T, ctorType)()
    {
        alias staticMap!(Unqual, ParameterTypeTuple!(ctorType)) TP;

        static if (TP.length == 0)
            return T();
        else
        {
            auto ctorParams = constructTuple!(TP)();
            return T(ctorParams.tupleof);
        }
    }

    // class instantiation helper
    T newClassInstance(T)()
    {
        if (_config.ctors == Config.Ctors.DefaultOnly)
        {
            static if (!is(typeof(new T())))
                assert(0, "Can't default construct class " ~ T.stringof);
            else
                return new T();
        }
        else if (_config.ctors == Config.Ctors.Any)
        {
            alias ctorOverloadSet!(T) overloads;
            auto which = overloads.length ? randomNumeric(cast(size_t)0,  overloads.length - 1) : 0;
            return callClassCtorOverload!(T, overloads)(which);
        }
        else
            assert(0);
    }

    T callClassCtorOverload(T)(size_t idx)
    {
        return new T();
    }

    T callClassCtorOverload(T, Overloads...)(size_t idx)
    {
        switch (idx)
        {
        foreach(i, ctor; Overloads)
        case i:
            return callClassCtor!(T, ctor)();

        default:
            assert(0);
        }
    }

    T callClassCtor(T, ctorType)()
    {
        alias staticMap!(Unqual, ParameterTypeTuple!(ctorType)) TP;

        auto ctorParams = constructTuple!(TP)();
        return new T(ctorParams.tupleof);
    }

    // Tuple helpers
    Tuple!T constructTuple(T...)() if(isTypeTuple!T)
    {
        Tuple!T res;
        initTuple(res.tupleof);
        return res;
    }

    void initTuple(TS...)(ref TS ts)
    {
        foreach(i, T; TS)
            ts[i] = internalGet!T();
    }
}

private:

template ctorOverloadSet(T)
{
    static if (__traits(hasMember, T, "__ctor"))
        alias typeof(__traits(getOverloads, T, "__ctor")) ctorOverloadSet;
    else
        alias TypeTuple!() ctorOverloadSet; // empty
}
