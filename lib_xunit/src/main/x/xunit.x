/**
 * The XUnit test framework module.
 */
module xunit.xtclang.org
    {
    package collections import collections.xtclang.org;

    import discovery.ModuleSelector;

    /**
     * A mixin that marks a module as a test suite.
     *
     * ToDo: we should eventually be able to remove this when there is a proper "x??"
     * Ecstasy test executable that will execute tests for a given module in the same
     * way that "xec" executes a module.
     */
    mixin Suite
            into Module
        {
        /**
         * Discover and execute all the test fixtures in the `Module`.
         */
        void test()
            {
            TestConfiguration config = createTestConfiguration();
            new Runner(config).run();
            }

        TestConfiguration createTestConfiguration()
            {
            return createTestConfigurationBuilder().build();
            }

        TestConfiguration.Builder createTestConfigurationBuilder()
            {
            return TestConfiguration.builder(this);
            }
        }

    /**
     * A `method` or a `function`.
     */
    typedef Method<Object, Tuple<>, Tuple<>> | Function<<>, Tuple<>> as TestMethodOrFunction;

    /**
     * Throw an `Assertion` exception with the specified method.
     * This is typically used to indicate a test has failed.
     */
    static void fail(String? message = Null)
        {
        throw new Assertion(message);
        }

    /**
     * A mixin that has a priority order.
     */
    @Abstract mixin PriorityAnnotation(Int priority)
            implements Orderable
        {
        static Ordered compare(PriorityAnnotation value1, PriorityAnnotation value2)
            {
            // Highest priority comes first (i.e. reverse natural Int order)
            return value2.priority <=> value1.priority;
            }
        }

    const FixtureMatcher(function Boolean (Object) matcher)
        {
        Boolean matches(Object fixture)
            {
            return matcher(fixture);
            }

        static FixtureMatcher Methods = new FixtureMatcher(o -> o.is(Method));

        static FixtureMatcher Classes = new FixtureMatcher(o -> o.is(Class));

        static FixtureMatcher Packages = new FixtureMatcher(o -> o.is(Package));
        }


    mixin DisplayName(String name)
        into Test.TestTarget;

    /**
     * A provider of `Extension`s.
     */
    interface ExtensionProvider
        {
        /**
         * Returns the `Extension`s provided by this `ExtensionProvider`.
         *
         * @param context  the current `ExecutionContext`
         *
         * @return the `Extension`s.
         */
        Extension[] getExtensions(ExecutionContext context)
            {
            return new Array();
            }
        }

    /**
     * A base mixin for test mixins that extends `Test` with a group of `Omit`
     * and a specific `priority`.
     *
     * @param priority  applies an ordering to the execution of associate test extension.
     */
    @Abstract mixin AbstractTestMixin(Int priority = 0)
            extends Test(Omit, priority);

    /**
     * A base mixin for test mixins that extends `Test` with a group of `Omit`
     * and a specific `priority` that mix into a `TestMethodOrFunction`.
     *
     * @param priority  applies an ordering to the execution of associate test extension.
     */
    @Abstract mixin TestMethodOrFunctionMixin(Int priority = 0)
            extends AbstractTestMixin(priority)
            into TestMethodOrFunction;

    /**
     * A mixin on a `Method` to indicate that this method should be executed repeatedly
     * before each test method.
     *
     * * If the annotated method is declared at the `Module` level, the method is executed
     *   repeatedly before every test in the entire module.
     * * If the annotated method is declared at the `Package` level, the method is executed
     *   repeatedly before every test in that `Package`.
     * * If the annotated method is declared at the `Class` level, the method is executed
     *   repeatedly before every test in that `Class`.
     *
     * @param priority  applies an ordering to the execution of `BeforeEach` annotated methods
     *                  that apply at the same level. Execution will be highest priority first.
     */
    @Abstract mixin AbstractEach(Int priority = 0, FixtureMatcher matcher = Methods)
            extends TestMethodOrFunctionMixin(priority)
            into TestMethodOrFunction;

    /**
     * A mixin on a static `Method` or `Function` to indicate that this method should be executed
     * once before all test methods.
     *
     * * If the annotated `Method` or `Function` is declared at the `Module` level, the method is
     *   executed once before any test in the entire module.
     * * If the annotated `Method` or `Function` is declared at the `Package` level, the method is
     *   executed once before all tests in that `Package`.
     * * If the annotated `Method` or `Function` is declared at the `Class` level, the method is
     *   executed once before all test in that `Class`.
     * * If the annotated method throws an exception, no further "before" processing will be
     *   invoked, tests will not be invoked, any "after all" processing will be invoked.
     *
     * @param priority  applies an ordering to the execution of `BeforeAll` annotated methods or
     *                  functions that apply at the same level. Execution will be highest priority
     *                  first.
     */
    mixin BeforeAll(Int priority = 0)
            extends TestMethodOrFunctionMixin(priority)
            implements ExtensionProvider
            into TestMethodOrFunction
        {
        @Override
        Extension[] getExtensions(ExecutionContext context)
            {
            return super(context) + new extensions.BeforeAllFunction(this);
            }
        }

    /**
     * A mixin on a `Method` to indicate that this method should be executed repeatedly
     * before each test method.
     *
     * * If the annotated method is declared at the `Module` level, the method is executed
     *   repeatedly before every test in the entire module.
     * * If the annotated method is declared at the `Package` level, the method is executed
     *   repeatedly before every test in that `Package`.
     * * If the annotated method is declared at the `Class` level, the method is executed
     *   repeatedly before every test in that `Class`.
     * * If the annotated method throws an exception, no further "before" processing will be
     *   invoked, tests will not be invoked, any "after all" and "after each" processing will
     *   be invoked.
     *
     * @param priority  applies an ordering to the execution of `BeforeEach` annotated methods
     *                  that apply at the same level. Execution will be highest priority first.
     */
    mixin BeforeEach(Int priority = 0, FixtureMatcher matcher = Methods)
            extends AbstractEach(priority, matcher)
            implements ExtensionProvider
            into TestMethodOrFunction
        {
        @Override
        Extension[] getExtensions(ExecutionContext context)
            {
            return super(context) + new extensions.BeforeEachFunction(this);
            }
        }

    /**
     * A mixin on a static `Method` or `Function` to indicate that this method should be executed
     * once after all test methods.
     *
     * * If the annotated `Method` or `Function` is declared at the `Module` level, the method is
     *   executed once after any test in the entire module.
     * * If the annotated `Method` or `Function` is declared at the `Package` level, the method is
     *   executed once after all tests in that `Package`.
     * * If the annotated `Method` or `Function` is declared at the `Class` level, the method is
     *   executed once after all test in that `Class`.
     * * If the annotated method throws an exception, all remaining "after" processing will
     *   still be invoked.
     *
     * @param priority  applies an ordering to the execution of `AfterAll` annotated methods or
     *                  functions that apply at the same level. Execution will be highest priority
     *                  first.
     */
    mixin AfterAll(Int priority = 0)
            extends TestMethodOrFunctionMixin(priority)
            implements ExtensionProvider
            into TestMethodOrFunction
        {
        @Override
        Extension[] getExtensions(ExecutionContext context)
            {
            return super(context) + new extensions.AfterAllFunction(this);
            }
        }

    /**
     * A mixin on a `Method` to indicate that this method should be executed repeatedly
     * after each test method.
     *
     * * If the annotated method is declared at the `Module` level, the method is executed
     *   repeatedly after every test in the entire module.
     * * If the annotated method is declared at the `Package` level, the method is executed
     *   repeatedly after every test in that `Package`.
     * * If the annotated method is declared at the `Class` level, the method is executed
     *   repeatedly after every test in that `Class`.
     * * If the annotated method throws an exception, all remaining "after" processing will
     *   still be invoked.
     *
     * @param priority  applies an ordering to the execution of `AfterEach` annotated methods
     *                  that apply at the same level. Execution will be highest priority first.
     */
    mixin AfterEach(Int priority = 0, FixtureMatcher matcher = Methods)
            extends AbstractEach(priority, matcher)
            implements ExtensionProvider
            into TestMethodOrFunction
        {
        @Override
        Extension[] getExtensions(ExecutionContext context)
            {
            return super(context) + new extensions.AfterEachFunction(this);
            }
        }

    /**
     * A mixin to indicate the lifecycle of a test fixture.
     *
     * The default behaviour is to create a new instance of a test fixture for
     * every test method. This allows tests to be executed without side-affects
     * due to left over state from previous tests. To change this behaviour so
     * that all tests execute on a single instance of the fixture, annotate the
     * fixture `Class` with `@TestFixture` with a `lifecycle` value of `Singleton`.
     *
     * @param lifecycle  the reason for disabling the test.
     */
    mixin TestFixture(Lifecycle lifecycle = EveryTest)
            into Class | Type
        {
        /**
         * An enum representing the different options for the
         * lifecycle of a test fixture.
         */
        enum Lifecycle
            {
            /**
             * All tests for a fixture execute on the same instance.
             */
            Singleton,
            /**
             * Each test for a fixture executes on new fixture instance.
             */
            EveryTest
            }
        }

    /**
     * A mixin to indicate that tests should be ignored.
     *
     * Any affected test fixture will be reported as skipped, with the specified reason.
     *
     * * If the mixin is applied to a `Package` all test fixtures in that `Package` are disabled.
     * * If the mixin is applied to a `Class` all test fixtures in that `Class` are disabled.
     * * If the mixin is applied to a `Method` then that test `Method` is disabled.
     *
     * @param reason  the reason for disabling the test.
     */
    mixin Disabled(String reason)
            into Test.TestTarget;

    /**
     * An class that determines whether a test should be skipped.
     */
    interface TestExecutionPredicate
        {
        /**
         * Returns whether a test should be skipped.
         *
         * @return `True` if the test should be skipped, otherwise `False`
         * @return the reason the test should be skipped
         */
        conditional String shouldSkip(ExecutionContext context);
        }

    /**
     * An `Extension` is used to apply additional processing to a test fixture.
     *
     * @param priority  applies an ordering to the execution of methods in `Extension`
     *                  annotated classes that apply at the same level. Execution will be
     *                  highest priority first.
     */
    mixin RegisterExtension(Int priority = 0)
            extends Test(Omit, priority)
            implements ExtensionProvider
            into Property<Object, Object, Ref<Object>>
        {
        @Override
        Extension[] getExtensions(ExecutionContext context)
            {
            Extension[] extensions = super(context);
            if (Object referent := this.isConstant())
                {
                return extensions + referent.as(Extension);
                }
            else
                {
                Object? fixture = context.testFixture;
                if (fixture.is(Target))
                    {
                    return extensions + this.get(context.testFixture.as(Target)).as(Extension);
                    }
                }
            return extensions;
            }
        }

    // ---- templated tests ------------------------------------------------------------------------

    /**
     * A `RepeatedTest` is a `TestTemplate` mixin that indicates the tests in the
     * mixin target should be repeated a specified number of times.
     *
     * Each iteration of the repeated tests behaves in the same way as a regular
     * test execution, with the same lifecycle callbacks and extensions applied.
     * In addition, the current repetition and total
     * number of repetitions can be accessed by having the {@link RepetitionInfo}
     * injected.
     */
    mixin RepeatedTest(Int iterations, String group = Test.Unit, Int priority = 0)
            extends templates.TestTemplate(group, priority)
            into Method | Function
        {
        @Override
        templates.TestTemplateFactory[] getTemplates()
            {
            return super() + new templates.RepeatedTestTemplateFactory(iterations);
            }
        }

    const RepeatedTestInfo(Int count, Int iteration);

    mixin ParameterizedTest(Function<Tuple, Tuple> parameters, String group = Test.Unit, Int priority = 0)
            extends templates.TestTemplate(group, priority)
            into Method | Function
        {
        @Override
        templates.TestTemplateFactory[] getTemplates()
            {
            return super() + new templates.ParameterizedTestTemplateFactory(parameters);
            }

        static const Argument<ArgType, ArgValue extends ArgType>
            {
            construct (ArgValue value, Type<ArgType>? type = Null)
                {
                this.value = value;
                this.type = type.is(Type) ? type.as(Type<ArgType>) : &value.actualType.as(Type<ArgType>);
                }

            ArgValue value;

            Type<ArgType> type;
            }
        }


    // ---- inner interface: TestInfo --------------------------------------------------------------

    /**
     * A `TestInfo` provides information to a method on a test fixture regarding the test that is
     * being executed, or is about to be executed.
     *
     * @param displayName  the name of the test to use in reports and results
     * @param testClass    the `Class` of the current test fixture, or `Null` if there is no
     *                     test fixture.
     * @param testMethod   the `TestMethodOrFunction` that is being, or will be executed, or `Null`
     *                     if not method is currently in scope.
     */
    const TestInfo(String displayName, Class? testClass, TestMethodOrFunction? testMethod = Null)
        {
        /**
         * Create a `TestInfo` from an `ExecutionContext`.
         */
        construct (ExecutionContext context)
            {
            construct TestInfo(context.displayName, context.testClass, context.testMethod);
            }
        }


    // ---- inner const: TestIdentifier ------------------------------------------------------------

    /**
     * An identifier of a test fixture.
     *
     * @param uniqueId     the `UniqueId` for the test fixture in the test hierarchy
     * @param displayName  the human readable display name to use for the test fixture
     * @param kind         the kind of test fixture this identifier represents
     */
    const TestIdentifier(UniqueId uniqueId, String displayName, Model.Kind kind);

    // ---- inner interface: TestResultReporter ----------------------------------------------------

    /**
     * A reporter that reports the execution of a test suite.
     */
    interface TestResultReporter
        {
        /**
         * Produce a test report.
         *
         * @param result  the test result to report
         */
        void report(TestResult result);
        }
    }
