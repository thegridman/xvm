import ecstasy.reflect.ClassTemplate;

/**
 * A `Selector` to discover test fixtures within a `Module`.
 *
 * @param testModule  the `Module` to discover tests in
 */
const ModuleSelector<DataType extends Module>(DataType testModule)
        extends PackageSelector<DataType>(testModule, True)
    {
    }