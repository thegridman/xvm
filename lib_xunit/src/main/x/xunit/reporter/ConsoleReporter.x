
const ConsoleReporter
        extends BaseTextReporter
    {
    @Inject Console console;

    @Override
    void printLine(String s)
        {
        console.print(s);
        }
    }