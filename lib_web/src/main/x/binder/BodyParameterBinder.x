import ecstasy.reflect.Parameter;

import codec.MediaTypeCodec;
import codec.MediaTypeCodecRegistry;
import web.Body;

/**
 * A parameter binder that binds the request body to a parameter.
 */
class BodyParameterBinder(MediaTypeCodecRegistry registry)
        implements ParameterBinder<HttpRequest>
    {
    @Override
    Int priority.get()
        {
        return DefaultPriority + 1;
        }

    @Override
    Boolean canBind(Parameter parameter)
        {
        String name = "";
        if (String paramName := parameter.hasName())
            {
            name = paramName;
            }

        return parameter.is(Body) || "body" == name;
        }

    @Override
    <ParamType> BindingResult<ParamType> bind(Parameter<ParamType> parameter, HttpRequest request)
        {
@Inject Console console;
console.println($"BodyParameterBinder: Parameter={parameter}");

        String name = "";
        if (String paramName := parameter.hasName())
            {
            name = paramName;
            }

        Parameter bodyParam = parameter;
        if (bodyParam.is(Body) || "body" == name)
            {
console.println($"BodyParameterBinder: Parameter is a Body");

            if (ParamType body := request.attributes.getAttribute(HttpAttributes.BODY))
                {
console.println($"BodyParameterBinder: Using previously decoded Body {body}");
                return new BindingResult<ParamType>(body, True);
                }

            MediaType? mediaType = request.contentType;
            if (mediaType != Null)
                {
console.println($"BodyParameterBinder: MediaType is {mediaType}");
                if (MediaTypeCodec codec := registry.findCodec(mediaType))
                    {
console.println($"BodyParameterBinder - Found codec for mediaType={mediaType}");
                    Object? requestBody = request.body;
                    if (requestBody.is(Byte[]))
                        {
console.println($"BodyParameterBinder - Request body is a Byte[]");
                        ParamType body = codec.decode<ParamType>(requestBody);
                        request.attributes.add(HttpAttributes.BODY, body);
console.println($"BodyParameterBinder - decoded mediaType={mediaType} body={body}");
                        return new BindingResult<ParamType>(body, True);
                        }
                    else
                        {
console.println($"BodyParameterBinder - Request body is NOT a Byte[] {requestBody}");
                        }
                    }
                }
            }
        return new BindingResult();
        }
    }