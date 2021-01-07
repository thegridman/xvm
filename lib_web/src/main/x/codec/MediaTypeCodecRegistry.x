/**
 * A registry of MediaTypeCodec instances.
 */
class MediaTypeCodecRegistry
    {
    construct (MediaTypeCodec[] codecs = [])
        {
        codecsByType      = new HashMap();
        codecsByExtension = new HashMap();

        MediaTypeCodec[] defaultCodecs = codec.DEFAULT_CODECS;
        codecs = codecs.empty ? defaultCodecs : (new MediaTypeCodec[]) + defaultCodecs + codecs;

        for (MediaTypeCodec codec : codecs)
            {
            for (MediaType mediaType : codec.mediaTypes)
                {
                codecsByType.put(mediaType, codec);
                String? ext = mediaType.extension;
                if (ext != Null)
                    {
                    codecsByExtension.put(ext, codec);
                    }
                }
            }
        }

    private Map<MediaType, MediaTypeCodec> codecsByType;

    private Map<String, MediaTypeCodec> codecsByExtension;

    conditional MediaTypeCodec findCodec(MediaType type)
        {
@Inject Console console;
console.println($"findCodec MediaType={type}");
        if (MediaTypeCodec codec := codecsByType.get(type))
            {
console.println($"findCodec FOUND MediaType={type}");
            return True, codec;
            }

console.println($"findCodec trying extensions MediaType={type} extension={type.extension}");
        String? ext = type.extension;
        if (ext != Null)
            {
            if (MediaTypeCodec codec := codecsByExtension.get(ext))
                {
console.println($"findCodec FOUND MediaType={type}");
                return True, codec;
                }
            }

console.println($"findCodec NOT FOUND MediaType={type}");
        return False;
        }
    }