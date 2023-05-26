import xunit.models.ContainerModel;
import xunit.models.MethodModel;
import xunit.models.TemplateModel;

/**
 * A base class for `Selector` implementations.
 */
@Abstract class BaseSelector<DataType>
        implements Selector
    {
    /**
     * Produce a `Model` for the specified test container `Class`.
     *
     * @param config    the `DiscoveryConfiguration` to determine what tests to select
     * @param clz       the `Class` to discover tests in
     * @param parentId  the `UniqueId` of the model's parent model
     * @param idType    the identifier type for the model
     *
     */
    conditional Model processContainer(DiscoveryConfiguration config, Class clz, UniqueId parentId, String idType)
        {
        Class[] childClasses = new Array();
        for (Type type : clz.toType().childTypes.values)
            {
            if (Class childClass := type.fromClass())
                {
                childClasses.add(childClass);
                }
            }
        return processContainer(config, clz, childClasses, parentId, idType);
        }

    /**
     * Produce a `Model` for the specified test container `Class`.
     *
     * @param config    the `DiscoveryConfiguration` to determine what tests to select
     * @param clz       the `Class` to discover tests in
     * @param children  the children of the container class to process
     * @param parentId  the `UniqueId` of the model's parent model
     * @param idType    the identifier type for the model
     *
     */
    conditional Model processContainer(DiscoveryConfiguration config, Class clz, Class[] children, UniqueId parentId, String idType)
        {
        DisplayNameGenerator  generator          = config.displayNameGenerator;
        String                name               = generator.nameForClass(clz);
        UniqueId              classId            = parentId.append(idType, clz.name);
        Type                  type               = clz.toType();
        TestMethodOrFunction? constructor        = clz.isSingleton() ? Null : findConstructor(type);
        ExtensionProvider[]   extensionProviders = new Array();

        findExtensions(type.functions,  extensionProviders);
        findExtensions(type.methods,    extensionProviders);
        findExtensions(type.properties, extensionProviders);
        findExtensions(type.constants,  extensionProviders);


        Model model = new ContainerModel(classId, clz, name, constructor, extensionProviders);
        if (clz.is(templates.TestTemplate))
            {
            model = new TemplateModel(model);
            }

        Test[] testMethods = new Array();

        for (Function fn : type.functions)
            {
            if (fn.is(Test) && fn.group != Test.Omit)
                {
                testMethods.add(fn);
                }
            }

        for (Method method : type.methods)
            {
            if (method.is(Test) && method.group != Test.Omit)
                {
                testMethods.add(method);
                }
            }

        for (Test test : testMethods.sorted())
            {
            if (test.is(TestMethodOrFunction))
                {
                UniqueId childId     = classId.append(MethodModel.SegmentType, test.name);
                String   displayName = generator.nameForMethod(clz, test);
                Model    methodModel = new MethodModel(childId, clz, test, displayName, constructor, extensionProviders);
                if (test.is(templates.TestTemplate))
                    {
                    methodModel = new TemplateModel(methodModel);
                    }
                model.addChild(methodModel);
                }
            }

        // process nested classes
        for (Class childClass : children)
            {
            if (childClass.abstract || (childClass.is(Test) && childClass.group == Test.Omit))
                {
                // skip over abstract and omitted classes
                continue;
                }

            Type childType = childClass.toType();
            if (childType.isA(Package))
                {
                if (Object o := childClass.isSingleton())
                    {
                    Package pkg = o.as(Package);
                    if (pkg.isModuleImport())
                        {
                        // skip module imports
                        continue;
                        }
                    if (Model childModel := processContainer(config, childClass, pkg.classes, classId, ContainerModel.PackageSegmentType))
                        {
                        model.addChild(childModel);
                        }
                    }
                }
            else if (Model childModel := processContainer(config, childClass, classId, ContainerModel.ClassSegmentType))
                {
                model.addChild(childModel);
                }
            }

        if (model.children.empty)
            {
            return False;
            }

        return True, model;
        }

    private void findExtensions(Iterable iter, ExtensionProvider[]   extensionProviders)
        {
        for (Object o : iter)
            {
            if (o.is(ExtensionProvider))
                {
                extensionProviders.add(o);
                }
            }
        }

    /**
     * Find the constructor that should be used to create instances of
     * the specified type.
     *
     * If any constructor is annotated with `@Test` that constructor will be used.
     * If multiple constructors are annotated with `@Test`, the first constructor
     * found will be used, which may be non-deterministic.
     *
     * If not constructors are annotated with `@Test` the default constructor will be used,
     * which is either a no-arg constructor, or a constructor where all parameters have
     * default values.
     *
     * @param type  the `Type` to find the constructor for
     *
     * @return the constructor to use, or `Null` if no constructor can be found for the type.
     */
    private Function<<>, <Object>>? findConstructor(Type type)
        {
        Function<<>, <Object>>? constructor = Null;
        for (Function<Tuple, <>> c : type.constructors)
            {
            if (c.is(Test))
                {
                constructor = c;
                break;
                }
            else if (c.requiredParamCount == 0)
                {
                constructor = c;
                }
            }
        return constructor;
        }
    }