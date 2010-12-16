module quickcheck.arbitrary;

private {
  import std.array;
  import std.algorithm : find;

  import quickcheck.detail.arbitrary;
  import quickcheck.policies;
}

T getArbitrary
(T, Ctor ctorPolicy = Ctor.Any, Init initPolicy = Init.Params, UserBuilder...)
()
{
  auto builder = Builder!(T, ctorPolicy, initPolicy, UserBuilder)();
  return builder.get();
}
