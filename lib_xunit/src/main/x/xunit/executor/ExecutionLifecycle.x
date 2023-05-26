import xunit.extensions.ExtensionRepository;

/**
 * An `ExecutionLifecycle` is the callback methods implemented by a test or container
 * to handle various phases of a test lifecycle.
 */
interface ExecutionLifecycle
    {
    List<Model> getChildren(DefaultExecutionContext context)
        {
        return new Array();
        }

	/**
	 * Determine whether the execution of the supplied DefaultExecutionContext
	 * should be skipped.
	 *
	 * @param context  the `DefaultExecutionContext` to execute in
	 */
	SkipResult shouldBeSkipped(DefaultExecutionContext context, ExtensionRepository extensions)
	    {
		return SkipResult.NotSkipped;
	    }

	/**
	 * Prepare an DefaultExecutionContext prior to execution.
	 *
	 * @param context  the optional parent `DefaultExecutionContext`
	 */
	DefaultExecutionContext prepare(DefaultExecutionContext context, ExtensionRepository extensions)
	    {
		return context;
	    }

	/**
	 * Execute the before behavior of this ExecutionLifecycle.
	 *
	 * This method will be called once before execution of this ExecutionLifecycle.
	 *
	 * @param collector  the exception collector to use
	 * @param context    the `DefaultExecutionContext` to execute in
	 *
	 * @return the context to use to execute children of this ExecutionLifecycle
	 */
	DefaultExecutionContext before(ExceptionCollector collector, DefaultExecutionContext context, ExtensionRepository extensions)
	    {
		return context;
	    }

	/**
	 * Execute the behavior of this ExecutionLifecycle.
	 *
	 * Test containers (i.e. classes, modules or packages) would not typically
	 * implement this method as the `TestEngine` will handle execution of their
	 * child ExecutionLifecycles.
	 *
	 * @param collector         the exception collector to use
	 * @param context          the `DefaultExecutionContext` to execute in
	 * @param fixture   the function that supplies the test fixture
	 *
	 * @return the context to use to execute children of this ExecutionLifecycle and execution
	 *         pf the after behaviour of this ExecutionLifecycle's parent
	 */
	DefaultExecutionContext execute(ExceptionCollector collector, DefaultExecutionContext context, ExtensionRepository extensions)
	    {
		return context;
	    }

	/**
	 * Execute any after behavior for this ExecutionLifecycle.
	 * This method will be called once, after execution of this ExecutionLifecycle.
	 *
	 * @param collector  the exception collector to use
	 * @param context    the `DefaultExecutionContext` to execute in
	 */
	void after(ExceptionCollector collector, DefaultExecutionContext context, ExtensionRepository extensions)
	    {
	    }

	/**
	 * Clean up the supplied DefaultExecutionContext after execution.
	 *
	 * @param collector  the exception collector to use
	 * @param context    the `DefaultExecutionContext` to execute in
	 */
	void cleanUp(ExceptionCollector collector, DefaultExecutionContext context, ExtensionRepository extensions)
	    {
	    }

	/**
	 * a callback that will be invoked if execution of this ExecutionLifecycle was skipped.
	 *
	 * @param context     the `DefaultExecutionContext`
	 * @param model  the test model that was skipped
	 * @param result      the result of skipped execution
	 */
	void onSkipped(DefaultExecutionContext context, ExtensionRepository extensions, SkipResult result)
	    {
	    }

	/**
	 * a callback that will be invoked when execution of this ExecutionLifecycle has completed.
	 *
	 * @param context     the `DefaultExecutionContext`
	 * @param model  the test model that was skipped
	 * @param result      the result of the execution
	 */
	void onFinished(DefaultExecutionContext context, ExtensionRepository extensions, Result result)
	    {
	    }

    /**
     * Returns a `Model` as a test hierarchy `ExecutionLifecycle`.
     *
     * @param d  the `Model` to convert to a `ExecutionLifecycle`
     *
     * @return the model converted to a `ExecutionLifecycle`
     */
    static ExecutionLifecycle asExecutionLifecycle(Model d)
        {
        if (d.is(ExecutionLifecycle))
            {
            return d.as(ExecutionLifecycle);
            }
        return ExecutionLifecycle.NoOp.Instance;
        }

    /**
     * A no-op instance of a `ExecutionLifecycle`.
     */
	static const NoOp
	        implements ExecutionLifecycle
        {
        static ExecutionLifecycle Instance = new NoOp();
        }
    }
