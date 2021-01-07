import ecstasy.reflect.Parameter;

import web.QueryParam;

/**
 * A parameter binder that binds values from a http request's URI query parameters.
 */
const QueryParameterBinder
        implements ParameterBinder<HttpRequest>
    {
    @Override
    <ParamType> BindingResult<ParamType> bind(Parameter<ParamType> parameter, HttpRequest request)
        {
@Inject Console console;
console.println($"QueryParameterBinder: Parameter={parameter}");
        Parameter queryParam = parameter;
        if (queryParam.is(QueryParam))
            {
console.println($"QueryParameterBinder: Parameter is a QueryParam");

            String name = "";
            if (queryParam.is(ParameterBinding))
                {
console.println($"QueryParameterBinder: Parameter is a ParameterBinding name={queryParam.templateParameter}");

                name = queryParam.templateParameter;
                }
            if (name == "")
                {
                assert name := parameter.hasName();
                }
console.println($"QueryParameterBinder: Parameter name={name}");

            Map<String, List<String>> queryParamMap = request.parameters;
            // ToDo: this process is actually a lot more complex
            // The parameter could be annotated with a name or pattern e.g. ?foo*
            // The value could need conversion.
            if (List<String> list := queryParamMap.get(name))
                {
console.println($"QueryParameterBinder: Parameter queryParam={list}");
                if (!list.empty)
                    {
                    return new BindingResult<ParamType>(list[0].as(ParamType), True);
                    }
                }
            }
        return new BindingResult();
        }
    }