module quickcheck.policies;

public:

enum Ctor
{
  Any,     // Will randomly call any available constructor.
  Default, // Will only construct default constructible structs/classes.
}

enum Init
{
  Params, // Will only initialize paramteres need for constructor.
  Members, // Will randomly initialize all members.
}
