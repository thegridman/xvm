import xunit.ExecutionContext;
import xunit.extensions.BeforeEachCallback;

/**
 * A `BeforeEachCallback` that counts the number of times it is invoked.
 */
class CountingBeforeEachCallback(String id = "n/a")
        implements BeforeEachCallback
    {
    Int count = 0;

    @Override
    void beforeEach(ExecutionContext ctx)
        {
        count++;
        @Inject Console console;
        console.print($"CountingBeforeEachCallback.beforeEach() id={id} count={count}");
        }
    }
