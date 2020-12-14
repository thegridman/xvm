
class WebServer
    {
    import ecstasy.io.ByteArrayOutputStream;
    import ecstasy.reflect.Parameter;
    import binder.BindingResult;
    import binder.ParameterBinder;
    import binder.RequestBinderRegistry;

    @Inject Console console;

    @Inject WebServerProxy proxy;

    private Router router = new Router();

    private RequestBinderRegistry binderRegistry = new RequestBinderRegistry();

    /**
     * Add all of the Routes for the annotated endpoints in the specified Type.
     *
     * @param type  the value with annotated endpoints
     *
     * @return  this WebServer
     */
    <T> WebServer addRoutes(T o)
        {
        router.addRoutes(o);
        return this;
        }

    /**
     * Start the web server.
     */
    void start()
        {
        proxy.start(handle);
        }

    void handle(HttpRequestProxy req, WebServerProxy.Responder responder)
        {
        ByteArrayOutputStream out  = new ByteArrayOutputStream();
        try
            {
            URI uri = URI.create(req.uri);

            HttpHeaders headers = new HttpHeaders();
            for (Map<String, String[]>.Entry entry : req.headers.entries)
                {
                headers.set(entry.key, new Array(Mutable, entry.value));
                }

            HttpMethod   method   = HttpMethod.fromName(req.method);
            HttpRequest  httpReq  = new HttpRequest(uri, headers, method);
            HttpResponse httpResp = new HttpResponse();

            List<UriRouteMatch> routes  = router.findClosestRoute(httpReq);
            HttpStatus          status  = HttpStatus.OK;

            if (routes.size == 1)
                {
                UriRouteMatch establishedRoute = routes[0];
                httpReq.attributes.add(HttpAttributes.ROUTE, establishedRoute.route);
                httpReq.attributes.add(HttpAttributes.ROUTE_MATCH, establishedRoute);
                httpReq.attributes.add(HttpAttributes.URI_TEMPLATE, establishedRoute.route.uriMatchTemplate.template);

                RouteMatch    bound  = binderRegistry.bind(establishedRoute, httpReq);
                Tuple<Object> result = bound.execute();

                httpResp.body = result[0];
                status        = httpResp.status;
                }
            else if (routes.size == 0)
                {
                status = HttpStatus.NotFound;
                }
            else
                {
                status = HttpStatus.MultipleChoices;
                }

            // ToDo: Check the status and execute any route for the status

            // ToDo: we need to be able to serialize the body to the produced media type
            Object? body = httpResp.body;
            if (body.is(String))
                {
                for (Char c : body)
                    {
                    out.writeBytes(c.utf());
                    }
                }
            responder(status.code, out.bytes);
            }
        catch (Exception e)
            {
            // ToDo: this should be handled by an exception handling route
            @Inject Console console;
            console.println(e.toString());
            responder(HttpStatus.InternalServerError.code, out.bytes);
            }
        }
    }