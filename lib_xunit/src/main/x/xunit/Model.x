/**
 * A `Model` is a description of a test or test container.
 *
 * A `Model` may describe a single test method, or it may describe
 * a container of tests. A container would be a `Class`, `Package` or
 * `Module` that contains test fixtures.
 */
interface Model
        extends Stringable
        extends Freezable
        extends Orderable
    {
	/**
	 * The unique identifier for this model.
	 */
	@RO UniqueId uniqueId;

	/**
	 * The optional parent uniqueId of this model.
	 */
	UniqueId? parentId;

    /**
     * The kind of this model;
     */
    @RO Kind kind;

	/**
	 * The immutable set of children of this model.
	 */
	@RO Model[] children;

    /**
     * The human readable name for this model.
     */
    @RO String displayName;

    /**
     * The test identifier for this model.
     */
    @RO TestIdentifier identifier;

    /**
     * The constructor to use to create an instance of the test fixture.
     */
    @RO TestMethodOrFunction? constructor;

    /**
     * The `ExtensionProvider`s for this model.
     */
    @RO ExtensionProvider[] extensionProviders;

    /**
     * The priority of this `Model`.
     */
    @RO Int priority;

    /**
     * Return any `TestTemplateFactory` instances defined by this model.
     */
    @RO templates.TestTemplateFactory[] templateFactories.get()
        {
        return [];
        }

	/**
	 * Get the immutable set of all descendants of this model.
	 *
	 * A descendant is a child of this model or a child of one of
	 * its children, recursively.
	 */
	Set<Model> getDescendants()
	    {
		Set<Model> descendants = new ListSet();
		descendants.addAll(this.children);
		for (Model child : this.children)
		    {
			descendants.addAll(child.getDescendants());
		    }
		return descendants;
	    }

	/**
	 * Add the children to this model.
	 *
	 * @param models  the children to add to this model
	 */
	void addChildren(Model[] models)
	    {
	    for (Model model : models)
	        {
	        addChild(model);
	        }
	    }

	/**
	 * Add a child to this model.
	 *
	 * @param model  the child to add to this model
	 */
	void addChild(Model model);

	/**
	 * Remove a child from this model.
	 *
	 * @param model  the child to remove from this model
	 */
	void removeChild(Model model);

	/**
	 * Determine if this model is a root model.
	 *
	 * A root model is a model without a parent.
	 */
	Boolean isRoot() 
	    {
		return parentId != Null;
	    }

	/**
	 * Determine if this model describes a container.
	 */
	Boolean isContainer()
	    {
		return kind.isContainer;
	    }

	/**
	 * Determine if this model describes a test.
	 */
	Boolean isTest()
	    {
		return kind.isTest;
	    }

	/**
	 * Determine if this model may register dynamic tests during execution.
	 */
	Boolean mayRegisterTests()
	    {
		return False;
	    }

	/**
	 * Determine if the supplied model (or any of its descendants)
	 * is a test or may potentially register tests dynamically.
	 *
	 * @param Model the `Model` to check for tests
	 *
	 * @return `True` if the model is a test, contains tests, or may
	 *         later register tests dynamically
	 */
	static Boolean containsTests(Model model)
	    {
		return model.isTest() || model.mayRegisterTests()
				|| model.children.any((d) -> d.containsTests());
    	}

	/**
	 * Find the model with the supplied unique ID.
	 *
	 * @param uniqueId  the `UniqueId` to search for
	 */
	conditional Model findByUniqueId(UniqueId uniqueId);

	/**
	 * Accept a `Visitor` to the subtree starting with this model.
	 *
	 * @param visitor  the `Visitor` to accept
	 */
	void accept(ModelVisitor visitor)
	    {
	    if (visitor.is(VisitorFunction))
	        {
	        visitor(this);
	        }
        else
            {
		    visitor.visit(this);
            }

		for (Model child : children)
		    {
		    child.accept(visitor);
		    }
	    }

    /**
     * Walk this test `Model` hierarchy.
     *
     * @param walker  the Walker to use to walk the hierarchy
     */
    void walk(Walker walker)
        {
        if (kind.isContainer)
            {
            walker.onContainerStart(this);
            for (Model child : children)
                {
                child.walk(walker);
                }
            walker.onContainerEnd(this);
            }
        else
            {
            walker.onTest(this);
            }
        }

    // ---- Orderable ------------------------------------------------------------------------------

    /**
     * Compare two Model values for the purposes of ordering.
     */
    static <CompileType extends Model> Ordered compare(CompileType value1, CompileType value2)
        {
        // Highest priority comes first (i.e. reverse natural Int order)
        return value2.priority <=> value1.priority;
        }

    /**
     * Compare two Model values for equality.
     */
    static <CompileType extends Model> Boolean equals(CompileType value1, CompileType value2)
        {
        return value1.uniqueId == value2.uniqueId;
        }

    // ----- Stringable methods --------------------------------------------------------------------

    @Override
    Int estimateStringLength()
        {
        return displayName.estimateStringLength();
        }

    @Override
    Appender<Char> appendTo(Appender<Char> buf)
        {
        return displayName.appendTo(buf);
        }

    // ----- Visitor interface ---------------------------------------------------------------------

	/**
	 * A Visitor for the tree-like Model structure.
	 */
	interface Visitor
	    {
		/**
		 * Visit a `Model`.
		 *
		 * @param model  the `Model` to visit
		 */
		void visit(Model model);
    	}

    /**
     * A function that takes a `Model` and returns `void`.
     */
    typedef function void (Model) as VisitorFunction;

    /**
     * A `VisitorFunction` that is also a model `Visitor`.
     */
    typedef (Visitor | VisitorFunction) as ModelVisitor;

    // ----- Walker interface ----------------------------------------------------------------------

    /**
     * A walker that can walk a test `Model` hierarchy.
     */
    interface Walker
        {
        /**
         * Start visiting a `Model` that is a test container.
         */
        void onContainerStart(Model model);

        /**
         * Visit a `Model` that is a test.
         */
        void onTest(Model model);

        /**
         * End visiting a `Model` that is a test container.
         */
        void onContainerEnd(Model model);
        }

    // ----- Kind enum -----------------------------------------------------------------------------

	/**
	 * Supported kinds of Models.
	 */
	enum Kind
	    {
		/**
		 * Denotes that the Model is for a container.
		 */
		Container,

		/**
		 * Denotes that the Model is for a test.
		 */
		Test,

		/**
		 * Denotes that the Model is for a test
		 * that may potentially also be a container.
		 */
		ContainerAndTest;

		/**
		 * `True` if this kind represents a model for a container that can
		 * contain other models
		 */
		@Lazy Boolean isContainer.calc()
		    {
			return this == Container || this == ContainerAndTest;
		    }

		/**
		 * `True` if this kind represents a model for a test
		 */
		@Lazy Boolean isTest.calc()
		    {
			return this == Test || this == ContainerAndTest;
		    }
    	}
    }
