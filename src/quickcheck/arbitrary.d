module quickcheck.arbitrary;

private {
  import std.array;
  import std.algorithm : find;
  import std.typetuple;

  import quickcheck.detail.arbitrary;
  import quickcheck.policies;
}

T getArbitrary
(T, TL...)
()
{
  auto builder = Builder!(T, TL)();
  return builder.get();
}
