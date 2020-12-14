interface HttpRequestProxy
    {
    @RO Map<String, String[]> headers;

    @RO String method;

    @RO String uri;
    }