module TestWebApp
    {
    package web import web.xtclang.org;

    import web.Get;
    import web.MediaType;
    import web.PathParam;
    import web.QueryParam;
    import web.Produces;
    import web.WebService;
    import web.WebServer;

    @Inject Console console;

    @WebService("/")
    class HelloApp
        {
//        @Get("/hello")
//        @Produces("text/plain")
//        String helloText()
//            {
//            return "Hello World!";
//            }

        @Get("/hello/{who}")
        @Produces("text/plain")
        String helloText(@PathParam String who, @QueryParam String greeting = "Hello")
            {
            return greeting + " " + who + "!";
            }

//        @Get("/hello")
//        @Produces("text/json")
//        String helloJson()
//            {
//            return "{\"message\": \"Hello World!\"}";
//            }
//
//        @Get("/goodbye")
//        @Produces("text/plain")
//        String goodbye()
//            {
//            return "Goodbye Cruel World!";
//            }
        }

    void run()
        {
        console.println("Testing Web App");

        new WebServer()
                .addRoutes(new HelloApp())
                .start();
        }
    }
