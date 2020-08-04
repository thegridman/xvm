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
