module TestUri
    {
    @Inject ecstasy.io.Console console;

    void run()
        {
        console.println("Testing URI:");

        console.println("1:");
        print(URI.create("http://foo:bar@ecstasy.com:8080/wiki/page1?a=b&c=d#abc"));
        console.println("2:");
        print(URI.create("http://ecstasy.com"));
        console.println("3:");
        print(URI.create("mailto:info@ecstacy.com"));
        console.println("4:");
        print(URI.create("http://ecstasy.com:8080"));
        }

    void print(URI uri)
        {
        console.println($"scheme='{uri.scheme}'");
        console.println($"authority='{uri.authority}'");
        console.println($"userInfo='{uri.userInfo}'");
        console.println($"host='{uri.host}'");
        console.println($"port='{uri.port}'");
        console.println($"path='{uri.path}'");
        console.println($"query='{uri.query}'");
        console.println($"fragment='{uri.fragment}'");
        console.println($"schemeSpecificPart='{uri.schemeSpecificPart}'");

        console.println($"String = '{uri}'");
        }

    }