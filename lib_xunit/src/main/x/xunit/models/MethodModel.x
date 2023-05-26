import xunit.executor.ExceptionCollector;
import xunit.executor.ExecutionLifecycle;
import xunit.executor.DefaultExecutionContext;
import xunit.executor.SkipResult;
import xunit.executor.TestInfoParameterResolver;
import xunit.extensions.AfterEachCallback;
import xunit.extensions.AfterTestInvocationCallback;
import xunit.extensions.BeforeEachCallback;
import xunit.extensions.BeforeTestInvocationCallback;
import xunit.extensions.ExtensionRepository;
import xunit.templates.TestTemplate;

/**
 * A `Model` representing a test method.
 */
class MethodModel
        extends BaseModel
        implements ExecutionLifecycle
    {
    /**
     * Create a `MethodModel`.
     *
     * @param id               a unique id for this test method
     * @param testMethod       the test `Method`
     * @param displayName      the name for this model to use when displaying test information
     * @param constructor      the constructor to use to create the test fixture
     * @param extensionProviders  the `ExtensionProvider`s this model will add
     */
    construct (UniqueId id, Class testClass, TestMethodOrFunction testMethod, String displayName, TestMethodOrFunction? constructor, ExtensionProvider[] extensionProviders)
        {
        this.testClass  = testClass;
        this.testMethod = testMethod;
        if (testClass.is(Disabled))
            {
            this.skipResult = new SkipResult(True, testClass.reason);
            }
        else if (testMethod.is(Disabled))
            {
            this.skipResult = new SkipResult(True, testMethod.reason);
            }
        else
            {
            this.skipResult = SkipResult.NotSkipped;
            }
        construct BaseModel(id, Test, displayName, constructor, extensionProviders);
        }

    construct(MethodModel model, String displayName)
        {
        construct MethodModel(model.uniqueId, model.testClass, model.testMethod, displayName, model.constructor, model.extensionProviders);
        }

    /**
     * The test method's parent `Class`.
     */
    public/private Class testClass;

    /**
     * The test method.
     */
    public/private TestMethodOrFunction testMethod;

    /**
     * The `SkipResult` indicating whether the method is skipped.
     */
    public/private SkipResult skipResult;

    /**
     * A segment type representing a test method.
     */
    static String SegmentType = "method";

    @Override templates.TestTemplateFactory[] templateFactories.get()
        {
        TestMethodOrFunction testMethod = this.testMethod;
        if (testMethod.is(TestTemplate))
            {
            return testMethod.as(Test).getTemplates();
            }
        return [];
        }

    // ----- MethodModel methods -------------------------------------------------------------------

    /**
     * Can be overridden in sub-classes that want to modify the context builder.
     *
     * @param builder     the `DefaultExecutionContext` builder that may be modified
     * @param extensions  the `ExtensionRepository` to add `Extensions` to
     */
    protected void prepare(DefaultExecutionContext.Builder builder, ExtensionRepository extensions)
        {
        }

    // ----- ExecutionLifecycle methods ------------------------------------------------------------

    @Override
	DefaultExecutionContext prepare(DefaultExecutionContext context, ExtensionRepository extensions)
	    {
	    DefaultExecutionContext.Builder builder = context.asBuilder(this)
                .withTestClass(testClass)
                .withTestMethod(testMethod);

        if (context.testFixture == Null)
            {
            builder.withTestFixture(ensureFixture(context, extensions, testClass));
            }

        prepare(builder, extensions);
	    return super(builder.build(), extensions);
        }

    @Override
	SkipResult shouldBeSkipped(DefaultExecutionContext context, ExtensionRepository extensions)
	    {
	    if (skipResult.skipped)
	        {
	        return skipResult;
	        }

	    for (TestExecutionPredicate predicate : context.repository.getResources(TestExecutionPredicate))
	        {
	        if (String reason := predicate.shouldSkip(context))
	            {
	            return new SkipResult(True, reason);
	            }
	        }

		return SkipResult.NotSkipped;
	    }

    @Override
	DefaultExecutionContext before(ExceptionCollector collector, DefaultExecutionContext context, ExtensionRepository extensions)
	    {
        return context;
	    }

    @Override
	DefaultExecutionContext execute(ExceptionCollector collector, DefaultExecutionContext context, ExtensionRepository extensions)
	    {
	    assert context.testFixture != Null;
        for (BeforeEachCallback before : extensions.get(BeforeEachCallback))
            {
            if (!collector.executeVoid(() -> before.beforeEach(context)))
                {
                break;
                }
            }

        if (collector.empty)
            {
            // run any before test invocation callbacks
            for (BeforeTestInvocationCallback before : extensions.get(BeforeTestInvocationCallback))
                {
                collector.executeVoid(() -> before.beforeTest(context));
                }

            if (collector.empty)
                {
                // only run the test if there have been no errors
                collector.executeVoid(() -> context.invoke(testMethod));
                }
            }

        // Always run all of the afters (afters run in reverse order)

        // run any after test in the context regardless of whether there have been errors
        for (AfterTestInvocationCallback after : extensions.reversed(AfterTestInvocationCallback))
            {
            collector.executeVoid(() -> after.afterTest(context));
            }

        // run any after functions in the context regardless of whether there have been errors
        for (AfterEachCallback after : extensions.reversed(AfterEachCallback))
            {
            collector.executeVoid(() -> after.afterEach(context));
            }

		return context;
	    }

    @Override
	void after(ExceptionCollector collector, DefaultExecutionContext context, ExtensionRepository extensions)
	    {
	    }

	// ----- Freezable -----------------------------------------------------------------------------

    @Override
    immutable MethodModel! freeze(Boolean inPlace = False)
        {
        if (&this.isImmutable)
            {
            return this.as(immutable MethodModel);
            }

        if (inPlace)
            {
            children = children.freeze(inPlace);
            return this.makeImmutable();
            }
            
        MethodModel model = new MethodModel(uniqueId, testClass, testMethod, displayName, constructor, extensionProviders.freeze(inPlace));
        model.parentId        = parentId;
        model.children        = children.freeze(inPlace);

        return model.makeImmutable();
        }
    }
