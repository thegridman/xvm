import ecstasy.reflect.AnnotationTemplate;
import ecstasy.reflect.ClassTemplate;
import ecstasy.reflect.ClassTemplate.Composition;
import ecstasy.reflect.ClassTemplate.Contribution;
import ecstasy.reflect.MultiMethodTemplate;
import ecstasy.reflect.PropertyTemplate;
import ecstasy.reflect.SourceCodeInfo;
import ecstasy.reflect.TypeParameter;
import ecstasy.reflect.TypeTemplate;


/**
 * The native reflected ClassTemplate implementation for property classes.
 */
class RTPropertyClassTemplate
        extends RTComponentTemplate
        implements ClassTemplate
    {
    // ----- Composition methods -------------------------------------------------------------------

    @Override @RO ClassTemplate[] classes;
    @Override @RO Contribution[]  contribs;

    @Override
    @RO ClassTemplate? mixesInto.get()
        {
        return Null;
        }

    @Override @RO MultiMethodTemplate[] multimethods;
    @Override @RO PropertyTemplate[]    properties;
    @Override @RO Boolean               singleton;
    @Override @RO SourceCodeInfo?       sourceInfo;
    @Override @RO TypeTemplate          type;

    @Override
    @RO TypeParameter[] typeParams.get()
        {
        return [];
        }

    @Override
    @RO Boolean virtualChild.get()
        {
        return False;
        }

    @Override conditional (AnnotationTemplate, Composition) deannotate();

    @Override Class<> ensureClass(Type[] actualTypes = [])
        {
        throw new UnsupportedOperation();
        }

    // natural code (these *could* be optimized if they were made native)
    //   Boolean extends(Composition composition)
    //   conditional Boolean incorporates(Composition composition)
    //   Boolean implements(Composition composition)
    //   Boolean derivesFrom(Composition composition)
    //   conditional ClassTemplate hasSuper()
    //   Composition! annotate(AnnotationTemplate annotation)


    // ----- ClassTemplate API ---------------------------------------------------------------------

    @Override conditional PropertyTemplate fromProperty();
    }
