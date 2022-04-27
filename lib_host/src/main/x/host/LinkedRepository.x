import ecstasy.mgmt.ModuleRepository;

import ecstasy.reflect.ModuleTemplate;


/**
 * A repository that delegates to a chain of repositories. Reads occur from the repositories in the
 * order that they were provided to the constructor. Writes occur to the first repository only.
 */
class LinkedRepository(List<ModuleRepository> repos)
        implements ModuleRepository
    {
    // ----- properties ----------------------------------------------------------------------------

    /**
     * The underlying repositories.
     */
    public/private List<ModuleRepository> repos;


    // ----- ModuleRepository API ------------------------------------------------------------------

    @Override
    immutable Set<String> moduleNames.get()
        {
        SkiplistSet<String> names = new SkiplistSet();
        for (ModuleRepository repo : repos)
            {
            names.addAll(repo.moduleNames);
            }
        return names.freeze(inPlace=True);
        }

    @Override
    ModuleTemplate getModule(String name)
        {
        for (ModuleRepository repo : repos)
            {
            if (repo.moduleNames.contains(name))
                {
                return repo.getModule(name);
                }
            }
        throw new IllegalArgument($"Module ${name} is missing");
        }

    @Override
    void storeModule(ModuleTemplate template)
        {
        repos[0].storeModule(template);
        }

    @Override
    String toString()
        {
        return $"LinkRepository({repos})";
        }
    }