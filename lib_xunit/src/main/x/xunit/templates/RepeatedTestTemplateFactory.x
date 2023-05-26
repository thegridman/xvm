/**
 * A `RepeatedTestTemplateFactory` is a `TestTemplateFactory` that will cause a
 * templated test to executed a specified number of times.
 */
const RepeatedTestTemplateFactory(Int count)
        implements TestTemplateFactory
    {
    // ---- TestTemplateFactory --------------------------------------------------------------------

    @Override
    Iterable<TestTemplateContext> getTemplates(ExecutionContext context)
        {
        return new RepeatedTestTemplateContextIterable(new RepeatedTestTemplateContext(count));
        }

    // ---- inner const: RepeatedTestTemplateContext -----------------------------------------------

    /**
     * A `TestTemplateContext` representing a repeated test.
     *
     * @param count  the number of times the test template is repeated
     */
    const RepeatedTestTemplateContext(Int count)
            implements TestTemplateContext
        {
        @Override
        (String, Extension[], ResourceRepository.Resource[]) getTemplateInfo(Int iteration)
            {
            RepeatedTestInfoResolver resolver = new RepeatedTestInfoResolver(count, iteration);
            return $"iteration {iteration} of {count}", [], [ResourceRepository.resource(resolver, Replace)];
            }
        }

    // ---- inner const: RepeatedTestTemplateContextIterable ---------------------------------------

    /**
     * An `Iterable` representing a number of `TestTemplateContext` instances.
     * The `TestTemplateContext` instances are created lazily as they are
     * iterated over.
     *
     * @param count  the number of `TestTemplateContext` instances to iterate over
     */
    const RepeatedTestTemplateContextIterable(RepeatedTestTemplateContext context)
            implements Iterable<TestTemplateContext>
        {
        @Override
        Iterator<TestTemplateContext> iterator()
            {
            return new RepeatedTestTemplateIterator(context);
            }
        }

    // ---- inner class: RepeatedTestTemplateIterator ----------------------------------------------

    /**
     * An `Iterator` that iterates over a number of `TestTemplateContext` instances.
     *
     * @param count  the number of `TestTemplateContext` instances to iterate over
     */
    class RepeatedTestTemplateIterator(RepeatedTestTemplateContext context)
            implements Iterator<TestTemplateContext>
        {
        /**
         * The index of the next `TestTemplateContext` that will be returned.
         */
        private Int iteration = 0;

        @Override
        conditional TestTemplateContext next()
            {
            if (iteration < context.count)
                {
                iteration++;
                return True, context;
                }
            return False;
            }
        }

    // ---- inner class: RepeatedTestInfoResolver -----------------------------------------

    /**
     * A `ParameterResolver` that resolves `Parameter`s of type `RepeatedTestInfo`.
     *
     * @param count      the total number of times a repeated test will be executed
     * @param iteration  the current iteration of the repeated test (the first iteration is zero)
     */
    const RepeatedTestInfoResolver(Int count, Int iteration)
            implements ParameterResolver
        {
        @Override
        <ParamType> conditional ParamType resolve(ExecutionContext context, Parameter<ParamType> param)
            {
            if (ParamType == RepeatedTestInfo)
                {
                return True, new RepeatedTestInfo(count, iteration);
                }
            return False;
            }
        }
    }