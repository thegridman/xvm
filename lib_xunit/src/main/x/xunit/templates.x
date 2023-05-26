/**
 * The `templates` package contains classes that control execution of templated tests.
 */
package templates
    {
    /**
     * A `TestTemplate` indicates that the target defines a test that is executed
     * zero ro more times, based on the provided `TestTemplateFactory` instances.
     */
    @Abstract mixin TestTemplate(String group = Unit, Int priority = 0)
            extends Test(group, priority)
            into Module | Package | Class | Method | Function
        {
        /**
         * @return the `TestTemplateFactory` instances to use to control execution of
         * the templated test.
         *
         * Concrete implementations of this method should call `super()` and then append
         * additional `TestTemplateFactory` instances to the returned `TestTemplateFactory`
         * array. This allows nesting of `TestTemplate` mixins. For example a test method
         * could be annotated with both `ParameterizedTest` and `RepeatedTest` to execute
         * the templated test with each set of parameters a repeated number of times.
         */
        TestTemplateFactory[] getTemplates()
            {
            return [];
            }
        }

    /**
     * A factory that produces instances of `TestTemplateContext` that will be used
     * to execute a templated test.
     */
    interface TestTemplateFactory
        {
        /**
         * @return `True` if the factory is enabled.
         */
        @RO Boolean enabled.get()
            {
            return True;
            }

        /**
         * Return the `TestTemplateContext`s to use to execute the templated test.
         *
         * The order of the `TestTemplateContext`s returned should ideally be deterministic,
         * so that repeated calls return the same list, which allows test discovery `Selector`s
         * to be used to run just a sub-set of the test iterations.
         */
        Iterable<TestTemplateContext> getTemplates(ExecutionContext context);
        }

    /**
     * A `TestTemplateContext` provides a context to use to execute
     * tests in a `TestTemplate`.
     */
    interface TestTemplateContext
        {
        /**
         * Returns the information to use for the specified iteration of the `TestTemplate`.
         *
         * @param iteration  the iteration of the test to be executed
         *
         * @return  the display name to use for the specified iteration of the `TestTemplate`.
         * @return  any additional `Extension`s for the specified iteration of the `TestTemplate`.
         * @return  any additional `ResourceRegistry.Resource`s to register for the specified
         *          iteration of the `TestTemplate`.
         */
        (String, Extension[], ResourceRepository.Resource[]) getTemplateInfo(Int iteration);
        }
    }