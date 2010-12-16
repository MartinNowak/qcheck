private {
  import quickcheck._;
}

version(unittest) {
  struct A {
    byte m;
    bool testMe(A a2) const {
      return &this != &a2;
    }
  }
  bool testFunc(A a1, A a2) {
    return &a1 != &a2;
  }
}

unittest {
  quickCheck!(testFunc, Policies.RandomizeMember)();
  A a;
  auto dg = &a.testMe;
  a.m = 10;
  quickCheck!(dg, Policies.RandomizeMember)();
}
