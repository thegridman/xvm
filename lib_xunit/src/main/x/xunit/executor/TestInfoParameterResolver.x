/**
 * A `ParameterResolver` that will resolve a `Parameter` that takes a `TestInfo`.
 */
const TestInfoParameterResolver
        implements ParameterResolver
        implements Stringable
    {
    static String name = "TestInfoParameterResolver";

    @Override
    <ParamType> conditional ParamType resolve(ExecutionContext context, Parameter<ParamType> param)
        {
        if (ParamType == TestInfo)
            {
            return True, new TestInfo(context);
            }
        return False;
        }

    // ----- Stringable methods --------------------------------------------------------------------

    @Override
    Int estimateStringLength()
        {
        return name.estimateStringLength();
        }

    @Override
    Appender<Char> appendTo(Appender<Char> buf)
        {
        return name.appendTo(buf);
        }
    }
