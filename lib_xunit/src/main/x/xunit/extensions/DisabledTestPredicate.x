/**
 * A `TestExecutionPredicate` that detects tests annotated with the `xunit.Disabled` mixin.
 */
const DisabledTestPredicate
        implements TestExecutionPredicate
    {
    @Override
    conditional String shouldSkip(ExecutionContext context)
        {
        if (context.testMethod != Null)
            {
            return isSkipped(context.testMethod);
            }
        if (context.testClass != Null)
            {
            return isSkipped(context.testClass);
            }
        if (context.testPackage != Null)
            {
            return isSkipped(context.testPackage);
            }
        if (context.testModule != Null)
            {
            return isSkipped(context.testModule);
            }
        return False;
        }

    private conditional String isSkipped(Object o)
        {
        if (o.is(Disabled))
            {
            return True, o.reason;
            }
        return False;
        }
    }