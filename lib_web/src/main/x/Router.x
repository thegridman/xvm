/**
 * A router that can work out the routes for a given http method and URI.
 */
class Router
    {
    construct()
        {
        routes = new Array();
        }

    /**
     * The routes this Router can route requests to.
     */
    private Array<UriRoute> routes;

    /**
     * Add all of the Routes for the annotated endpoints in the specified Type.
     *
     * @param controller  the endpoints to add
     */
    <T> void addRoutes(T controller)
        {
        Type<T> t = &controller.actualType;
        for (Method<Object, Tuple, Tuple> method : t.methods)
            {
            Method endpoint = method;
            if (endpoint.is(HttpEndpoint))
                {
                ExecutableFunction executable = new SimpleExecutableFunction(method, controller);
                Array<MediaType>   produces   = new Array<MediaType>();
                Array<MediaType>   consumes   = new Array<MediaType>();
                UriMatchTemplate   template   = UriMatchTemplate.from(endpoint.path);

                if (method.is(Produces))
                    {
                    produces.add(new MediaType(method.mediaType));
                    }

                if (method.is(Consumes))
                    {
                    consumes.add(new MediaType(method.mediaType));
                    }

                routes.add(new DefaultUriRoute(endpoint.method, template,
                        executable, consumes, produces));
                }
            }
        }

    /**
     * Finds the closest matching routes for the given request.
     *
     * @param request the request
     *
     * @return a list of possible routes
     */
    List<UriRouteMatch> findClosestRoute(HttpRequest req)
        {
        HttpMethod  method                = req.method;
        Boolean     permitsBody           = HttpMethod.permitsRequestBody(method);
        MediaType?  contentType           = req.contentType;
        MediaType[] acceptedProducedTypes = req.accepts;

        // find the routes matching the URI path filtered on matching media types
        List<UriRouteMatch> matches = findRoutes(method, req)
                .filter(match -> (!permitsBody || match.canConsume(contentType))
                                 && match.canProduce(acceptedProducedTypes), new Array())
                .as(List<UriRouteMatch>);

        if (matches.size <= 1)
            {
            // only one or zero matches so we're done
            return matches;
            }

        if (!acceptedProducedTypes.empty)
            {
            // take the highest priority accepted type
            MediaType           mediaType    = acceptedProducedTypes[0];
            List<UriRouteMatch> mostSpecific = matches.filter(match -> match.canProduce(mediaType), new Array()).as(List<UriRouteMatch>);

            if (!mostSpecific.empty || !acceptedProducedTypes.contains(MediaType.ALL_TYPE))
                {
                matches = mostSpecific;
                }
            }

        if (matches.size > 1 && permitsBody)
            {
            List<UriRouteMatch> explicitlyConsumedRoutes = new Array();
            List<UriRouteMatch> consumesRoutes           = new Array();

            for (UriRouteMatch match: matches)
                {
                MediaType explicitType = contentType != Null ? contentType : MediaType.ALL_TYPE;
                if (match.explicitlyConsumes(explicitType))
                    {
                    explicitlyConsumedRoutes.add(match);
                    }

                if (explicitlyConsumedRoutes.empty && match.canConsume(contentType))
                    {
                    consumesRoutes.add(match);
                    }
                }
            matches = explicitlyConsumedRoutes.empty ? consumesRoutes : explicitlyConsumedRoutes;
            }

        if (matches.size > 1)
            {
            List<UriRouteMatch> closestMatches = new Array();
            Int                 variableCount  = 0;
            Int                 rawLength      = 0;

            for (Int i: 0..matches.size - 1)
                {
                UriRouteMatch    match    = matches[i];
                UriMatchTemplate template = match.route.uriMatchTemplate;
                Int              variable = template.variableCount;
                Int              raw      = template.rawLength;

                if (i == 0)
                    {
                    variableCount = variable;
                    rawLength     = raw;
                    }

                if (variable > variableCount || raw < rawLength)
                    {
                    break;
                    }
                closestMatches.add(match);
                }
            matches = closestMatches;
            }

        return matches;
        }

    /**
     * Find the matching routes for a http method, URI and request.
     *
     * @param method  the requested http method
     * @param req     the HttpRequest
     */
    List<UriRouteMatch> findRoutes(HttpMethod method, HttpRequest req)
        {
        Array<UriRouteMatch> matches = new Array<UriRouteMatch>();
        URI                  uri     = req.uri;
        for (UriRoute route : routes)
            {
            if (route.matchesMethod(method))
                {
                if (UriRouteMatch match := route.match(uri))
                    {
                    matches.add(match);
                    }
                }
            }
        return matches;
        }

    // ----- inner class: DefaultUriRoute ----------------------------------------------------------

    /**
     * The default implementation of a UriRoute.
     */
    static class DefaultUriRoute
            implements UriRoute
            implements Stringable
        {
        construct(HttpMethod            httpMethod,
                  UriMatchTemplate      uriMatchTemplate,
                  ExecutableFunction    executable,
                  MediaType[]           consumes = [],
                  MediaType[]           produces = [],
                  List<DefaultUriRoute> nestedRoutes = List:[])
            {
            this.httpMethod       = httpMethod;
            this.uriMatchTemplate = uriMatchTemplate;
            this.executable       = executable;
            this.consumes         = consumes;
            this.produces         = produces;
            this.nestedRoutes     = new Array();
            this.nestedRoutes.addAll(nestedRoutes);
            }

        // ----- properties ------------------------------------------------------------------------

        /**
         * The http method that this routes matches.
         */
        private HttpMethod httpMethod;

        /**
         * The template to use to match this route to a URI.
         */
        private UriMatchTemplate uriMatchTemplate;

        /**
         * The function that handles executing the route.
         */
        private ExecutableFunction executable;

        /**
         * Child routes of this route.
         */
        private List<DefaultUriRoute> nestedRoutes;

        @Override
        public/private MediaType[] consumes;

        @Override
        public/private MediaType[] produces;

        // ----- UriRoute implementation -----------------------------------------------------------

        @Override
        Boolean matchesMethod(HttpMethod method)
            {
            return this.httpMethod == method;
            }

        @Override
        conditional UriRouteMatch match(String uri)
            {
            if (UriMatchInfo info := uriMatchTemplate.match(uri))
                {
                DefaultUriRouteMatch route = new DefaultUriRouteMatch(info, this);
                return True, route;
                }
            return False;
            }

        // ----- Orderable methods -----------------------------------------------------------------

        @Override
        static <T extends DefaultUriRoute> Boolean equals(T value1, T value2)
            {
            return value1.uriMatchTemplate == value2.uriMatchTemplate;
            }

        @Override
        static <T extends DefaultUriRoute> Ordered compare(T value1, T value2)
            {
            return value1.uriMatchTemplate <=> value2.uriMatchTemplate;
            }

        // ----- Stringable methods ----------------------------------------------------------------

        @Override
        Int estimateStringLength()
            {
            return 0;
            }

        @Override
        Appender<Char> appendTo(Appender<Char> buf)
            {
            "DefaultUriRoute(".appendTo(buf);
            httpMethod.appendTo(buf);
            ", ".appendTo(buf);
            uriMatchTemplate.appendTo(buf);
            ", ".appendTo(buf);
            consumes.toString().appendTo(buf);
            ", ".appendTo(buf);
            produces.toString().appendTo(buf);
            ")".appendTo(buf);

            return buf;
            }
        }
    }