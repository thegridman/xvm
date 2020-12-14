
interface WebServerProxy
    {
    void start(Handler handler);

    typedef function void (Int, Byte[]) Responder;
    typedef function void (HttpRequestProxy, Responder) Handler;
    }