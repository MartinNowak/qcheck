module qcheck.exceptions;

class CyclicDependencyException : Exception
{
    this(string s, string file=__FILE__, size_t line=__LINE__)
    {
        super(s, file, line);
    }
}

class PropertyException : Exception
{
    this(string s, string file=__FILE__, size_t line=__LINE__)
    {
        super(s, file, line);
    }
}
