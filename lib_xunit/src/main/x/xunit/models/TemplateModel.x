import xunit.executor.ExceptionCollector;
import xunit.executor.ExecutionLifecycle;
import xunit.executor.DefaultExecutionContext;
import xunit.extensions.ExtensionRepository;
import xunit.templates.TestTemplateContext;
import xunit.templates.TestTemplateFactory;

class TemplateModel
        extends BaseModel
        implements ExecutionLifecycle
    {
    construct (Model templateModel)
        {
        this.templateModel = templateModel;
        construct BaseModel(templateModel.uniqueId, Container, templateModel.displayName, templateModel.constructor, templateModel.extensionProviders);
        }

    public/private Model templateModel;

    // ----- ExecutionLifecycle methods ------------------------------------------------------------

    @Override
    List<Model> getChildren(DefaultExecutionContext context)
        {
        return createChildren(templateModel.templateFactories, 0, context, new Array());
        }

	// ----- TemplateModel methods -----------------------------------------------------------------

    private List<Model> createChildren(TestTemplateFactory[] factories, Int index, DefaultExecutionContext context, List<Model> models)
        {
        if (index >= factories.size)
            {
            return models;
            }

        TestTemplateFactory           factory          = factories[index];
        Iterable<TestTemplateContext> templateContexts = factory.getTemplates(context);
        Int                           iteration        = 0;
        Model[]                       children         = new Array();

        for (TestTemplateContext templateContext : templateContexts)
            {
            (String name, Extension[] extensions, ResourceRepository.Resource[] resources)
                = templateContext.getTemplateInfo(iteration);

            if (models.empty)
                {
                children.add(new MethodTemplateModel(templateModel.as(MethodModel), displayName + " " + name, extensions, resources));
                }
            else
                {
                for (Model model : models)
                    {
                    children.add(new MethodTemplateModel(templateModel.as(MethodTemplateModel), model.displayName + " " + name, extensions, resources));
                    }
                }
            iteration++;
            }

        return createChildren(factories, index + 1, context, children);
        }

	// ----- Freezable -----------------------------------------------------------------------------

    @Override
    immutable TemplateModel! freeze(Boolean inPlace = False)
        {
        if (&this.isImmutable)
            {
            return this.as(immutable TemplateModel);
            }

        if (inPlace)
            {
            templateModel = templateModel.freeze(inPlace);
            return this.makeImmutable();
            }

        TemplateModel model = new TemplateModel(templateModel.freeze(inPlace));
        return model.makeImmutable();
        }

    }