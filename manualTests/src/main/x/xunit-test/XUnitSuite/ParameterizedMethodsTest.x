
class ParameterizedMethodsTest
    {
    @Inject Console console;

    @ParameterizedTest(simpleParameters)
    void shouldHaveStringParameter(String arg)
        {
        console.print($"Executing shouldHaveStringParameter: {arg}");
        }

    static String[] simpleParameters()
        {
        return ["Foo", "Bar"];
        }

    @ParameterizedTest(multiParameters)
    void shouldHaveTwoParameters(String stringValue, String anotherString)
        {
        console.print($"Executing shouldHaveTwoParameters: {stringValue}, {anotherString}");
        }

    static List<Tuple> multiParameters()
        {
        return [("One", "Another One"), ("Two", "Another Two")];
        }

    @ParameterizedTest(mixedParameters)
    void shouldHaveMixedParameters(String stringValue, Int intValue, String anotherString)
        {
        console.print($"Executing shouldHaveMixedParameters: {stringValue}, {intValue}, {anotherString}");
        }

    static List<Tuple> mixedParameters()
        {
        return [("One", Int:1, "Another One"), ("Two", Int:2, "Another Two")];
        }
    }