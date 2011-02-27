module qcheck.exceptions;

private {
  import std.conv : to;

  import core.exception;
}

class CyclicDepException : Exception {
  this(string s) {
    super(s);
  }
}

class PropertyException : Exception {
  this(string s) {
    super(s);
  }
}
