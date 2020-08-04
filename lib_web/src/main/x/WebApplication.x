
mixin WebApplication
    {
    WebApplication register(WebService svc)
        {
        // registers a service, works out the endpoints from the various annotated methods etc...
        return this;
        }

    /**
     * Can be overridden to alter the server configuration.
     */
    void configure(WebServer.Configuration config)
        {
        }

    void run()
        {
        @Inject ecstasy.io.Console console;
        console.println("In WebApplication.run()");

        // discover WebService classes in this module

        WebServer.Configuration config = new WebServer.Configuration();
        configure(config);

        WebServer server = new WebServer(config);
        server.start();
        }
    }