module TestWebApp
    {
    package web import web.xtclang.org;

    import web.Accepts;
    import web.Body;
    import web.Consumes;
    import web.Delete;
    import web.Get;
    import web.HttpStatus;
    import web.MediaType;
    import web.NotFound;
    import web.PathParam;
    import web.Post;
    import web.Produces;
    import web.Put;
    import web.QueryParam;
    import web.WebServer;
    import web.WebService;

    /**
     * A simple CRUD web service.
     */
    @WebService("/")
    class UsersApi
        {
        private Map<String, User> users = new HashMap();

        @Post("/users/{who}")
        @Consumes("application/json")
        void putUser(@PathParam String who, @Body User user)
            {
            users.put(who, user);
            }

        @Get("/users/{who}")
        User getUser(String who)
            {
            if (User user := users.get(who))
                {
                return user;
                }
            throw new NotFound($"User '{who}' does not exist");
            }

//        @Get("/users/{who}")
//        conditional User getUser(String who)
//            {
//            if (User user := users.get(who))
//                {
//                return True, user;
//                }
//            return False;
//            }

        @Delete("/users/{who}")
        HttpStatus deleteUser(String who)
            {
            if (!users.contains(who))
                {
                return HttpStatus.NotFound;
                }
            users.remove(who);
            return HttpStatus.OK;
            }
        }

    /**
     * A user with a name and email address.
     */
    const User(String name, String email)
        {
        }

    void run()
        {
        @Inject Console console;
        console.println("Testing Web App");

        new WebServer()
                .addRoutes(new UsersApi())
                .start();
        }
    }
