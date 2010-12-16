module quickcheck.detail.tuple;

private {
  import std.traits : isTypeTuple;
  import std.typecons;

  import quickcheck.detail.arbitrary;
  import quickcheck.policies;
}

Tuple!T constructTuple
(Ctor cp, Init ip, T...)
()
if(isTypeTuple!T)
{
  Tuple!T res;
  initTuple!(cp, ip)(res);
  return res;
}

/**
 * For empty parameter type tuples
 */
void constructTuple
(Ctor cp, Init ip)
()
{
}

void initTuple
(Ctor cp, Init ip, T...)
(ref T ts)
{
  foreach(i, _; ts) {
    ts[i] = arbitrary!(T[i], cp, ip).get();
  }
}

