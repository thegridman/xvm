/**
 * A representation of a http request.
 */
class HttpRequest(URI uri, HttpHeaders headers, HttpMethod method)
        extends HttpMessage(headers)
    {
    /**
     * @return the accepted media types.
     */
    MediaType[] accepts.get()
        {
        return headers.accepts;
        }

    /**
     * @return the HTTP parameters contained with the URI query string
     */
    @Lazy Map<String, List<String>> parameters.calc()
        {
        UriQueryStringParser parser = new UriQueryStringParser(uri.toString());
        return parser.getParameters();
        }
    }
