import ecstasy.text.Matcher;
import ecstasy.text.Pattern;

/**
 * An implementation of the URI Template specification. See https://tools.ietf.org/html/rfc6570
 */
const UriTemplate(String template, List<PathSegment> segments, Int variableCount, Int rawLength)
        implements Orderable
        implements Hashable
        implements Stringable
    {

    // ----- properties ----------------------------------------------------------------------------

    private static String  STRING_PATTERN_SCHEME    = "([^:/?#]+):";
    private static String  STRING_PATTERN_USER_INFO = "([^@\\[/?#]*)";
    private static String  STRING_PATTERN_HOST_IPV4 = "[^\\[{/?#:]*";
    private static String  STRING_PATTERN_HOST_IPV6 = "\\[[\\p{XDigit}\\:\\.]*[%\\p{Alnum}]*\\]";
    private static String  STRING_PATTERN_HOST      = "(" + STRING_PATTERN_HOST_IPV6 + "|" + STRING_PATTERN_HOST_IPV4 + ")";
    private static String  STRING_PATTERN_PORT      = "(\\d*(?:\\{[^/]+?\\})?)";
    private static String  STRING_PATTERN_PATH      = "([^#]*)";
    private static String  STRING_PATTERN_QUERY     = "([^#]*)";
    private static String  STRING_PATTERN_REMAINING = "(.*)";
    private static Char    QUERY_OPERATOR           = '?';
    private static Char    SLASH_OPERATOR           = '/';
    private static Char    HASH_OPERATOR            = '#';
    private static Char    EXPAND_MODIFIER          = '*';
    private static Char    OPERATOR_NONE            = '0';
    private static Char    VAR_START                = '{';
    private static Char    VAR_END                  = '}';
    private static Char    AND_OPERATOR             = '&';
    private static String  SLASH_STRING             = "/";
    private static Char    DOT_OPERATOR             = '.';
    private static Pattern PATTERN_PERCENT          = Pattern.compile("%");
    private static Pattern PATTERN_SPACE            = Pattern.compile("\\s");

    // Regex patterns that match URIs. See RFC 3986, appendix B
    private static Pattern PATTERN_SCHEME = Pattern.compile("^" + STRING_PATTERN_SCHEME + "//.*");

    private static Pattern PATTERN_FULL_PATH = Pattern.compile("^([^#\\?]*)(\\?([^#]*))?(\\#(.*))?$");

    private static Pattern PATTERN_FULL_URI = Pattern.compile(
            "^(" + STRING_PATTERN_SCHEME + ")?" + "(//(" + STRING_PATTERN_USER_INFO + "@)?"
                 + STRING_PATTERN_HOST + "(:" + STRING_PATTERN_PORT +
                    ")?" + ")?" + STRING_PATTERN_PATH + "(\\?" + STRING_PATTERN_QUERY + ")?"
                 + "(#" + STRING_PATTERN_REMAINING + ")?");


    // ----- factory methods -----------------------------------------------------------------------

    public static UriTemplate from(String template)
        {
        UriTemplateParser parser = new UriTemplateParser(template);
        return parser.parse();
        }

    // ----- Hashable ------------------------------------------------------------------------------

    static <CompileType extends UriTemplate> Int hashCode(CompileType value)
        {
        return String.hashCode(value.template);
        }

    // ----- Orderable -----------------------------------------------------------------------------

    static <CompileType extends UriTemplate> Boolean equals(CompileType value1, CompileType value2)
        {
        return value1.template == value2.template;
        }

    static <CompileType extends UriTemplate> Ordered compare(CompileType value1, CompileType value2)
        {
        //using value2 compareTo value1 because more raw length should have higher precedence
        Ordered rawCompare = value2.rawLength <=> value1.rawLength;
        if (rawCompare == Ordered.Equal)
            {
            return value1.variableCount <=> value2.variableCount;
            }
        else
            {
            return rawCompare;
            }
        }

    // ----- Stringable methods --------------------------------------------------------------------

    @Override
    Int estimateStringLength()
        {
        return template.size;
        }

    @Override
    Appender<Char> appendTo(Appender<Char> buf)
        {
        return template.appendTo(buf);
        }

    // ----- inner types ---------------------------------------------------------------------------

    /**
     * A URI template parser that parses a template string into a UriTemplate.
     *
     * @param template   the URI template string to parse
     * @param arguments  the optional parser arguments
     */
    protected static class UriTemplateParser(String template, Object[] arguments = [])
        {
        private UriTemplate? uriTemplate = Null;

        /**
         * Parse UriTemplate instance from the template string.
         *
         * @return a UriTemplate
         */
        protected UriTemplate parse()
            {
            UriTemplate? t = this.uriTemplate;
            if (t.is(UriTemplate))
                {
                return t;
                }

            ParserResult result = parse(template);

            uriTemplate = new UriTemplate(result.template,
                                          result.segments,
                                          result.variableCount,
                                          result.rawLength);

            return uriTemplate.as(UriTemplate);
            }

        protected ParserResult parse(String template)
            {
            if (template[template.size - 1] == SLASH_OPERATOR)
                {
                if (template.size > 1)
                    {
                    template = template[0..template.size - 1];
                    }
                }

            Array<PathSegment> segments = new Array();

            if (PATTERN_SCHEME.match(template).matched)
                {
                Matcher matcher = PATTERN_FULL_URI.match(template);

                if (matcher.find())
                    {
                    String? scheme = matcher.group(2);
                    if (scheme.is(String))
                        {
                        segments.add(new RawPathSegment(False, scheme + "://"));
                        }

                    String? userInfo = matcher.group(5);
                    String? host = matcher.group(6);
                    String? port = matcher.group(8);
                    String? path = matcher.group(9);
                    String? query = matcher.group(11);
                    String? fragment = matcher.group(13);

                    if (userInfo.is(String))
                        {
                        createSegmentParser(userInfo, arguments).parse(segments);
                        }
                    if (host.is(String))
                        {
                        createSegmentParser(host, arguments).parse(segments);
                        }
                    if (port.is(String))
                        {
                        createSegmentParser(':' + port, arguments).parse(segments);
                        }
                    if (path.is(String))
                        {
                        if (fragment.is(String))
                            {
                            createSegmentParser(path + HASH_OPERATOR + fragment, [])
                                    .parse(segments);
                            }
                        else
                            {
                            createSegmentParser(path, arguments).parse(segments);
                            }
                        }
                    if (query.is(String))
                        {
                        createSegmentParser(query, arguments).parse(segments);
                        }
                    }
                else
                    {
                    throw new IllegalArgument("Invalid URI template: " + template);
                    }
                }
            else
                {
                createSegmentParser(template, arguments).parse(segments);
                }

            Int variableCount = 0;
            Int rawLength     = 0;
            for (PathSegment segment: segments)
                {
                if (segment.isVariable())
                    {
                    if (!segment.isQuerySegment)
                        {
                        variableCount++;
                        }
                    }
                else
                    {
                    rawLength += segment.size;
                    }
                }

            return new ParserResult(template, segments, variableCount, rawLength);
            }

        /**
         * Create a SegmentParser.
         *
         * @param  template   the template string to parse
         * @param  arguments  parameters to pass to the parser
         *
         * @return a SegmentParser
         */
        protected SegmentParser createSegmentParser(String template, Object[] arguments = [])
            {
            return new SegmentParser(template);
            }
        }

    // ----- inner class: ParserResult -------------------------------------------------------------

    /**
     * The result of parsing a URI template string.
     */
    protected static const ParserResult(String            template,
                                        List<PathSegment> segments,
                                        Int               variableCount,
                                        Int               rawLength);

    // ----- inner class: SegmentParser ------------------------------------------------------------

    /**
     * An URI template parser.
     */
    protected static class SegmentParser(String templateText)
        {
        private static Int STATE_TEXT              = 0; // raw text
        private static Int STATE_VAR_START         = 1; // the start of a URI variable ie. {
        private static Int STATE_VAR_CONTENT       = 2; // within a URI variable. ie. {var}
        private static Int STATE_VAR_NEXT          = 11; // within the next variable in a URI variable declaration ie. {var, var2}
        private static Int STATE_VAR_MODIFIER      = 12; // within a variable modifier ie. {var:1}
        private static Int STATE_VAR_NEXT_MODIFIER = 13; // within a variable modifier of a next variable ie. {var, var2:1}

        private Int      state          = STATE_TEXT;
        private Char     operator       = OPERATOR_NONE; // zero means no operator
        private Char     modifier       = OPERATOR_NONE; // zero means no modifier
        private Boolean  isQuerySegment = False;
        private String?  varDelimiter   = Null;

        /**
         * Parse a list of segments.
         *
         * @param segments The list of segments
         */
        void parse(List<PathSegment> segments)
            {
            StringBuffer buff     = new StringBuffer();
            StringBuffer modBuff  = new StringBuffer();
            Int          varCount = 0;
            
            NextChar: for (Char c : templateText)
                {
                switch (state)
                    {
                    case STATE_TEXT:
                        if (c == VAR_START)
                            {
                            if (buff.size > 0)
                                {
                                String value = buff.toString();
                                addRawContentSegment(segments, value, isQuerySegment);
                                }
                            buff.clear();
                            state = STATE_VAR_START;
                            continue NextChar;
                            } 
                        else 
                            {
                            if (c == QUERY_OPERATOR || c == HASH_OPERATOR) 
                                {
                                isQuerySegment = True;
                                }
                            buff.append(c);
                            continue NextChar;
                            }
                    case STATE_VAR_MODIFIER:
                    case STATE_VAR_NEXT_MODIFIER:
                        if (c == ' ')
                            {
                            continue NextChar;
                            }
                        continue;
                    case STATE_VAR_NEXT:
                    case STATE_VAR_CONTENT:
                        switch (c)
                            {
                            case ':':
                            case EXPAND_MODIFIER: // arrived to expansion modifier
                                if (state == STATE_VAR_MODIFIER || state == STATE_VAR_NEXT_MODIFIER) 
                                    {
                                    modBuff.append(c);
                                    continue NextChar;
                                    }
                                modifier = c;
                                state = state == STATE_VAR_NEXT ? STATE_VAR_NEXT_MODIFIER : STATE_VAR_MODIFIER;
                                continue NextChar;
                            case ',': // arrived to new variable
                                state = STATE_VAR_NEXT;
                                continue;
                            case VAR_END: // arrived to variable end
                                if (buff.size > 0) 
                                    {
                                    String  value  = buff.toString();
                                    String? prefix = Null;
                                    String  delimiter;
                                    Boolean encode;
                                    Boolean repeatPrefix;
                                    switch (operator) 
                                        {
                                        case '+':
                                            encode = False;
                                            prefix = Null;
                                            delimiter = ",";
                                            repeatPrefix = varCount < 1;
                                            break;
                                        case HASH_OPERATOR:
                                            encode = False;
                                            repeatPrefix = varCount < 1;
                                            prefix = operator.toString();
                                            delimiter = ",";
                                            break;
                                        case DOT_OPERATOR:
                                        case SLASH_OPERATOR:
                                            encode = True;
                                            repeatPrefix = varCount < 1;
                                            prefix = operator.toString();
                                            delimiter = modifier == EXPAND_MODIFIER ? prefix : ",";
                                            break;
                                        case ';':
                                            encode = True;
                                            repeatPrefix = True;
                                            prefix = operator + value + '=';
                                            delimiter = modifier == EXPAND_MODIFIER ? prefix : ",";
                                            break;
                                        case QUERY_OPERATOR:
                                        case AND_OPERATOR:
                                            encode = True;
                                            repeatPrefix = True;
                                            prefix = varCount < 1 ? operator + value + '=' : value + "=";
                                            delimiter = modifier == EXPAND_MODIFIER ? AND_OPERATOR + value + '=' : ",";
                                            break;
                                        default:
                                            repeatPrefix = varCount < 1;
                                            encode = True;
                                            prefix = Null;
                                            delimiter = ",";
                                            break;
                                        }

                                    String  modifierStr  = modBuff.toString();
                                    Char    modifierChar = modifier;
                                    String? previous     = state == STATE_VAR_NEXT || state == STATE_VAR_NEXT_MODIFIER ? this.varDelimiter : Null;

                                    addVariableSegment(segments, value, prefix, delimiter, encode,
                                            repeatPrefix, modifierStr, modifierChar, operator,
                                            previous, isQuerySegment);
                                    }
    
                                Boolean hasAnotherVar = state == STATE_VAR_NEXT && c != VAR_END;
    
                                if (hasAnotherVar) 
                                    {
                                    String? delimiter;
                                    switch (operator) 
                                        {
                                        case ';':
                                            delimiter = Null;
                                            break;
                                        case QUERY_OPERATOR:
                                        case AND_OPERATOR:
                                            delimiter = "&";
                                            break;
                                        case DOT_OPERATOR:
                                        case SLASH_OPERATOR:
                                            delimiter = operator.toString();
                                            break;
                                        default:
                                            delimiter = ",";
                                            break;
                                        }
                                    varDelimiter = delimiter;
                                    varCount++;
                                    } 
                                else 
                                    {
                                    varCount = 0;
                                    }
                                state = hasAnotherVar ? STATE_VAR_NEXT : STATE_TEXT;
                                modBuff.clear();
                                buff.clear();
                                modifier = OPERATOR_NONE;
                                if (!hasAnotherVar) 
                                    {
                                    operator = OPERATOR_NONE;
                                    }
                                continue NextChar;
                            default:
                                switch (modifier) 
                                    {
                                    case EXPAND_MODIFIER:
                                        throw new IllegalState("Expansion modifier * must be immediately followed by a closing brace '}'");
                                    case ':':
                                        modBuff.append(c);
                                        continue NextChar;
                                    default:
                                        buff.append(c);
                                        continue NextChar;
                                    }
                            }
                    case STATE_VAR_START:
                        switch (c) 
                            {
                            case ' ':
                                continue NextChar;
                            case ';':
                            case QUERY_OPERATOR:
                            case AND_OPERATOR:
                            case HASH_OPERATOR:
                                isQuerySegment = True;
                                continue;
                            case '+':
                            case DOT_OPERATOR:
                            case SLASH_OPERATOR:
                                operator = c;
                                state = STATE_VAR_CONTENT;
                                continue NextChar;
                            default:
                                state = STATE_VAR_CONTENT;
                                buff.append(c);
                                break;
                            }
                        break;
                    default:
                        // no-op
                        break;
                    }
                }

            if (state == STATE_TEXT && buff.size > 0)
                {
                String value = buff.toString();
                addRawContentSegment(segments, value, isQuerySegment);
                }
            }

        /**
         * Adds a raw content segment.
         *
         * @param segments       The segments
         * @param value          The value
         * @param isQuerySegment Whether is a query segment
         */
        protected void addRawContentSegment(List<PathSegment> segments, String value, Boolean isQuerySegment)
            {
            segments.add(new RawPathSegment(isQuerySegment, value));
            }

        /**
         * Adds a new variable segment.
         *
         * @param segments          The segments to augment
         * @param variable          The variable
         * @param prefix            The prefix to use when expanding the variable
         * @param delimiter         The delimiter to use when expanding the variable
         * @param encode            Whether to URL encode the variable
         * @param repeatPrefix      Whether to repeat the prefix for each expanded variable
         * @param modifierStr       The modifier string
         * @param modifierChar      The modifier as Char
         * @param operator          The currently active operator
         * @param previousDelimiter The delimiter to use if a variable appeared before this variable
         * @param isQuerySegment    Whether is a query segment
         */
        protected void addVariableSegment(List<PathSegment> segments,
                                       String variable,
                                       String? prefix,
                                       String? delimiter,
                                       Boolean encode,
                                       Boolean repeatPrefix,
                                       String modifierStr,
                                       Char modifierChar,
                                       Char operator,
                                       String? previousDelimiter,
                                       Boolean isQuerySegment)
            {
            segments.add(new VariablePathSegment(isQuerySegment, variable, prefix, delimiter,
                    encode, modifierChar, operator, modifierStr, previousDelimiter, repeatPrefix));
            }
        }

    // ----- inner interface: PathSegment ----------------------------------------------------------

    /**
     * Represents an expandable path segment parsed from the template.
     */
    protected static interface PathSegment
            extends immutable Const
            extends Stringable
            extends Hashable
        {
        @RO Int size;

        /**
         * @return Whether this segment is part of the query string
         */
        @RO Boolean isQuerySegment;

        /**
         * If this path segment represents a variable returns the underlying variable name.
         *
         * @return The variable name if present
         */
        conditional String getVariable() {
            return False;
        }

        /**
         * @return True if this is a variable segment
         */
        Boolean isVariable() {
            return getVariable();
        }

        /**
         * Expands this segment using the specified parameters.
         *
         * @param parameters              the parameters to use in the expansion
         * @param previousHasContent      True if there was previous content
         * @param anyPreviousHasOperator  True if an operator is present
         *
         * @return the expanded string
         */
        String? expand(Map<String, Object> parameters,
                       Boolean             previousHasContent,
                       Boolean             anyPreviousHasOperator);

        @Op("[]")
        Char charAt(Int index);

        @Op("[..]")
        String slice(Range<Int> indexes);
        }


    // ----- inner class: RawPathSegment -----------------------------------------------------------

    /**
     * A raw path segment implementation.
     */
    static const RawPathSegment(Boolean isQuerySegment, String value)
            implements PathSegment
        {
        @Override
        Int size.get()
            {
            return value.size;
            }

        @Override
        String? expand(Map<String, Object> parameters,
                       Boolean previousHasContent,
                       Boolean anyPreviousHasOperator)
            {
            return value;
            }

        @Op("[]")
        @Override
        Char charAt(Int index)
            {
            return value[index];
            }

        @Op("[..]")
        @Override
        String slice(Range<Int> indexes)
            {
            return value.slice(indexes);
            }

        // ----- Stringable methods ------------------------------------------------------------

        @Override
        Int estimateStringLength()
            {
            return value.size;
            }

        @Override
        Appender<Char> appendTo(Appender<Char> buf)
            {
            return value.appendTo(buf);
            }
        }

    // ----- inner class: VariablePathSegment ------------------------------------------------------

    /**
     * A variable path segment implementation.
     */
    static const VariablePathSegment(Boolean isQuerySegment,
                              String variable, String? prefix, String? delimiter,
                              Boolean encode, Char modifierChar, Char operator,
                              String modifierStr, String? previousDelimiter, Boolean repeatPrefix)
            implements PathSegment
        {
        // ----- properties --------------------------------------------------------------------

        @Lazy String stringValue.calc()
            {
            StringBuffer builder = new StringBuffer();
            builder.append(variable);
            if (modifierChar != OPERATOR_NONE)
                {
                builder.append(modifierChar);
                builder.append(modifierStr);
                }
            return builder.toString();
            }

        @Override
        Int size.get()
            {
            return stringValue.size;
            }

        // ----- PathSegment methods -----------------------------------------------------------

        @Op("[]")
        @Override
        Char charAt(Int index)
            {
            return stringValue[index];
            }

        @Op("[..]")
        @Override
        String slice(Range<Int> indexes)
            {
            return stringValue.slice(indexes);
            }

        @Override
        conditional String getVariable()
            {
            return True, variable;
            }

        @Override
        public String? expand(Map<String, Object> parameters,
                              Boolean             previousHasContent,
                              Boolean             anyPreviousHasOperator)
            {
            // ToDo:
            return Null;
            }

        // ----- Stringable methods ------------------------------------------------------------

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

        // ----- helper methods ----------------------------------------------------------------

        /**
         * Replace all instances of '%' in the specified String with "%25"
         * and all instances of whitespace with "%20%".
         */
        private String escape(String v)
            {
            String s = PATTERN_PERCENT.match(v).replaceAll("%25");
            return PATTERN_SPACE.match(v).replaceAll("%20");
            }

        private String applyModifier(String modifierStr, Char modifierChar, String result, Int len)
            {
            if (modifierChar == ':' && modifierStr.size > 0 && modifierStr[0].isDigit())
                {
                try
                    {
                    Int subResult = new IntLiteral(modifierStr.trim());
                    if (subResult < len)
                        {
                        result = result[0..subResult];
                        }
                    }
                catch (IllegalArgument e)
                    {
                    result = ":" + modifierStr;
                    }
                }
            return result;
            }

        /**
         * Encode the specified String suitable for use in a URL.
         *
         * @param str    the String to encode
         * @param query  True if the String is a query parameter
         *
         * @return the encoded String
         */
        private String encodeString(String str, Boolean query)
            {
            // ToDo:
            return str;
            }
        }
    }