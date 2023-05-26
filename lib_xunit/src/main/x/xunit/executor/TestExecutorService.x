/**
 * A service that executes test fixtures.
 *
 * @param configuration  the `ExecutionConfiguration` controlling how test fixtures ae executed
 */
service TestExecutorService(ExecutionConfiguration configuration)
    {
    void submit(TestExecution execution, Model model, ExecutionListener listener)
        {
        DefaultExecutionContext context = DefaultExecutionContext.builder(model)
                .withListener(listener)
                .build();

        context.repository.register(new TestInfoParameterResolver(), Replace);
        context.repository.register(new extensions.DisabledTestPredicate(), Replace);

        execution.execute(context);
        }
    }