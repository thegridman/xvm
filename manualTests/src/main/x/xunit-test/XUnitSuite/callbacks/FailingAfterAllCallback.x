import xunit.ExecutionContext;
import xunit.extensions.AfterAllCallback;

/**
 * A `AfterAllCallback` that will fail with either a `PreconditionFailed`
 * or an assertion error.
 */
const FailingAfterAllCallback(Boolean assumption = False)
        implements AfterAllCallback
    {
    @Override
    void afterAll(ExecutionContext ctx)
        {
        if (assumption)
            {
            throw new PreconditionFailed("After all precondition failed");
            }
        xunit.fail("AfterAll failed");
        }
    }