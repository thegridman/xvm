/**
 * A `TestTemplateFactory` for parameterized tests.
 *
 * @param parameters  the function to use to provide parameters for parameterized test
 *                    methods or parameterized test class constructors.
 */
const ParameterizedTestTemplateFactory(Function<Tuple, Tuple> parameters)
        implements TestTemplateFactory
    {
    // ---- TestTemplateFactory --------------------------------------------------------------------

    @Override
    Iterable<TestTemplateContext> getTemplates(ExecutionContext context)
        {
        List<ParameterizedTestTemplateContext> arguments = new Array();
        if (var o := context.invokeSingleResult(parameters))
            {
            if (o.is(Collection))
                {
                for (var arg : o)
                    {
                    arguments.add(new ParameterizedTestTemplateContext(createArguments(arg)));
                    }
                }
            else
                {
                arguments.add(new ParameterizedTestTemplateContext(createArguments(o)));
                }
            }
        return arguments;
        }

    /**
     * Create the arguments array for a given result from the arguments provider function.
     *
     * The arguments provider function may have returned a `Collection`, a `Tuple`, or a single
     * value. If it returned a `Collection`, the `o` parameter will be one of the values from
     * that `Collection`, which could also be a `Collection, a `Tuple`, or a single value.
     * Consequently the `o` parameter may be a `Collection`, a `Tuple`, or a single value.
     *
     * * `Collection` - each value in the `Collection` is used to create an entry in the
     *   returned `Argument` array. If an entry in the `Collection` is an `Argument` it is
     *   added directly to the argument array, otherwise it is wrapped in an `Argument`.
     *
     * * `Tuple` - each value in the `Tuple` is used to create an entry in the returned
     *   `Argument` array. If an entry in the `Collection` is an `Argument` it is added
     *    directly to the argument array, otherwise it is wrapped in an `Argument`.
     *
     * * Single value - A single value will create a single entry `Argument` array.
     *   If value is an `Argument` it is added directly to the argument array, otherwise it
     *   is wrapped in an `Argument`.
     *
     * @param o  a result from calling the arguments provider function
     *
     * @return the array of `Argument`s created from the parameter `Object`
     */
    private ParameterizedTest.Argument[] createArguments(Object o)
        {
        if (o.is(Tuple))
            {
            ParameterizedTest.Argument[] args = new Array();
            for (Int i : 0..<o.size)
                {
                Object argument = o[i];
                args[i] = new ParameterizedTest.Argument(argument, &argument.actualType);
                }
            return args;
            }
        else if (o.is(ParameterizedTest.Argument))
            {
            return [o];
            }
        return [new ParameterizedTest.Argument(o, &o.actualType)];
        }

    // ---- inner const: ParameterizedTestTemplateContext ------------------------------------------

    /**
     * A `TestTemplateContext` representing a parameterized test.
     *
     * @param arguments  the parameterized test arguments
     */
    const ParameterizedTestTemplateContext(ParameterizedTest.Argument[] arguments)
            implements TestTemplateContext
        {
        @Override
        (String, Extension[], ResourceRepository.Resource[]) getTemplateInfo(Int iteration)
            {
            ParameterizedTestResolver resolver = new ParameterizedTestResolver(arguments);
            StringBuffer buf = new StringBuffer();
            buf.append($"[{iteration}] ");
            for (Int i : 0..<arguments.size)
                {
                if (i > 0)
                    {
                    buf.append(", ");
                    }
                ParameterizedTest.Argument arg = arguments[i];
                buf.append($"{arg.value}");
                }
            return buf.toString(), [], [ResourceRepository.resource(resolver, Replace)];
            }
        }

    // ---- inner const: ParameterizedTestResolver -------------------------------------------------

    /**
     * A `ParameterResolver` that resolves `Parameter`s of a parameterized test method
     * or test class constructor.
     */
    const ParameterizedTestResolver(ParameterizedTest.Argument[] args)
            implements ParameterResolver
        {
        @Override
        <ParamType> conditional ParamType resolve(ExecutionContext context, Parameter<ParamType> param)
            {
            if (param.ordinal < args.size)
                {
                ParameterizedTest.Argument arg = args[param.ordinal];
                // ToDo we should be able to do type conversion to compatible types
                if (ParamType == arg.type)
                    {
                    return True, arg.value.as(ParamType);
                    }
                }
            return False;
            }
        }    
    }
