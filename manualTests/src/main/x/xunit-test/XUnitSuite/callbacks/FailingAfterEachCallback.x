import xunit.ExecutionContext;
import xunit.extensions.AfterEachCallback;

/**
 * A `AfterEachCallback` that will fail with either a `PreconditionFailed`
 * or an assertion error.
 */
const FailingAfterEachCallback(Boolean assumption = False)
        implements AfterEachCallback
    {
    @Override
    void afterEach(ExecutionContext ctx)
        {
        if (assumption)
            {
            throw new PreconditionFailed("After each precondition failed");
            }
        xunit.fail("AfterEach failed");
        }
    }