
module Web.xtclang.org
    {

    mixin Path(String path)
            into Class | Method
        {
        }


    mixin HttpMethod(String method)
            into Method
        {
        }

    mixin Get
            extends HttpMethod("GET")
            into Method
        {
        }

    mixin Post
            extends HttpMethod("POST")
            into Method
        {
        }

    mixin Put
            extends HttpMethod("PUT")
            into Method
        {
        }

    mixin Delete
            extends HttpMethod("DELETE")
            into Method
        {
        }

    mixin Produces(String mediaType = "*/*")
            into Method
        {
        }

    mixin Consumes(String mediaType = "*/*")
            into Method
        {
        }

    mixin PathParam(String name)
        {
        }

    mixin ResponseStatus(Int status)
        {
        }

    @Abstract
    mixin Interceptor(Int priority = 1000)
            into Method
        {
        void before(Request req, Response response)
            {
            }

        void after(Request req, Response response)
            {
            }
        }
    }