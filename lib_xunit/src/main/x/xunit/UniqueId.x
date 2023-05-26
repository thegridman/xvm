import ecstasy.text.RegEx;

/**
 * A unique identifier for a test model.
 *
 * * A `UniqueId` is made up of an array of segments, where a `Segment` has a type and a value.
 * * A `UniqueId` is part of a model hierarchy, so like a File path, the parent of a
 *   `UniqueId` can be determined by removing the last `Segment` from it's array of segments.
 */
const UniqueId
    {
    /**
     * Create a `UniqueId`
     *
     * @param segments  the `Segment` array that makes up this `UniqueId`
     *
     * @throws IllegalArgument if the `Segment` array is empty
     */
    private construct(Segment[] segments)
        {
        assert:arg !segments.empty;
        this.segments = segments;
        }

    /**
     * The `Segment` array that makes up this `UniqueId`.
     */
    Segment[] segments;

    /**
     * Return the type of this `UniqueId`.
     *
     * The type is the type from the last `Segment` in this id.
     *
     * @return the type of this `UniqueId`
     */
    @Lazy String type.calc()
        {
        return segments[segments.size -1].type;
        }

    /**
     * The string representation of this `UniqueId`.
     */
    @Lazy String stringValue.calc()
        {
        StringBuffer buf = new StringBuffer();
        for (Int i : 0..<segments.size)
            {
            if (i > 0)
                {
                buf.append('/');
                }
            buf.append($"[{segments[i].type}:{segments[i].value}]");
            }
        return buf.toString();
        }

    /**
     * Return an array of `UniqueId` instance that make up the path
     * if ids from this `UniqueId` up to the root `UniqueId`.
     *
     * @return  an array of `UniqueId` instance that make up the path
                if ids from this `UniqueId` up to the root `UniqueId`
     */
    @Lazy UniqueId[] path.calc()
        {
        if (segments.empty)
            {
            return [];
            }

        UniqueId[] path = new Array();
        UniqueId   id   = new UniqueId([segments[0]]);

        path.add(id);
        for (Int i : 1..<segments.size)
            {
            path.add(new UniqueId(id.segments + segments[i]));
            }
        path.makeImmutable();
        return path;
        }

    /**
     * Return a `UniqueId` that is this `UniqueId` with a new `Segment` appended.
     *
     * @param type   the `Segment` type
     * @param value  the `Segment` value
     */
    UniqueId! append(String type, String value)
        {
        return new UniqueId(segments + new Segment(type, value));
        }

    /**
     * Returns the parent of this `UniqueId`.
     *
     * @return `True` iff this `UniqueId` has a parent, otherwise returns `False`
     * @return the `UniqueId` of the parent
     */
    conditional UniqueId! parent()
        {
        if (segments.size > 1)
            {
            return True, new UniqueId(segments[1..<segments.size]);
            }
        return False;
        }

    /**
     * Create an engine's unique ID from its engineId using the default
     * format.
     *
     * @param engineId the engine ID
     */
    static UniqueId forEngine(String engineId)
        {
        return root("engine", engineId);
        }

    /**
     * Create a root UniqueId from the supplied `segmentType` and
     * `value` using the default format.
     *
     * @param segmentType  the segment type
     * @param value        the value
     */
    static UniqueId root(String segmentType, String value)
        {
        return new UniqueId([new Segment(segmentType, value)]);
        }

    // ----- Stringable methods --------------------------------------------------------------------

    @Override
    Int estimateStringLength()
        {
        return stringValue.size;
        }

    @Override
    Appender<Char> appendTo(Appender<Char> buf)
        {
        return stringValue.appendTo(buf);
        }

    // ----- Segment -------------------------------------------------------------------------------

    /**
     * A segment in a unique identifier.
     */
    static const Segment(String type, String value)
        {
        }
    }
