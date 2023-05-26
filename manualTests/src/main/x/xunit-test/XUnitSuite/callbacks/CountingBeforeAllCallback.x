import xunit.ExecutionContext;
import xunit.extensions.BeforeAllCallback;

/**
 * A `BeforeAllCallback` that counts the number of times it is invoked.
 */
class CountingBeforeAllCallback(String id = "n/a")
        implements BeforeAllCallback
    {
    Int count = 0;

    @Override
    void beforeAll(ExecutionContext ctx)
        {
        count++;
        @Inject Console console;
        console.print($"CountingBeforeAllCallback.beforeAll() id={id} count={count}");
        }
    }