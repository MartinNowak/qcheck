module quickcheck.arbitrary;

private {
  import std.array;
  import std.algorithm : find;

  import quickcheck.detail.arbitrary;
  import quickcheck.policies;
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
  return arbitrary!(T, cp, ip).get();
}
