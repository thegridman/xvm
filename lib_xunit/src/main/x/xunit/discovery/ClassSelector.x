import ecstasy.reflect.ClassTemplate;

import xunit.models.*;

/**
 * A `Class` discovery selector to discover classes that that may or may not be a test fixture.
 * The class may contain other classes and/or test methods.
 */
const ClassSelector<DataType>(Class<DataType> clz)
        extends BaseSelector<DataType>
    {
    @Override
    (Selector[], Model[]) select(DiscoveryConfiguration config, UniqueId id)
        {
        Selector[] selectors = new Array();
        Model[]    models    = new Array();

        if (Model model := processContainer(config, clz, id, ContainerModel.ClassSegmentType))
            {
            models.add(model);
            }

        Type<DataType> t = clz.toType().as(Type<DataType>);
        if (t.isA(Package))
            {
            if (Object o := clz.isSingleton())
                {
                if (o.is(Package))
                    {
                    selectors.add(new PackageSelector(o));
                    }
                }
            }

        return (selectors, models);
        }
    }