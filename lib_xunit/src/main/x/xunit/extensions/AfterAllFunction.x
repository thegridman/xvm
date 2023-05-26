/**
 * A `AfterAllCallback` extension implementation that wraps a
 * `TestMethodOrFunctionMixin`. When the callback is invoked,
 * the wrapped `TestMethodOrFunctionMixin` will be invoked.
 *
 * @param testMixin  the `TestMethodOrFunctionMixin` that is mixed into the
 *                   ``TestMethodOrFunction` to be invoked
 */
const AfterAllFunction(TestMethodOrFunctionMixin testMixin)
        implements AfterAllCallback
    {
    @Override Int priority.get()
        {
        return testMixin.priority;
        }

    @Override
    void afterAll(ExecutionContext context)
        {
        context.invoke(testMixin);
        }
    }
