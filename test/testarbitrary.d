private {
  import std.conv : to, roundTo;
  import std.stdio : writeln, writefln;
  import std.math;
  import std.traits;

  import quickcheck._;
}

debug=ARBITRARY;

template maxIt(T) if(isFloatingPoint!T) {
  enum maxIt = 0;
}
template maxIt(T) if(isSigned!T && isIntegral!T) {
  enum maxIt = maxIt!(Unsigned!T);
}
template maxIt(T) if(is(T == ulong)) { enum maxIt = 0; }
template maxIt(T) if(is(T == uint)) { enum maxIt = 0; }
template maxIt(T) if(is(T == ushort)) { enum maxIt = 1; }
template maxIt(T) if(is(T == ubyte)) { enum maxIt = 1; }
template maxIt(T) if(is(T == bool)) { enum maxIt = 10; }

template testNumeric(T) {
  void run() {
    auto b0 = getArbitrary!T();
    size_t i;
    while (b0 == getArbitrary!T())
      ++i;
    assert(i <= maxIt!T);
  }
}

unittest {
  testNumeric!bool.run();
  testNumeric!ulong.run();
  testNumeric!long.run();
  testNumeric!uint.run();
  testNumeric!int.run();
  testNumeric!ushort.run();
  testNumeric!short.run();
  testNumeric!ubyte.run();
  testNumeric!byte.run();
  testNumeric!float.run();
  testNumeric!double.run();
  testNumeric!real.run();
}

version(unittest) {
  enum IntEnum {
    A = 10,
    B = 20,
    C = 30,
    D = 40,
  }
  enum BoolNum : bool {
    FALSE = false,
    TRUE = true,
  }
  struct EnumStruct {
    string name;
    this(string name) { this.name = name; }
  }
}

unittest {
  IntEnum val = getArbitrary!IntEnum();
  assert(cast(int)val % 10 == 0);
}

version(unittest) {
class TestClass {
  ClassWCtor val;
  @property string toString() {
    return "TestClass val:" ~ to!string(val);
  }
}
struct TestStruct {
  ClassWCtor val;
}

class ClassWOCtor { int m; }
class ClassWCtor {
  this() {
  }
  int m;
}

}

unittest {
  auto cl = getArbitrary!TestClass();
  assert(cl.val is null);
  cl = getArbitrary!(TestClass, Ctor.Any, Init.Members)();
  assert(!(cl.val is null));
}


version(unittest) {
class MultiCtors {
  uint val;
  this(uint) {
    this.val = 1;
  }
  this(uint, uint) {
    this.val = 2;
  }
  this(uint, uint, uint) {
    this.val = 3;
  }
  this(uint, uint, uint, uint) {
    this.val = 4;
  }
}
}
unittest {
  auto inst1 = getArbitrary!(MultiCtors)();
  auto i = 0;
  while (inst1.val == getArbitrary!(MultiCtors)().val) {
    //! very unlikely
    assert(++i < 100);
  }
}
