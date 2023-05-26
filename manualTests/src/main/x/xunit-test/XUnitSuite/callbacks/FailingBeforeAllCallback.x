import xunit.ExecutionContext;
import xunit.extensions.BeforeAllCallback;

/**
 * A `BeforeAllCallback` that will fail with either a `PreconditionFailed`
 * or an assertion error.
 */
const FailingBeforeAllCallback(Boolean assumption = False)
        implements BeforeAllCallback
    {
    @Override
    void beforeAll(ExecutionContext ctx)
        {
        if (assumption)
            {
            throw new PreconditionFailed("Before all precondition failed");
            }
        xunit.fail("BeforeAll failed");
        }
    }