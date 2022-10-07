import ecstasy.reflect.AnnotationTemplate;
import ecstasy.reflect.Argument;
import ecstasy.reflect.ClassTemplate.Composition;

import codecs.Registry;

import routing.Catalog;
import routing.Catalog.EndpointInfo;
import routing.Catalog.MethodInfo;
import routing.Catalog.ServiceConstructor;
import routing.Catalog.WebServiceInfo;
import routing.UriTemplate;


/**
 * The `@WebApp` annotation is used to mark a module as being a web-application module. It can
 * contain any number of discoverable HTTP endpoints.
 *
 * TODO how to import a web module explicitly as "it's ok to trust any web services in this module"
 *      - can the package be annotated as "@Trusted" or something like that?
 */
mixin WebApp
        into Module
    {
    /**
     * Collect all endpoints declared by this Module and assemble them into a Catalog.
     */
    @Lazy Catalog catalog_.calc()
        {
        // REVIEW CP: how to report verification errors

        ClassInfo[] classInfos    = new ClassInfo[];
        Class[]     sessionMixins = new Class[];

        // collect the ClassInfos for WebServices
        scanClasses(this.classes, classInfos, sessionMixins, new HashSet<String>());

        // sort the ClassInfos based on their paths
        classInfos.sorted((ci1, ci2) -> ci2.path <=> ci1.path, inPlace=True);

        // now collect all endpoints
        WebServiceInfo[] webServiceInfos = collectEndpoints(classInfos);

        return new Catalog(this, webServiceInfos, sessionMixins);
        }

    /**
     * The registry for this WebApp.
     */
    @Lazy Registry registry_.calc()
        {
        return new Registry();
        }

    /**
     * WebService class/path info collected during the scan phase.
     */
    private static const ClassInfo(Class<WebService> clz, String path);

    /**
     * Scan all the specified classes for WebServices and add the corresponding information
     * to the ClassInfo array along with session mixin class array.
     */
    private void scanClasses(Class[] classes, ClassInfo[] classInfos, Class[] sessionMixins,
                             Set<String> declaredPaths)
        {
        for (Class child : classes)
            {
            if (AnnotationTemplate webServiceAnno := child.annotatedBy(WebService))
                {
                Argument[] args = webServiceAnno.arguments;
                assert !args.empty;

                String path;
                if (!(path := args[0].value.is(String)))
                    {
                    throw new IllegalState($"WebService \"{child}\": first argument is not a path");
                    }

                if (path != "/")
                    {
                    while (path.endsWith('/'))
                        {
                        // while the service path represents a "directory", we normalize it, so it
                        // does not end with the '/' (except for the root)
                        path = path[0 ..< path.size-1];
                        }

                    if (!path.startsWith('/'))
                        {
                        // the service path is always a "root"
                        path = "/" + path;
                        }
                    }

                if (declaredPaths.contains(path))
                    {
                    throw new IllegalState($|WebService \"{child}\":
                                            |path {path.quoted()} is already in use
                                            );
                    }

                declaredPaths += path;
                classInfos    += new ClassInfo(child.as(Class<WebService>), path);

                // scan classes inside the WebService class
                Collection<Type> childTypes   = child.PrivateType.childTypes.values;
                Class[]          childClasses = new Class[];
                childTypes.forEach(t ->
                    {
                    if (Class c := t.fromClass())
                        {
                        childClasses += c;
                        }
                    });

                scanClasses(childClasses, classInfos, sessionMixins, declaredPaths);
                }
            else if (child.mixesInto(Session))
                {
                sessionMixins += child;
                }
            else if (child.implements(Package), Object pkg := child.isSingleton())
                {
                assert pkg.is(Package);

                // don't scan imported modules
                if (!pkg.isModuleImport())
                    {
                    scanClasses(pkg.as(Package).classes, classInfos, sessionMixins, declaredPaths);
                    }
                }
            }
        }

    /**
     * Collect all endpoints for the WebServices in the specified ClassInfo array and
     * create a corresponding WebServiceInfo array.
     */
    private WebServiceInfo[] collectEndpoints(ClassInfo[] classInfos)
        {
        typedef MediaType|MediaType[] as MediaTypes;
        typedef String|String[]       as Subjects;

        Class      clzWebApp         = &this.actualClass;
        TrustLevel appTrustLevel     = clzWebApp.is(LoginRequired) ? clzWebApp.security : None;
        Boolean    appTls            = clzWebApp.is(HttpsRequired);
        MediaTypes appProduces       = clzWebApp.is(Produces) ? clzWebApp.produces : [];
        MediaTypes appConsumes       = clzWebApp.is(Consumes) ? clzWebApp.consumes : [];
        Subjects   appSubjects       = clzWebApp.is(Restrict) ? clzWebApp.subject  : [];
        Boolean    appStreamRequest  = clzWebApp.is(StreamingRequest);
        Boolean    appStreamResponse = clzWebApp.is(StreamingResponse);

        Int wsid = 0;
        Int epid = 0;

        WebServiceInfo[] webServiceInfos = new Array(classInfos.size);
        for (ClassInfo classInfo : classInfos)
            {
            Class<WebService>  clz         = classInfo.clz;
            Type<WebService>   serviceType = clz.PublicType;
            ServiceConstructor constructor;
            if (!(constructor := serviceType.defaultConstructor()))
                {
                throw new IllegalState($"default constructor is missing for \"{clz}\"");
                }

            TrustLevel serviceTrust = appTrustLevel;
            Boolean    serviceTls   = appTls;
            if (clz.is(LoginRequired))
                {
                serviceTrust = clz.security;
                serviceTls   = True;
                }
            else
                {
                if (clz.is(LoginOptional))
                    {
                    serviceTrust = None;
                    }
                if (clz.is(HttpsOptional))
                    {
                    serviceTls = False;
                    }
                else if (clz.is(HttpsRequired))
                    {
                    serviceTls = True;
                    }
                }
            MediaTypes serviceProduces       = clz.is(Produces) ? clz.produces : appProduces;
            MediaTypes serviceConsumes       = clz.is(Consumes) ? clz.consumes : appConsumes;
            Subjects   serviceSubjects       = clz.is(Restrict) ? clz.subject  : appSubjects;
            Boolean    serviceStreamRequest  = clz.is(StreamingRequest) || appStreamRequest;
            Boolean    serviceStreamResponse = clz.is(StreamingResponse) || appStreamResponse;

            EndpointInfo[] endpoints       = new EndpointInfo[];
            EndpointInfo?  defaultEndpoint = Null;
            MethodInfo[]   interceptors    = new MethodInfo[];
            MethodInfo[]   observers       = new MethodInfo[];
            MethodInfo?    onError         = Null;
            MethodInfo?    route           = Null;

            static void validateEndpoint(Method method)
                {
                Int returnCount = method.returns.size;
                assert returnCount <= 1 ||
                       returnCount == 2 && method.conditionalResult
                            as $"endpoint \"{method}\" has multiple returns";
                }

            for (Method<WebService, Tuple, Tuple> method : serviceType.methods)
                {
                switch (method.is(_))
                    {
                    case Default:
                        if (defaultEndpoint == Null)
                            {
                            String uriTemplate = method.template;
                            if (uriTemplate != "")
                                {
                                throw new IllegalState($|non-empty uri template for \"Default\"\
                                                        |endpoint \"{clz}\"
                                                        );
                                }
                            validateEndpoint(method);
                            defaultEndpoint = new EndpointInfo(method, epid++, wsid,
                                                serviceTls, serviceTrust,
                                                serviceProduces, serviceConsumes, serviceSubjects,
                                                serviceStreamRequest, serviceStreamResponse);
                            }
                        else
                            {
                            throw new IllegalState($"multiple \"Default\" endpoints on \"{clz}\"");
                            }
                        break;

                    case Endpoint:
                        validateEndpoint(method);
                        endpoints.add(new EndpointInfo(method, epid++, wsid,
                                            serviceTls, serviceTrust,
                                            serviceProduces, serviceConsumes, serviceSubjects,
                                            serviceStreamRequest, serviceStreamResponse));
                        break;

                    case Intercept, Observe:
                        interceptors.add(new MethodInfo(method, wsid));
                        break;

                    case OnError:
                        if (onError == Null)
                            {
                            onError = new MethodInfo(method, wsid);
                            }
                        else
                            {
                            throw new IllegalState($"multiple \"OnError\" handlers on \"{clz}\"");
                            }
                        break;

                    default:
                        if (method.name == "route" && method.params.size >= 4 &&
                                method.params[0].ParamType == Session         &&
                                method.params[1].ParamType == Request         &&
                                method.params[2].ParamType == Handler         &&
                                method.params[3].ParamType == ErrorHandler)
                            {
                            assert route == Null;
                            route = new MethodInfo(method, wsid);
                            }
                        break;
                    }
                }

            // we never use the endpoint id as an index, so we can sort them in-place
            endpoints.sorted((ep1, ep2) ->
                    ep2.template.literalPrefix <=> ep1.template.literalPrefix, inPlace=True);

            webServiceInfos += new WebServiceInfo(wsid++,
                    classInfo.path, constructor,
                    endpoints, defaultEndpoint,
                    interceptors, observers, onError, route
                    );
            }
        return webServiceInfos;
        }

    /**
     * Handle an otherwise-unhandled exception or other error that occurred during [Request]
     * processing within this `WebApp`, and produce a [Response] that is appropriate to the
     * exception or other error that was raised.
     *
     * @param session   the session (usually non-`Null`) within which the request is being
     *                  processed; the session can be `Null` if the error occurred before or during
     *                  the instantiation of the session
     * @param request   the request being processed
     * @param error     the exception thrown, the error description, or an HttpStatus code
     *
     * @return the [Response] to send back to the caller
     */
    Response handleUnhandledError(Session? session, Request request, Exception|String|HttpStatus error)
        {
        // TODO CP: does the exception need to be logged?
        HttpStatus status = error.is(RequestAborted) ? error.status :
                            error.is(HttpStatus)     ? error
                                                     : InternalServerError;

        return new responses.SimpleResponse(status=status, bytes=error.toString().utf8());
        }
    }