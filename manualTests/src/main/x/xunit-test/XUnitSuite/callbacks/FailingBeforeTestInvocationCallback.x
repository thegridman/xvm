import xunit.ExecutionContext;
import xunit.extensions.BeforeTestInvocationCallback;

/**
 * A `BeforeTestInvocationCallback` that will fail with either a `PreconditionFailed`
 * or an assertion error.
 */
const FailingBeforeTestInvocationCallback(Boolean assumption = False)
        implements BeforeTestInvocationCallback
    {
    @Override
    void beforeTest(ExecutionContext ctx)
        {
        if (assumption)
            {
            throw new PreconditionFailed("BeforeTestInvocationCallback precondition failed");
            }
        xunit.fail("BeforeTestInvocationCallback failed");
        }
    }