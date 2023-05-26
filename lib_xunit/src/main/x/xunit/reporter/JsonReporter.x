
const JsonReporter(File file)
        implements TestResultReporter
    {
    construct()
        {
        @Inject Directory curDir;
        construct JsonReporter(curDir);
        }

    construct(Directory dir)
        {
        File file = dir.fileFor("test-results.json");
        if (file.exists)
            {
            file.delete();
            }
        construct JsonReporter(file.ensure());
        }

    @Override
    void report(TestResult result)
        {
        TestIdentifier id = result.id;
        if (id.kind.isContainer)
            {
            String json = $|\{"name": "{id.displayName}",\
                           | "tests": {result.testCount},\
                           | "success": {result.testsSucceeded},\
                           | "failed": {result.testsFailed},\
                           | "skipped": {result.testsSkipped},\
                           | "aborted": {result.testsAborted},\
                           |}
                           ;
            file.append(json.utf8());
            }
        else
            {
            String json = $|\{"name": "{id.displayName}",\
                           | "State": "{result.state}",\
                           | "Duration": {result.duration.milliseconds}\
                           |}
                           ;
            file.append(json.utf8());
            }
        }
    }