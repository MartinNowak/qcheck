/**
 * Find classinfos at runtime.
 */
module quickcheck.detail.runtimeclass;

package:

/**
 * Helper that collects all classinfos from known modules for which
 * pred returns true.
 */
ClassInfo[] findClasses(bool delegate(ClassInfo) pred) {
  ClassInfo[] derived;
  foreach(m; ModuleInfo) {
    foreach(c; m.localClasses) {
      if (pred(c))
        derived ~= c;
    }
  }
  return derived;
}


/****************************************
  Predicates
*/

/**
 * Returns true if base is a baseclass of derived.
 */
bool isDerived(ClassInfo derived, ClassInfo base) {
  while (derived.base) {
    derived = derived.base;
    if (base is derived)
      return true;
  }
  return false;
}

/**
 * Returns true if derived implements the interface interf.
 */
bool implements(ClassInfo derived, ClassInfo interf) {
  foreach(ci; derived.interfaces) {
    if (ci.classinfo is interf)
      return true;
  }
  return false;
}

/**
 * Returns true if derived or any of it's base classes implements the
 * interface interf.
 */
bool inherits(ClassInfo derived, ClassInfo interf) {
  while (derived) {
    if (implements(derived, interf))
      return true;
    derived = derived.base;
  }
  return false;
}


version(unittest) {
  class Base {}
  class Derived : Base {}
  interface IBase {}
  class IImpl : IBase {}
  class IImpl2 : IImpl {}
}

unittest {
  auto classDerivatives =
    findClasses((ClassInfo c) { return isDerived(c, Base.classinfo); } );
  assert(classDerivatives == [Derived.classinfo]);

  auto interfaceDerivatives =
    findClasses((ClassInfo c) { return isDerived(c, IBase.classinfo); } );
  assert(interfaceDerivatives.length == 0);

  auto immediateImpls =
    findClasses((ClassInfo c) { return implements(c, IBase.classinfo); } );
  assert(immediateImpls == [IImpl.classinfo]);

  auto allInterfaceClasses =
    findClasses((ClassInfo c) { return inherits(c, IBase.classinfo); } );
  assert(allInterfaceClasses == [IImpl.classinfo, IImpl2.classinfo]);
}
