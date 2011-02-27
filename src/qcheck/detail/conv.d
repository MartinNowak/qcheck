/**
  Conversion helper
*/
module qcheck.detail.conv;

private {
  import std.algorithm : min, max;
  import std.traits;
}

/**
 * clips a source value to a target values maximal range.
 */
T clipTo(T, S)(S value)
{
    static if (mostNegative!(S) < mostNegative!(T)) {
      value = max(value, mostNegative!(T));
    }
    static if (S.max > T.max) {
      value = min(value, T.max);
    }
    return cast(T) value;
}
