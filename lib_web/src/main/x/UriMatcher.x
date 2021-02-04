/**
 * A URI matcher is capable of matching a URI and producing a UriMatchInfo.
 */
public interface UriMatcher
    {
    /**
     * Match the given URI object.
     *
     * @param uri The URI
     *
     * @return True iff this matcher matches the URI
     * @return the resulting UriMatchInfo
     */
    conditional UriMatchInfo match(URI uri)
        {
        return match(uri.toString());
        }

    /**
     * Match the given URI object.
     *
     * @param uri The URI
     *
     * @return True iff this matcher matches the URI
     * @return the resulting UriMatchInfo
     */
    conditional UriMatchInfo match(String uri);
    }
