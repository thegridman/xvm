import xunit.extensions.ExtensionRepository;

/**
 * The `TestExecution` controls execution of tests defined by a `Model`.
 */
class TestExecution
        implements Freezable
    {
    /**
     * Create a `TestExecution`.
     *
     * @param model          the `Model` that defines the tests to execute
     * @param configuration  the `ExecutionConfiguration` to configure execution
     */
    construct (Model model, ExecutionConfiguration configuration)
        {
        this.model         = model;
        this.lifecycle     = ExecutionLifecycle.asExecutionLifecycle(model);
        this.configuration = configuration;
        }

    /**
     * The `Clock` used to time test fixture execution.
     */
    @Inject
    Clock clock;

    /**
     * The `Model` that defines the tests to execute.
     */
    public/private Model model;

    /**
     * The `ExecutionConfiguration` to configure execution.
     */
    public/private ExecutionConfiguration configuration;

    /**
     * The current `ExecutionLifecycle`.
     */
    public/private ExecutionLifecycle lifecycle;

    /**
     * Execute the tests
     *
     * @param parentContext  the parent `DefaultExecutionContext` to use
     */
    void execute(DefaultExecutionContext parentContext)
        {
        ExtensionRepository     extensions = new ExtensionRepository();
        ExceptionCollector      collector  = new ExceptionCollector();
        SkipResult?             skipResult = Null;
        Boolean                 started    = False;
        DefaultExecutionContext context    = parentContext;
        Time                    start      = clock.now;

		if (context := collector.execute(() -> lifecycle.prepare(parentContext, extensions)))
		    {
            if (SkipResult result := collector.execute(() -> lifecycle.shouldBeSkipped(context, extensions)))
                {
                skipResult = result;
                if (collector.empty && !result.skipped)
                    {
                    context.listener.onStarted(model.identifier);
                    started = True;
                    if (context := executeRecursively(collector, context, extensions))
                        {
                        cleanUp(collector, context, extensions);

                        Duration duration = clock.now - start;
                        reportCompletion(collector, context, extensions, skipResult, started, duration);
                        }
                    else
                        {
                        @Inject Console console;
                        console.print($"Error: {collector.exception}");
                        }
                    }
                }
		    }
        }

    private conditional DefaultExecutionContext executeRecursively(ExceptionCollector collector, DefaultExecutionContext context, ExtensionRepository extensions)
        {
        return collector.execute(() ->
            {
            context = lifecycle.before(collector, context, extensions);
            if (collector.empty)
                {
                List<TestExecution> children = new Array();
                for (Model child : lifecycle.getChildren(context).sorted())
                    {
                    children.add(new TestExecution(child, configuration));
                    }

                context = lifecycle.execute(collector, context, extensions);
                for (TestExecution child : children)
                    {
                    child.execute(context);
                    }
                collector.executeVoid(() -> lifecycle.after(collector, context, extensions));
                }

            return context;
            });
        }

    private void cleanUp(ExceptionCollector collector, DefaultExecutionContext context, ExtensionRepository extensions)
        {
        collector.executeVoid(() -> lifecycle.cleanUp(collector, context, extensions));
        }

    private void reportCompletion(ExceptionCollector collector, DefaultExecutionContext context, ExtensionRepository extensions, SkipResult? skipResult, Boolean started, Duration duration)
        {
        Result result;

        if (collector.empty && skipResult.is(SkipResult) && skipResult.skipped)
            {
            result = collector.result.withDuration(duration);
            try
                {
                lifecycle.onSkipped(context, extensions, skipResult);
                }
            catch (Exception e)
                {
                @Inject Console console;
                console.print($"{e}");
                }
            context.listener.onSkipped(model.identifier, skipResult.reason);
            }
        else
            {
            if (!started)
                {
                context.listener.onStarted(model.identifier);
                }
            result = collector.result.withDuration(duration);

            try
                {
                lifecycle.onFinished(context, extensions, result);
                }
            catch (Exception e)
                {
                @Inject Console console;
                console.print($"{e}");
                }

            context.listener.onFinished(model.identifier, result);
            }
        }
	// ----- Freezable -----------------------------------------------------------------------------

    @Override
    immutable TestExecution! freeze(Boolean inPlace = False)
        {
        if (&this.isImmutable)
            {
            return this.as(immutable TestExecution);
            }

        if (inPlace)
            {
            model = model.freeze(inPlace);
            return this.makeImmutable();
            }

        TestExecution execution = new TestExecution(model.freeze(inPlace), configuration);
        return execution.makeImmutable();
        }
    }