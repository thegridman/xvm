
const CompositeReporter(TestResultReporter[] reporters)
        implements TestResultReporter
    {
    @Override
    void report(TestResult result)
        {
        for (TestResultReporter reporter : reporters)
            {
            reporter.report(result);
            }
        }
    }
