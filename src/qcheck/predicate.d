module qcheck.predicate;

//! It is okay for a testee to return a bool
enum QCheckResult
{
  Reject = -1,
  REJECT = Reject,
  Ok = true,
  OK = Ok,
  Success = Ok,
  SUCCESS = Ok,
  Fail = false,
  FAIL = Fail,
}
