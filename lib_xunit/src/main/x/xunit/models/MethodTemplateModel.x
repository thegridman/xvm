import xunit.executor.DefaultExecutionContext;
import xunit.extensions.ExtensionRepository;

class MethodTemplateModel
        extends MethodModel
    {
    construct(MethodModel model, String displayName, Extension[] extensions, ResourceRepository.Resource[] resources)
        {
        this.additionalExtensions  = new Array();
        this.additionalResources   = new Array();

        Model methodModel;
        if (model.is(MethodTemplateModel))
            {
            this.additionalExtensions.addAll(model.additionalExtensions);
            this.additionalResources.addAll(model.additionalResources);
            methodModel = model.methodModel;
            }
        else
            {
            methodModel = model;
            }

        this.methodModel = methodModel;
        this.additionalExtensions.addAll(extensions);
        this.additionalResources.addAll(resources);

        construct MethodModel(methodModel, displayName);
        }

    private MethodModel methodModel;

    public/private Extension[] additionalExtensions;

    public/private ResourceRepository.Resource[] additionalResources;

    // ----- MethodModel methods -------------------------------------------------------------------

    @Override
    protected void prepare(DefaultExecutionContext.Builder builder, ExtensionRepository extensions)
        {
        for (ResourceRepository.Resource resource : additionalResources)
            {
            builder.repository.register(resource);
            }

        for (Extension extension : additionalExtensions)
            {
            extensions.add(extension);
            }
        }
    }