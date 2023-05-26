import ecstasy.reflect.ClassTemplate;

import xunit.models.*;

/**
 * A `Selector` to discover test fixtures within a `Package`.
 *
 * @param package   the `Package` to discover tests fixtures in
 * @param isModule  true iff the `Package` is also a `Module`
 */
const PackageSelector<DataType extends Package>(Package pkg, Boolean isModule = False)
        extends BaseSelector<DataType>
    {
    @Override
    (Selector[], Model[]) select(DiscoveryConfiguration config, UniqueId id)
        {
        Selector[]     selectors = new Array();
        Model[]        models    = new Array();
        String         idType    = isModule ? "module" : "package";
        Class<Package> pkgClass  = &pkg.actualClass.as(Class<Package>);

        if (Model model := processContainer(config, pkgClass, pkg.classes, id, idType))
            {
            models.add(model);
            }

        return (selectors, models);
        }
    }