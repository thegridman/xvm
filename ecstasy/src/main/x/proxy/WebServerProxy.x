
interface WebServerProxy
    {
    void start(Handler handler);

    typedef function void (Int, Byte[], Tuple<String, String[]>[]) Responder;
    typedef function void (HttpRequestProxy, Responder) Handler;
    }