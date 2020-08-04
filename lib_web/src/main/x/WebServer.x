
service WebServer(Configuration config)
    {

    void start()
        {
        @Inject ecstasy.io.Console console;
        console.println($"WebServer listening on {config.address}:{config.port}");
        }

    static class Configuration
        {
        String address = "0.0.0.0";
        Int port = 8080;
        }
    }