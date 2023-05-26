import xunit.ExecutionContext;
import xunit.extensions.AfterTestInvocationCallback;

/**
 * A `AfterTestInvocationCallback` that will fail with either a `PreconditionFailed`
 * or an assertion error.
 */
const FailingAfterTestInvocationCallback(Boolean assumption = False)
        implements AfterTestInvocationCallback
    {
    @Override
    void afterTest(ExecutionContext ctx)
        {
        if (assumption)
            {
            throw new PreconditionFailed("AfterTestInvocationCallback precondition failed");
            }
        xunit.fail("AfterTestInvocationCallback failed");
        }
    }