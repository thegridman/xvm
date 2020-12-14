/**
 * Represents a route to an endpoint for a http request.
 */
interface Route
    {
    /**
     * The media-types that the route consumes.
     */
    @RO MediaType[] consumes;

    /**
     * The media-types that the route produces.
     */
    @RO MediaType[] produces;
    }