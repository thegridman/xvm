module WebApp
    {
    package web import web.xtclang.org;

    import web.Get;
    import web.MediaType;
    import web.Produces;

    @WebService(path = "/hello")
    class HelloApp
        {
        @Get
        @Produces(MediaType.TEXT_PLAIN)
        public String index()
            {
            return "Hello World";
            }
        }
    }
