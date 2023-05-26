import xunit.ExecutionContext;
import xunit.extensions.BeforeTestInvocationCallback;

/**
 * A `BeforeTestInvocationCallback` that counts the number of times it is invoked.
 */
class CountingBeforeTestInvocationCallback(String id = "n/a")
        implements BeforeTestInvocationCallback
    {
    Int count = 0;

    @Override
    void beforeTest(ExecutionContext ctx)
        {
        count++;
        @Inject Console console;
        console.print($"CountingBeforeTestInvocationCallback.beforeTest() id={id} count={count}");
        }
    }