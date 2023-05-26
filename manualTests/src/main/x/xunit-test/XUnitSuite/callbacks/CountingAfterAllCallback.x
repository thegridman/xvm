import xunit.ExecutionContext;
import xunit.extensions.AfterAllCallback;

/**
 * A `AfterAllCallback` that counts the number of times it is invoked.
 */
class CountingAfterAllCallback(String id = "n/a")
        implements AfterAllCallback
    {
    Int count = 0;

    @Override
    void afterAll(ExecutionContext ctx)
        {
        count++;
        @Inject Console console;
        console.print($"CountingAfterAllCallback.afterAll() id={id} count={count}");
        }
    }