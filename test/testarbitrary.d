private {
  import std.stdio : writeln;
  import quickcheck._;
}

version(unittest) {

class TestClass {
  TestMember val;
}
struct TestStruct {
  TestMember val;
}

class TestMember {
  this() {
    writeln("TestMEmberCtor");
  }
  int m;
}
TestMember arbitraryU(T : TestMember)() {
  TestMember res;
  res.m = 5;
  writeln("fetched up");
  return res;
}
}

unittest {
  auto cl = getArbitrary!TestClass();
  assert(cl.val is null);
  cl = getArbitrary!(TestClass, Ctor.Any, Init.Members)();
  assert(!(cl.val == null));
  //  mixin arbitraryM!(TestClass, Ctor.Any, Init.Members);
  //  get();
}
