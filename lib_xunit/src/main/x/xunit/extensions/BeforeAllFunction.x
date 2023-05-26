/**
 * A `BeforeAllCallback` extension implementation that wraps a
 * `TestMethodOrFunctionMixin`. When the callback is invoked,
 * the wrapped `TestMethodOrFunctionMixin` will be invoked.
 *
 * @param testMixin  the `TestMethodOrFunctionMixin` that is mixed into the
 *                   ``TestMethodOrFunction` to be invoked
 */
const BeforeAllFunction(TestMethodOrFunctionMixin testMixin)
        implements BeforeAllCallback
    {
    @Override Int priority.get()
        {
        return testMixin.priority;
        }

    @Override
    void beforeAll(ExecutionContext context)
        {
        context.invoke(testMixin);
        }
    }
