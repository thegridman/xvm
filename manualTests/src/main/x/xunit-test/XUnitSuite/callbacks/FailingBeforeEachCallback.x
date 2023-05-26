import xunit.ExecutionContext;
import xunit.extensions.BeforeEachCallback;

/**
 * A `BeforeEachCallback` that will fail with either a `PreconditionFailed`
 * or an assertion error.
 */
const FailingBeforeEachCallback(Boolean assumption = False)
        implements BeforeEachCallback
    {
    @Override
    void beforeEach(ExecutionContext ctx)
        {
        if (assumption)
            {
            throw new PreconditionFailed("Before each precondition failed");
            }
        xunit.fail("BeforeEach failed");
        }
    }