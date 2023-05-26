
@Abstract class BaseTextReporter
        implements TestResultReporter
    {
    @Override
    void report(TestResult result)
        {
        report(result, "");
        }

    @Abstract void printLine(String s);

    private void report(TestResult result, String pad)
        {
        TestIdentifier id   = result.id;
        String         name = id.displayName;
        if (id.kind.isContainer)
            {
            if (result.state == Skipped)
                {
                printLine($"=== SKIPPED ❎  {pad}{name} (reason: {result.skipReason})");
                }
            else
                {
                printLine($"=== TEST        {pad}{name}");

                String status = result.testsFailed == 0 && result.testsAborted == 0
                    ? "=== PASS    ✅  "
                    : "=== FAILED  ❌  ";

                printLine($"{status}{pad}{name} tests={result.testCount} success={result.testsSucceeded} failed={result.testsFailed} skipped={result.testsSkipped} aborted={result.testsAborted}");
                }
            }
        else
            {
            if (result.state == Skipped)
                {
                printLine($"--- SKIPPED ❎  {pad}{name} (reason: {result.skipReason})");
                }
            else
                {
                if (result.state == Failed)
                    {
                    printLine($"--- FAILED  ❌  {pad}{name}");
                    Exception? ex = result.exception;
                    if (ex.is(Exception))
                        {
                        printLine(ex.toString());
                        }
                    }
                else
                    {
                    printLine($"--- PASS    ✅  {pad}{name} (in {result.duration})");
                    }
                }
            }
        }
    }