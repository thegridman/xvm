import ecstasy.reflect.Parameter;

interface ParameterResolver
    {
    <ParamType> conditional ParamType resolve(ExecutionContext context, Parameter<ParamType> param);

    static Map<Parameter, Object> ensureResolved(ExecutionContext context, Parameter[] params)
        {
        (Map<Parameter, Object> values, Parameter[] unresolved) = resolveInternal(context, params);
        if (unresolved.empty)
            {
            return values;
            }

        ParameterResolver[] resolvers = context.repository.getResources(ParameterResolver);
        throw new IllegalState($"Failed to resolve parameters: unresolved={unresolved} resolvers={resolvers}");
        }

    static conditional Map<Parameter, Object> resolve(ExecutionContext context, Parameter[] params)
        {
        (Map<Parameter, Object> values, Parameter[] unresolved) = resolveInternal(context, params);
        if (unresolved.empty)
            {
            return True, values;
            }
        return False;
        }

    private static (Map<Parameter, Object>, Parameter[]) resolveInternal(ExecutionContext context, Parameter[] params)
        {
        if (params.size == 0)
            {
            return Map:[], [];
            }

        Map<Parameter, Object> paramValues = new ListMap();
        Parameter[]            unresolved  = new Array();

        for (var param : params)
            {
            if (var value := ParameterResolver.resolveParameter(context, param, param.ParamType))
                {
                paramValues.put(param, value);
                }
            else if (var defaultValue := param.defaultValue())
                {
                paramValues.put(param, defaultValue);
                }
            else
                {
                unresolved.add(param);
                }
            }

        return paramValues, unresolved;
        }

    private static <ParamType> conditional Object resolveParameter(ExecutionContext context, Parameter<ParamType> param, Type<ParamType> type)
        {
        ParameterResolver[] resolvers = context.repository.getResources(ParameterResolver);
        for (ParameterResolver resolver : resolvers)
            {
            if (var value := resolver.resolve(context, param))
                {
                return True, value;
                }
            }
        return False;
        }
    }