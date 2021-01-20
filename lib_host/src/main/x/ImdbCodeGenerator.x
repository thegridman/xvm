import ecstasy.mgmt.ModuleRepository;

import ecstasy.reflect.ClassTemplate;
import ecstasy.reflect.ClassTemplate.Contribution;
import ecstasy.reflect.FileTemplate;
import ecstasy.reflect.ModuleTemplate;
import ecstasy.reflect.PropertyTemplate;
import ecstasy.reflect.TypeTemplate;

/**
 * Code generator for imdb connection.
 */
class ImdbCodeGenerator
    {
    @Inject Console console;

    /**
     * Generate all the necessary classes to use imdb.
     */
    ModuleTemplate generateStubs(ModuleRepository repository, String dbModuleName, Directory buildDir)
        {
        ModuleTemplate dbModule = repository.getModule(dbModuleName);

        String appName = dbModuleName; // TODO GG: allow fully qualified name

        Directory moduleDir = buildDir.dirFor(appName + "_imdb");
        if (moduleDir.exists)
            {
            moduleDir.deleteRecursively();
            }
        moduleDir.create();

        ClassTemplate appSchemaTemplate;
        if (appSchemaTemplate := findSchema(dbModule)) {}
        else
            {
            throw new IllegalState($"Schema is not found in {dbModuleName} module");
            }

        String appSchema  = appSchemaTemplate.name;
        File   moduleFile = moduleDir.fileFor("module.x");

        createModule(moduleFile, appName, appSchema);

        String clientSchema = "Client" + appSchema;
        File   clientFile   = moduleDir.fileFor($"{clientSchema}.x");

        createClient(clientFile, appName, appSchema, clientSchema, appSchemaTemplate);

        // temporary; replace with the compilation of generated source
        return repository.getModule(dbModuleName + "_imdb");
        }

    conditional ClassTemplate findSchema(ModuleTemplate dbModule)
        {
        Class         schemaClass    = oodb.RootSchema;
        ClassTemplate schemaTemplate = schemaClass.baseTemplate;

        for (ClassTemplate classTemplate : dbModule.classes)
            {
            if (classTemplate.format == Interface)
                {
                for (Contribution contrib : classTemplate.contribs)
                    {
                    if (contrib.action == Implements)
                        {
                        ClassTemplate template = contrib.ingredient.as(ClassTemplate);
                        if (template == schemaTemplate)
                            {
                            return (True, classTemplate);
                            }
                        }
                    }
                }
            }
        return False;
        }

    /**
     * Create module.x source file.
     */
    void createModule(File moduleFile, String appName, String appSchema)
        {
        String moduleTemplate = $./templates/_module.txt;
        String moduleSource   = moduleTemplate
                                .replace("%appName%",   appName)
                                .replace("%appSchema%", appSchema);
        moduleFile.create();
        writeUtf(moduleFile, moduleSource);
        }

    /**
     * Create Client%appSchema%.x source file.
     */
     void createClient(File clientFile, String appName, String appSchema, String clientSchema,
                       ClassTemplate appSchemaTemplate)
        {
        String clientTemplate = $./templates/ClientClass.txt;
        String clientSource   = clientTemplate
                                .replace("%appName%",   appName)
                                .replace("%appSchema%", appSchema);

        // TODO
        // Map<String, ClassTemplate> mapDbProps = collectDBProps(appSchemaTemplate);

        clientFile.create();
        writeUtf(clientFile, clientSource);
        }

    /**
     * Collect all DB properties.
     */
    Map<String, ClassTemplate> collectDBProps(ClassTemplate appSchemaTemplate)
        {
        for (PropertyTemplate prop : appSchemaTemplate.properties)
            {
            console.println(prop);
            }
        TODO
        }

    /**
     * The code below should be replaced with
     *      file.contents = contents.utfBytes();
     */
    void writeUtf(File file, String contents)
        {
        import ecstasy.io.ByteArrayOutputStream as Stream;
        import ecstasy.io.UTF8Writer;
        import ecstasy.io.Writer;

        Stream out    = new Stream(contents.size);
        Writer writer = new UTF8Writer(out);
        writer.addAll(contents);

        file.contents = out.bytes.freeze(True);
        }
    }