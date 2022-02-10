/**
 * The module for basic hosting functionality.
 */
module host.xtclang.org
    {
    package oodb   import oodb.xtclang.org;
    package imdb   import imdb.xtclang.org;
    package jsondb import jsondb.xtclang.org;

    import ecstasy.annotations.InjectedRef;

    import ecstasy.io.IOException;
    import ecstasy.io.Log;

    import ecstasy.mgmt.Container;
    import ecstasy.mgmt.ModuleRepository;
    import ecstasy.mgmt.ResourceProvider;

    import ecstasy.reflect.ClassTemplate;
    import ecstasy.reflect.FileTemplate;
    import ecstasy.reflect.ModuleTemplate;
    import ecstasy.reflect.TypeTemplate;

    import Injector.ConsoleBuffer as Buffer;

    @Inject Console          console;
    @Inject Directory        curDir;
    @Inject ModuleRepository repository;

    void run(String[] args=[])
        {
        if (args.empty)
            {
            console.println($"Error: Module is not specified");
            return;
            }

        String   path   = args[0];
        String[] errors = new String[];

        if (FutureVar result := loadAndRun(path, errors))
            {
            result.handle(e ->
                {
                console.println($"Execution error: {e}");
                return Tuple:();
                });
            }

        for (String error : errors)
            {
            console.println(error);
            }
        }

    conditional FutureVar loadAndRun(String path, Log errors)
        {
        FileTemplate fileTemplate;
        Directory    appHomeDir;

        if (!((fileTemplate, appHomeDir) := load(path, errors)))
            {
            return False;
            }

        function void() terminate = () -> {};
        Injector        injector;

        if (String dbModuleName := detectDatabase(fileTemplate))
            {
            // Directory workDir = appHomeDir.parent ?: assert; // TODO GG - breaks the second "if" below
            Directory? workDir = appHomeDir.parent;
            assert workDir != Null;

            if (DbHost dbHost := createDbHost(workDir, dbModuleName, errors))
                {
                injector  = createDbInjector(dbHost, appHomeDir);
                terminate = dbHost.closeDatabase;
                }
            else
                {
                return False;
                }
            }
        else
            {
            injector = new Injector(appHomeDir);
            }

        Container container = new Container(fileTemplate.mainModule, Lightweight, repository, injector);

        Tuple result = container.invoke^("run", Tuple:());
        &result.whenComplete((r, x) -> terminate());
        return True, &result;
        }

    /**
     * @return True iff there is a file template for the specified module path
     * @return (optional) the FileTemplate for the module
     * @return (optional) the "home" directory to use
     */
    conditional (FileTemplate, Directory) load(String path, Log errors)
        {
        File fileXtc;
        if (!(fileXtc := curDir.findFile(path)))
            {
            errors.add($"Error: {path.quoted()} - not found");
            return False;
            }

        Byte[] bytes;
        try
            {
            bytes = fileXtc.contents;
            }
        catch (IOException e)
            {
            errors.add($"Error: Failed to read the module: {fileXtc}");
            return False;
            }

        FileTemplate fileTemplate;
        try
            {
            @Inject Container.Linker linker;

            fileTemplate = linker.loadFileTemplate(bytes).resolve(repository);
            }
        catch (Exception e)
            {
            errors.add($"Error: Failed to resolve the module: {fileXtc} ({e.text})");
            return False;
            }

        Path?     buildPath = fileXtc.path.parent;
        Directory workDir  = fileXtc.store.dirFor(buildPath?) : curDir; // temporary
        Directory homeDir   = ensureHome(workDir, fileTemplate.mainModule.qualifiedName);

        return True, fileTemplate, homeDir;
        }

    /**
     * @return True iff the primary module for the specified FileTemplate depends on a Database
     *         module
     * @return (optional) the Database module name
     */
    conditional String detectDatabase(FileTemplate fileTemplate)
        {
        import ClassTemplate.Contribution;

        TypeTemplate dbTypeTemplate = oodb.Database.as(Type).template;

        for ((String name, String dependsOn) : fileTemplate.mainModule.moduleNamesByPath)
            {
            if (dependsOn != TypeSystem.MackKernel)
                {
                ModuleTemplate depModule = fileTemplate.getModule(dependsOn);

                for (Contribution contrib : depModule.contribs)
                    {
                    if (contrib.action == Incorporates &&
                            contrib.ingredient.type == dbTypeTemplate)
                        {
                        return True, dependsOn;
                        }
                    }
                }
            }
        return False;
        }

    /**
     * Create a DbHost for the specified db module.
     *
     * @return (optional) the DbHost
     */
    conditional DbHost createDbHost(Directory workDir, String dbModuleName, Log errors)
        {
        Directory      dbHomeDir = ensureHome(workDir, dbModuleName);
        DbHost         dbHost;
        ModuleTemplate dbModuleTemplate;

        @Inject Map<String, String> properties;

        switch (String impl = properties.getOrDefault("db.impl", "json"))
            {
            case "":
            case "json":
                dbHost = new JsondbHost(dbModuleName, dbHomeDir);
                break;

            default:
                errors.add($"Error: Unknown db implementation: {impl}");
                return False;
            }

        if (!(dbModuleTemplate := dbHost.ensureDBModule(repository, workDir, errors)))
            {
            errors.add($"Error: Failed to create a host for : {dbModuleName}");
            return False;
            }

        dbHost.container = new Container(dbModuleTemplate, Lightweight, repository,
                                new Injector(dbHomeDir));
        return True, dbHost;
        }

    /**
     * @return an Injector for the specified DbHost
     */
    Injector createDbInjector(DbHost dbHost, Directory appHomeDir)
        {
        import oodb.Connection;
        import oodb.RootSchema;
        import oodb.DBUser;

        function Connection(DBUser) createConnection = dbHost.ensureDatabase();

        return new Injector(appHomeDir)
            {
            @Override
            Supplier getResource(Type type, String name)
                {
                if (type.is(Type<Connection>) || type.is(Type<RootSchema>))
                    {
                    return (InjectedRef.Options opts) ->
                        {
                        // consider the injector to be passed some info about the calling
                        // container, so the host could figure out the user
                        DBUser user = new oodb.model.User(1, "test");
                        Connection conn = createConnection(user);
                        return type.is(Type<Connection>)
                                ? &conn.maskAs<Connection>(type)
                                : &conn.maskAs<RootSchema>(type);
                        };
                    }
                return super(type, name);
                }
            };
        }

    /**
     * Ensure a home directory for the specified module.
     */
    Directory ensureHome(Directory parentDir, String moduleName)
        {
        return parentDir.dirFor(moduleName).ensure();
        }

    /**
     * The Injector service.
     */
    service Injector(Directory appHomeDir)
            implements ResourceProvider
        {
        @Lazy ConsoleBuffer consoleBuffer.calc()
            {
            File consoleFile = appHomeDir.fileFor("console.log");
            if (consoleFile.exists)
                {
                // remove the old content
                consoleFile.truncate(0);
                }
            else
                {
                consoleFile.ensure();
                }
            return new ConsoleBuffer(new ConsoleBack(consoleFile));
            }

        /**
         * The "client" side of the ConsoleBuffer that operates in the injected space.
         */
        const ConsoleBuffer(ConsoleBack backService)
                implements Console
            {
            @Override
            void print(Object o)
                {
                backService.print(o.toString());
                }

            @Override
            void println(Object o = "")
                {
                backService.println(o.toString());
                }

            @Override
            String readLine()
                {
                throw new UnsupportedOperation();
                }

            @Override
            Boolean echo(Boolean flag)
                {
                throw new UnsupportedOperation();
                }

            @Override
            Appender<Char> appendTo(Appender<Char> buf)
                {
                return buf.addAll("Console");
                }
            }

        /**
         * The "service" side of the ConsoleBuffer.
         */
        class ConsoleBack(File consoleFile)
            {
            void print(String s)
                {
                consoleFile.append(s.utf8());
                }

            void println(String s)
                {
                // consider remembering the position if the file size calls for pruning
                consoleFile.append(s.utf8()).append(['\n'.toByte()]);
                }
            }

        @Override
        Supplier getResource(Type type, String name)
            {
            import Container.Linker;

            Boolean wrongName = False;
            switch (type)
                {
                case Console:
                    if (name == "console")
                        {
                        return &consoleBuffer.maskAs(Console);
                        }
                    wrongName = True;
                    break;

                case Clock:
                    if (name == "clock")
                        {
                        @Inject Clock clock;
                        return clock;
                        }
                    wrongName = True;
                    break;

                case Timer:
                    if (name == "timer")
                        {
                        @Inject Timer timer;
                        return timer;
                        }
                    wrongName = True;
                    break;

                case FileStore:
                    if (name == "storage")
                        {
                        @Inject FileStore storage;
                        return storage;
                        }
                    wrongName = True;
                    break;

                case Directory:
                    switch (name)
                        {
                        case "rootDir":
                            @Inject Directory rootDir;
                            return rootDir;

                        case "homeDir":
                            @Inject Directory homeDir;
                            return homeDir;

                        case "curDir":
                            @Inject Directory curDir;
                            return curDir;

                        case "tmpDir":
                            @Inject Directory tmpDir;
                            return tmpDir;

                        default:
                            wrongName = True;
                            break;
                        }
                    break;

                case Linker:
                    if (name == "linker")
                        {
                        @Inject Linker linker;
                        return linker;
                        }
                    wrongName = True;
                    break;

                case Random:
                    if (name == "random" || name == "rnd")
                        {
                        return (InjectedRef.Options opts) ->
                            {
                            @Inject(opts=opts) Random random;
                            return random;
                            };
                        }
                    wrongName = True;
                    break;
                }

            throw wrongName
                ? new Exception($"Invalid resource name: \"{name}\" of type \"{type}\"")
                : new Exception($"Invalid resource type: \"{type}\" for name \"{name}\"");
            }
        }
    }