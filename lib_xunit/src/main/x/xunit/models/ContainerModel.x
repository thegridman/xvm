import xunit.executor.*;
import xunit.extensions.*;
import xunit.templates.TestTemplate;

/**
 * A test model representing a container of other models.
 *
 * The type this model represents would typically be a container of
 * other models, such as a `Class`, or `Module` or `Package` containing
 * other containers or tests.
 */
class ContainerModel
        extends BaseModel
        implements ExecutionLifecycle
    {
    /**
     * Create a `ContainerModel`.
     *
     * @param id               a unique id for this test fixture
     * @param testClass        the `Class` of the test fixture
     * @param displayName      the name for this model to use when displaying test information
     * @param constructor      the constructor to use to create the test fixture
     * @param extensionProviders  the `ExtensionProvider`s this model will add
     */
    construct (UniqueId id, Class clz, String displayName, TestMethodOrFunction? constructor, ExtensionProvider[] extensionProviders)
        {
        this.testClass = clz;
        this.testType  = clz.toType();
        construct BaseModel(id, Container, displayName, constructor, extensionProviders);
        }

    /**
     * The test fixture's `Type`.
     */
    public/private Class testClass;

    /**
     * The test fixture's `Type`.
     */
    public/private Type testType;

    /**
     * A fixture type that represents a `Class`.
     */
    static String ClassSegmentType = "class";

    /**
     * A fixture type that represents a `Package`.
     */
    static String PackageSegmentType = "package";

    /**
     * A fixture type that represents a `Module`.
     */
    static String ModuleSegmentType = "module";

    @Override templates.TestTemplateFactory[] templateFactories.get()
        {
        Class testClass = this.testClass;
        if (testClass.is(TestTemplate))
            {
            return testClass.getTemplates();
            }
        return [];
        }

    // ----- ExecutionLifecycle methods ------------------------------------------------------------

    @Override
	SkipResult shouldBeSkipped(DefaultExecutionContext context, ExtensionRepository extensions)
	    {
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
	DefaultExecutionContext prepare(DefaultExecutionContext context, ExtensionRepository extensions)
	    {
	    return super(context, extensions)
	            .asBuilder(this)
                .withTestClass(testClass)
                .withTestMethod(Null)
                .build();
	    }

    @Override
	DefaultExecutionContext before(ExceptionCollector collector, DefaultExecutionContext context, ExtensionRepository extensions)
	    {
	    Class testClass = this.testClass;
	    if (testClass.is(TestFixture))
	        {
	        if (testClass.lifecycle == Singleton)
	            {
	            Object? fixture = ensureFixture(context, extensions, testClass);
	            context = context.asBuilder(this).withTestFixture(fixture).build();
	            }
	        }

        for (BeforeAllCallback before : extensions.get(BeforeAllCallback))
            {
            if (!collector.executeVoid(() -> before.beforeAll(context)))
                {
                break;
                }
            }
		return context;
	    }

    @Override
	void after(ExceptionCollector collector, DefaultExecutionContext context, ExtensionRepository extensions)
	    {
        for (AfterAllCallback after : extensions.reversed(AfterAllCallback))
            {
            if (!collector.executeVoid(() -> after.afterAll(context)))
                {
                }
            }
	    }

	// ----- Freezable -----------------------------------------------------------------------------

    @Override
    immutable ContainerModel! freeze(Boolean inPlace = False)
        {
        if (&this.isImmutable)
            {
            return this.as(immutable ContainerModel);
            }

        if (inPlace)
            {
            children = children.freeze(inPlace);
            return this.makeImmutable();
            }

        ContainerModel model = new ContainerModel(uniqueId, testClass, displayName, constructor, extensionProviders.freeze(inPlace));
        model.parentId        = parentId;
        model.children        = children.freeze(inPlace);

        return model.makeImmutable();
        }
    }
