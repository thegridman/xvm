import xunit.ExecutionContext;
import xunit.extensions.AfterEachCallback;

/**
 * A `AfterEachCallback` that counts the number of times it is invoked.
 */
class CountingAfterEachCallback(String id = "n/a")
        implements AfterEachCallback
    {
    Int count = 0;

    @Override
    void afterEach(ExecutionContext ctx)
        {
        count++;
        @Inject Console console;
        console.print($"CountingAfterEachCallback.afterEach() id={id} count={count}");
        }
    }