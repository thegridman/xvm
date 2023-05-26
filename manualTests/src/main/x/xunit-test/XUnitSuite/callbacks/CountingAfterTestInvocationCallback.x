import xunit.ExecutionContext;
import xunit.extensions.AfterTestInvocationCallback;

/**
 * A `AfterTestInvocationCallback` that counts the number of times it is invoked.
 */
class CountingAfterTestInvocationCallback(String id = "n/a")
        implements AfterTestInvocationCallback
    {
    Int count = 0;

    @Override
    void afterTest(ExecutionContext ctx)
        {
        count++;
        @Inject Console console;
        console.print($"CountingAfterTestInvocationCallback.afterTest() id={id} count={count}");
        }
    }