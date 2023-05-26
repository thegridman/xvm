/**
 * Information about the current phase of execution of a test fixture.
 * A test fixture could be a test method, or a test container.
 */
interface ExecutionContext
    {
    /**
     * The `UniqueId` of the current test fixture.
     */
    @RO UniqueId uniqueId;

    /**
     * The display 
     */
    @RO String displayName;

    /**
     * The `ResourceRepository` containing resources registered for this execution.
     */
    @RO ResourceRepository repository;

    /**
     * The `Module` associated to the current test fixture.
     */
    @RO Module? testModule;

    /**
     * The `Package` associated to the current test fixture.
     */
    @RO Package? testPackage;

    /**
     * The `Class` associated to the current test fixture.
     *
     * @return `True` iff the current test fixture is a `Class` or
     *         is the child of a `Class`.
     * @return the `Class` associated to the current test fixture
     */
    @RO Class? testClass;

    /**
     * The current test method.
     */
    @RO TestMethodOrFunction? testMethod;

    /**
     * The current test fixture the test method will execute against.
     */
    @RO Object? testFixture;

    /**
     * Any `Exception`s thrown during execution of the test lifecycle.
     */
    @RO Exception? exception;

    /**
     * Invoke a `TestMethodOrFunction` using any registered `ParameterResolver` resources
     * to resolve parameters for the function.
     *
     * @param fn the `TestMethodOrFunction` to invoke
     *
     * @return the result of invoking the function
     */
    @RO MethodExecutor methodExecutor;

    /**
     * Invoke a `TestMethodOrFunction` using any registered `ParameterResolver` resources
     * to resolve parameters for the function.
     *
     * @param method the `TestMethodOrFunction` to invoke
     *
     * @return the result of invoking the function
     */
    Tuple invoke(TestMethodOrFunction method)
        {
        if (method.is(Method))
            {
            assert testFixture != Null;
            return methodExecutor.invoke(method.as(Method), testFixture, this);
            }
        return methodExecutor.invoke(method.as(Function), this);
        }

    /**
     * Invoke a `TestMethodOrFunction` using any registered `ParameterResolver` resources
     * to resolve parameters for the function and return the single result returned by the
     * invocation.
     *
     * @param method the `TestMethodOrFunction` to invoke
     *
     * @return `True` iff the invocation returned a result
     * @return the single result of invoking the function
     */
    conditional Object invokeSingleResult(TestMethodOrFunction method)
        {
        Tuple tuple = invoke(method);
        if (tuple.size > 0)
            {
            return True, tuple[0];
            }
        return False;
        }
    }