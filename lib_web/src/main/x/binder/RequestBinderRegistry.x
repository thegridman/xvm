import ecstasy.reflect.Parameter;

/**
 * A ParameterBinderRegistry containing ParameterBinder instances that
 * bind parameters to values from a from a HttpRequest.
 */
class RequestBinderRegistry
        implements ParameterBinderRegistry<HttpRequest>
    {
    construct()
        {
        binders = new Array();
        binders.add(new QueryParameterBinder());
        }

    private Array<ParameterBinder> binders;

    @Override
    <T> conditional ParameterBinder<T, HttpRequest>
    findParameterBinder(Parameter<T> parameter, HttpRequest source)
        {
        return True, binders[0].as(ParameterBinder<T, HttpRequest>);
        }

    /**
     * Produce the bound parameters for the route and request.
     *
     * @param route  the route to bind parameters for
     * @param req    the http request to obtain parameters values from
     *
     * @return a RouteMatch bound to the arguments from the source request
     */
    RouteMatch bind(RouteMatch route, HttpRequest req)
        {
        Map<String, Object> arguments = new HashMap();
        for (Parameter p : route.requiredParameters)
            {
            if (String name := p.hasName())
                {
                if (ParameterBinder<Object, HttpRequest> binder := findParameterBinder(p, req))
                    {
                    BindingResult result = binder.bind(p, req);
                    if (result.bound)
                        {
                        arguments.put(name, result.value);
                        }
                    }
                }
            }
        return route.fulfill(arguments);
        }
    }
