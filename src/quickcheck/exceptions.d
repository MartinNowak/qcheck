module quickcheck.exceptions;

private {
  import core.exception;
}

class CyclicDepException : Exception {
  this(string s) {
    super(s);
  }
}