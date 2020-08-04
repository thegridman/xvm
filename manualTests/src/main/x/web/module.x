
/**
 * This module demonstrates a web application.
 * The module adds the WebApplication mixin from the web module, which
 * turns this module into a WebApplication.
 *
 * There is a run() method in the WebApplication that will start and configure
 * the WebServer so this module does not need a run method unless it specifically
 * needs to override run() to do something custom.
 */
module TestWeb
        incorporates web.WebApplication
    {
    package web import Web.xtclang.org;

    import web.Delete;
    import web.Get;
    import web.Path;
    import web.PathParam;
    import web.Post;
    import web.Put;
    import web.Produces;
    import web.WebServer;
    import web.WebService;

    @Inject ecstasy.io.Console console;

    // The WebServer will have a default configuration but
    // we can override the configure method to allow us to alter
    // the WebServer configuration before the server starts.
    // There are probably other ways to configure the server (like maybe
    // some sort of configuration file, environment variables etc)
    // but this method lets us do whatever we want programmatically
    // if we really need to.
    @Override
    void configure(WebServer.Configuration config)
        {
        config.port=7001;
        }


//    void run()
//        {
//        console.println("Testing Web...");
//        CartsApi api = new CartsApi();
//
//        Type t = &api.actualType;
//        console.println(t);
//        console.println("Is WebService");
//        console.println(api.is(web.WebService));
//        console.println("Is Path");
//        console.println(api.is(web.Path));
//
//        for (Method m : t.methods)
//            {
//            Type mt = &m.actualType;
//            console.print(m.name + " : ");
//            console.println(mt);
//            console.println(mt.underlyingTypes);
//            console.println(mt.is(Type<web.Get>));
//
//            Function fn = m.bindTarget(api);
//            console.println(fn);
//            console.println(&fn.actualType);
//            console.println(&fn.actualType.underlyingTypes);
//            console.println(&fn.instanceOf(web.Get));
//
//            if (fn.is(web.Get))
//                {
//                console.println("*********************");
//                }
//            }
//
//        api.getCart("foo");
//        }

    /**
     * The REST API to manage shopping carts.
     */
    @Path("/carts")
    class CartsApi
            incorporates WebService
        {
        // A fake Cart database, in reality this would probably be some
        // sort of injected service.
        Map<String, Cart> cartsDatabase = new HashMap();

        // The framework will call this method for a GET
        // If the conditional is True the returned Cart will be serialized to json and
        // returned in the response body with a status code of 200
        // If the conditional is False a 404 response is returned
        @Get
        @Path("{customerId}")
        @Produces("application/json")
        conditional Cart getCart(@PathParam("customerId") String customerId)
            {
            return cartsDatabase.get(customerId);
            }

        // The framework will call this method for a DELETE
        // When the method completes a 200 response will be sent to the caller
        @Delete
        @Path("{customerId}")
        void deleteCart(@PathParam("customerId") String customerId)
            {
            cartsDatabase.remove(customerId);
            }

        // This method returns an inner service, in this case to manage items in
        // a specific customer's shopping cart.
        @Path("{customerId}/items")
        ItemsApi getItems(@PathParam("customerId") String customerId)
            {
            return new ItemsApi(customerId);
            }
        }

    /**
     * The REST API to manage items in a shopping cart.
     */
    class ItemsApi(String customerId)
            incorporates WebService
        {
        }

    /**
     * A representation of a shopping cart.
     */
    class Cart(String customerId)
        {
        }

    /**
     * A representation of an item in a shopping cart.
     */
    class Item(String itemId)
        {
        }
    }
