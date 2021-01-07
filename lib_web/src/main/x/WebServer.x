
class WebServer
    {
    import ecstasy.io.ByteArrayOutputStream;
    import ecstasy.reflect.Parameter;
    import binder.BodyParameterBinder;
    import binder.BindingResult;
    import binder.ParameterBinder;
    import binder.RequestBinderRegistry;
    import codec.MediaTypeCodec;
    import codec.MediaTypeCodecRegistry;

    @Inject Console console;

    @Inject WebServerProxy proxy;

    private Router router = new Router();

    private RequestBinderRegistry binderRegistry = new RequestBinderRegistry();

    private MediaTypeCodecRegistry codecRegistry = new MediaTypeCodecRegistry();

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
        binderRegistry.addParameterBinder(new BodyParameterBinder(codecRegistry));
        proxy.start(handle);
        }

    void handle(HttpRequestProxy req, WebServerProxy.Responder responder)
        {
        try
            {
            URI         uri      = URI.create(req.uri);
            HttpMethod  method   = HttpMethod.fromName(req.method);
            HttpHeaders headers = new HttpHeaders();

console.println($"In WebServer.handle() uri={uri}");
console.println($"In WebServer.handle() method={method}");

            for (Map<String, String[]>.Entry entry : req.headers.entries)
                {
                headers.set(entry.key, new Array(Mutable, entry.value));
console.println($"In WebServer.handle() Header: {entry.key} {entry.value}");
                }

            HttpRequest         httpReq  = new HttpRequest(uri, headers, method);
            List<UriRouteMatch> routes   = router.findClosestRoute(httpReq);
            HttpResponse        httpResp;

            httpReq.body = req.body;

            if (routes.size == 1)
                {
                UriRouteMatch establishedRoute = routes[0];
                httpReq.attributes.add(HttpAttributes.ROUTE, establishedRoute.route);
                httpReq.attributes.add(HttpAttributes.ROUTE_MATCH, establishedRoute);
                httpReq.attributes.add(HttpAttributes.URI_TEMPLATE,
                                       establishedRoute.route.uriMatchTemplate.template);

                RouteMatch bound     = binderRegistry.bind(establishedRoute, httpReq);
                Tuple      result    = bound.execute();

                if (bound.conditionalResult && result.size > 0 && result[0].as(Boolean) == False)
                    {
                    // a False conditional result is equivalent to a 404 response
                    httpResp = new HttpResponse(HttpStatus.NotFound);
                    }
                else
                    {
                    MediaType  mediaType = resolveDefaultResponseContentType(httpReq, bound);
                    httpResp = encodeResponse(result, method, mediaType);
                    }
                }
            else if (routes.size == 0)
                {
                // ToDo: should be handled by a 404 status handler
                httpResp = new HttpResponse(HttpStatus.NotFound);
                }
            else
                {
                // ToDo: we can attempt to narrow down multiple results using other rules
                httpResp = new HttpResponse(HttpStatus.MultipleChoices);
                }

            // ToDo: Check the status and execute any route for the status

            writeResponse(httpResp, responder);
            }
        catch (Exception e)
            {
            // ToDo: this should be handled by an exception handling route
            if (e.is(HttpException))
                {
                writeResponse(new HttpResponse(e.status), responder);
                }
            else
                {
                @Inject Console console;
                console.println(e.toString());
                writeResponse(new HttpResponse(HttpStatus.InternalServerError), responder);
                }
            }
        }

    /**
     * Process the `Tuple` returned from a request handler into a `HttpResponse`.
     */
    HttpResponse encodeResponse(Tuple t, HttpMethod method, MediaType mediaType)
        {
console.println($"In WebServer.encodeResponse() - mediaType={mediaType}");

        HttpResponse httpResp = new HttpResponse();
        httpResp.headers.add("Content-Type", mediaType.name);

        if (t.size == 0)
            {
            // method had a void return type
            if (HttpMethod.permitsRequestBody(method))
                {
                // method allows a body so set the length to zero
                httpResp.headers.add("Content-Length", "0");
                //httpResp.headers.contentLength = 0;
                }
            return httpResp;
            }

        if (t[0].is(HttpResponse))
            {
            return t[0].as(HttpResponse);
            }

        for (Int i : [0..t.size))
            {
            Object o = t[i];
            if (o.is(HttpStatus))
                {
                httpResp.status = o;
                }
            else if (o != Null)
                {
                httpResp.body = o;
                }
            }

        if (MediaTypeCodec codec := codecRegistry.findCodec(mediaType))
            {
console.println($"In WebServer.encodeResponse() - Found codec for mediaType={mediaType} body={httpResp.body}");
            if (httpResp.body != Null)
                {
                httpResp.body = codec.encode(httpResp.body);
console.println($"In WebServer.encodeResponse() - Encoded mediaType={mediaType} body={httpResp.body}");
                }
            }

        return httpResp;
        }

    void writeResponse(HttpResponse response, WebServerProxy.Responder responder)
        {
        ByteArrayOutputStream out = new ByteArrayOutputStream();

        Object? body = response.body;
        if (body.is(Iterable<Char>))
            {
            for (Char c : body)
                {
                out.writeBytes(c.utf());
                }
            }
        else if (body.is(Byte[]))
            {
            out.writeBytes(body);
            }

        responder(response.status.code, out.bytes, response.headers.toTuples());
        }

    /**
     * Determine the default content type for the response.
     */
    MediaType resolveDefaultResponseContentType(HttpRequest request, RouteMatch route)
        {
        MediaType[] accepts = request.accepts;
        for (MediaType mt : accepts)
            {
            if (mt != MediaType.ALL_TYPE && route.canProduce(mt))
                {
                return mt;
                }
            }

        MediaType[] produces = route.produces;
        if (produces.size > 0)
            {
            return produces[0];
            }
        return MediaType.APPLICATION_JSON_TYPE;
        }
    }