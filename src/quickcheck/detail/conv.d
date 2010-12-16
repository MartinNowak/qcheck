/**
  Conversion helper
*/
module quickcheck.detail.conv;

private {
  import std.algorithm : min, max;
  import std.traits;
}

/**
 * clips a source value to a target values maximal range.
 */
T clipTo(T, S)(S value)
if (isImplicitlyConvertible!(S, T))
{
  return cast(T) value;
}
T clipTo(T, S)(S value)
if (!isImplicitlyConvertible!(S, T)
    && isNumeric!(S) && isNumeric!(T))
{
    static if (mostNegative!(S) < 0) {
      value = max(value, mostNegative!(T));
    }
    static if (S.max > T.max) {
      value = min(value, T.max);
    }
    return cast(T) value;
}
