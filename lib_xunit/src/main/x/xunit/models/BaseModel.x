import executor.ExecutionLifecycle;
import executor.DefaultExecutionContext;
import extensions.ExtensionRepository;

/**
 * A base class for test models.
 */
@Abstract class BaseModel
        implements Model
        implements executor.ExecutionLifecycle
    {
    /**
     * Create a `BaseModel`.
     *
     * @param uniqueId         the unique identifier of this model
     * @param kind             the `Kind` of this model
     * @param displayName      the human readable name of the test fixture this model represents
     * @param constructor      the constructor to use to create the test fixture
     * @param extensionProviders  the `ExtensionProvider`s this model will add
     */
    construct (UniqueId uniqueId, Kind kind, String displayName, TestMethodOrFunction? constructor, ExtensionProvider[] extensionProviders)
        {
        this.uniqueId           = uniqueId;
        this.kind               = kind;
        this.displayName        = displayName;
        this.constructor        = constructor;
        this.extensionProviders = extensionProviders;
        this.children           = new Array();
        }

    @Override ExtensionProvider[] extensionProviders;

    /**
     * The constructor to use to create an instance of the test fixture.
     */
    @Override TestMethodOrFunction? constructor;

	/**
	 * The unique identifier for this model.
	 */
	@Override UniqueId uniqueId;

	/**
	 * The optional parent uniqueId of this model.
	 */
	@Override UniqueId? parentId;

    /**
     * The kind of this model;
     */
    @Override Kind kind;

	/**
	 * The immutable set of children of this model.
	 */
	@Override Model[] children;

    /**
     * The human readable name for this model
     */
    @Override String displayName;

    /**
     * The test identifier for this model.
     */
    @Override @Lazy TestIdentifier identifier.calc()
        {
        return new TestIdentifier(uniqueId, displayName, kind);
        }

	@Override
    List<Model> getChildren(DefaultExecutionContext context)
        {
        return children;
        }

	@Override
	void addChild(Model child)
	    {
		child.parentId = this.uniqueId;
		children.add(child);
	    }

	@Override
	void removeChild(Model child)
	    {
	    children.remove(child);
	    child.parentId = Null;
	    }

	@Override
	conditional Model findByUniqueId(UniqueId uniqueId)
	    {
	    if (this.uniqueId == uniqueId)
	        {
	        return True, this;
	        }
	    for (Model child : children)
	        {
	        if (Model found := child.findByUniqueId(uniqueId))
	            {
	            return True, found;
	            }
	        }
	    return False;
	    }

    // ----- BaseModel methods ----------------------------------------------------------------

    @Override
	DefaultExecutionContext prepare(DefaultExecutionContext context, ExtensionRepository extensions)
	    {
	    for (ExtensionProvider ep : extensionProviders)
	        {
	        for (Extension extension : ep.getExtensions(context))
	            {
    	        extensions.add(extension, ep);
	            }
	        }
        return context;
	    }

	/**
	 * Returns the fixture to execute tests against, creating a new instance
	 * if required.
	 *
	 * @return the fixture instance, or `Null` if this model is not able to
	 *         create a fixture instance
	 */
	Object? ensureFixture(DefaultExecutionContext context, ExtensionRepository extensions, Class clz)
	    {
	    if (Object fixture := clz.isSingleton())
	        {
	        // ToDo: call pre/post fixture constructor extensions
	        return fixture;
	        }

	    // ToDo: check extensions for any test fixture factory and use it if found

	    TestMethodOrFunction? constructor = this.constructor;
	    if (constructor.is(TestMethodOrFunction))
	        {
	        // ToDo: call pre/post fixture constructor extensions
	        if (Object fixture := context.invokeSingleResult(constructor))
	            {
	            return fixture;
	            }
	        }
		return Null;
	    }
    }