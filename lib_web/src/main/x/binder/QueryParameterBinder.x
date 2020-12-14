import ecstasy.reflect.Parameter;

/**
 * A parameter binder that binds values from a http request's URI query parameters.
 */
const QueryParameterBinder<ParamType>
        implements ParameterBinder<ParamType, HttpRequest>
    {
    @Override
    BindingResult<ParamType> bind(Parameter<ParamType> parameter, HttpRequest request)
        {
        Map<String, List<String>> params = request.parameters;
        // ToDo: this process is actually a lot more complex
        // The parameter could be annotated with a name or pattern e.g. ?foo*
        // The value could need conversion.
        if (String name := parameter.hasName())
            {
            if (List<String> list := params.get(name))
                {
                if (!list.empty)
                    {
                    return new BindingResult<ParamType>(list[0].as(ParamType), True);
                    }
                }
            }
        return new BindingResult();
        }
    }