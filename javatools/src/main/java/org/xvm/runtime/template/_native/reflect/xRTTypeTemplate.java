package org.xvm.runtime.template._native.reflect;


import org.xvm.asm.Annotation;
import org.xvm.asm.ClassStructure;
import org.xvm.asm.Constant;
import org.xvm.asm.ConstantPool;
import org.xvm.asm.Constants;
import org.xvm.asm.MethodStructure;
import org.xvm.asm.Op;

import org.xvm.asm.constants.ClassConstant;
import org.xvm.asm.constants.IdentityConstant;
import org.xvm.asm.constants.PropertyConstant;
import org.xvm.asm.constants.PropertyInfo;
import org.xvm.asm.constants.TypeConstant;
import org.xvm.asm.constants.TypeInfo;

import org.xvm.runtime.Frame;
import org.xvm.runtime.ObjectHandle;
import org.xvm.runtime.ObjectHandle.GenericHandle;
import org.xvm.runtime.TemplateRegistry;
import org.xvm.runtime.TypeComposition;
import org.xvm.runtime.Utils;

import org.xvm.runtime.template.xBoolean;
import org.xvm.runtime.template.xConst;
import org.xvm.runtime.template.xEnum;
import org.xvm.runtime.template.xEnum.EnumHandle;
import org.xvm.runtime.template.xNullable;

import org.xvm.runtime.template.collections.xArray;
import org.xvm.runtime.template.collections.xArray.ArrayHandle;

import org.xvm.runtime.template.text.xString;
import org.xvm.runtime.template.text.xString.StringHandle;


/**
 * Native TypeTemplate implementation.
 */
public class xRTTypeTemplate
        extends xConst
    {
    public static xRTTypeTemplate INSTANCE;

    public xRTTypeTemplate(TemplateRegistry templates, ClassStructure structure, boolean fInstance)
        {
        super(templates, structure, false);

        if (fInstance)
            {
            INSTANCE = this;
            }
        }

    @Override
    public void initNative()
        {
        markNativeProperty("desc");
        markNativeProperty("explicitlyImmutable");
        markNativeProperty("form");
        markNativeProperty("name");
        markNativeProperty("recursive");
        markNativeProperty("underlyingTypes");

        markNativeMethod("accessSpecified",   null, null);
        markNativeMethod("annotated",         null, null);
        markNativeMethod("contained",         null, null);
        markNativeMethod("fromClass",         null, null);
        markNativeMethod("fromProperty",      null, null);
        markNativeMethod("isA",               null, null);
        markNativeMethod("modifying",         null, null);
        markNativeMethod("relational",        null, null);
        markNativeMethod("parameterized",     null, null);
        markNativeMethod("purify",            null, null);
        markNativeMethod("parameterize",      null, null);
        markNativeMethod("annotate",          null, null);
        markNativeMethod("resolveFormalType", null, null);

        getCanonicalType().invalidateTypeInfo();
        }

    @Override
    public int invokeNativeGet(Frame frame, String sPropName, ObjectHandle hTarget, int iReturn)
        {
        TypeTemplateHandle hType = (TypeTemplateHandle) hTarget;
        switch (sPropName)
            {
            case "desc":
                return getPropertyDesc(frame, hType, iReturn);

            case "explicitlyImmutable":
                return getPropertyExplicitlyImmutable(frame, hType, iReturn);

            case "form":
                return getPropertyForm(frame, hType, iReturn);

            case "name":
                return getPropertyName(frame, hType, iReturn);

            case "recursive":
                return getPropertyRecursive(frame, hType, iReturn);

            case "underlyingTypes":
                return getPropertyUnderlyingTypes(frame, hType, iReturn);
            }

        return super.invokeNativeGet(frame, sPropName, hTarget, iReturn);
        }

    @Override
    public int invokeNative1(Frame frame, MethodStructure method, ObjectHandle hTarget,
                             ObjectHandle hArg, int iReturn)
        {
        TypeTemplateHandle hType = (TypeTemplateHandle) hTarget;
        switch (method.getName())
            {
            case "isA":
                return invokeIsA(frame, hType, hArg, iReturn);

            case "parameterize":
                return invokeParameterize(frame, hType, hArg, iReturn);

            case "annotate":
                return invokeAnnotate(frame, hType, hArg, iReturn);
            }

        return super.invokeNative1(frame, method, hTarget, hArg, iReturn);
        }

    @Override
    public int invokeNativeN(Frame frame, MethodStructure method, ObjectHandle hTarget, ObjectHandle[] ahArg, int iReturn)
        {
        TypeTemplateHandle hType = (TypeTemplateHandle) hTarget;
        switch (method.getName())
            {
            case "purify":
                return invokePurify(frame, hType, iReturn);
            }

        return super.invokeNativeN(frame, method, hTarget, ahArg, iReturn);
        }

    @Override
    public int invokeNativeNN(Frame frame, MethodStructure method, ObjectHandle hTarget,
                              ObjectHandle[] ahArg, int[] aiReturn)
        {
        TypeTemplateHandle hType = (TypeTemplateHandle) hTarget;
        switch (method.getName())
            {
            case "accessSpecified":
                return invokeAccessSpecified(frame, hType, aiReturn);

            case "annotated":
                return invokeAnnotated(frame, hType, aiReturn);

            case "contained":
                return invokeContained(frame, hType, aiReturn);

            case "fromClass":
                return invokeFromClass(frame, hType, aiReturn);

            case "fromProperty":
                return invokeFromProperty(frame, hType, aiReturn);

            case "modifying":
                return invokeModifying(frame, hType, aiReturn);

            case "relational":
                return invokeRelational(frame, hType, aiReturn);

            case "parameterized":
                return invokeParameterized(frame, hType, aiReturn);

            case "resolveFormalType":
                return invokeResolveFormalType(frame, hType, (StringHandle) ahArg[0], aiReturn);
            }

        return super.invokeNativeNN(frame, method, hTarget, ahArg, aiReturn);
        }


    // ----- TypeTemplateHandle support ------------------------------------------------------------

    /**
     * Obtain a {@link TypeTemplateHandle} for the specified type.
     *
     * @param type  the {@link TypeConstant} to obtain a {@link TypeTemplateHandle} for
     *
     * @return the resulting {@link TypeTemplateHandle}
     */
    public static TypeTemplateHandle makeHandle(TypeConstant type)
        {
        TypeComposition clz = INSTANCE.ensureClass(INSTANCE.getCanonicalType(),
                INSTANCE.pool().ensureEcstasyTypeConstant("reflect.TypeTemplate"));
        return new TypeTemplateHandle(clz, type);
        }

    /**
     * Inner class: TypeTemplateHandle. This is a handle to a native TypeConstant.
     */
    public static class TypeTemplateHandle
            extends GenericHandle
        {
        protected TypeTemplateHandle(TypeComposition clz, TypeConstant type)
            {
            super(clz);

            f_type     = type;
            m_fMutable = false;
            }

        public TypeConstant getDataType()
            {
            return f_type;
            }

        @Override
        public String toString()
            {
            return super.toString() + " " + f_type;
            }

        final private TypeConstant f_type;
        }


    // ----- property implementations --------------------------------------------------------------

    /**
     * Implements property: childTypes.get()
     */
    public int getPropertyDesc(Frame frame, TypeTemplateHandle hType, int iReturn)
        {
        TypeConstant type  = hType.getDataType();
        String       sDesc = type.getValueString();
        return frame.assignValue(iReturn, xString.makeHandle(sDesc));
        }

    /**
     * Implements property: explicitlyImmutable.get()
     */
    public int getPropertyExplicitlyImmutable(Frame frame, TypeTemplateHandle hType, int iReturn)
        {
        TypeConstant type   = hType.getDataType();
        boolean      fImmut = type.isImmutabilitySpecified();
        return frame.assignValue(iReturn, xBoolean.makeHandle(fImmut));
        }

    /**
     * Implements property: form.get()
     */
    public int getPropertyForm(Frame frame, TypeTemplateHandle hType, int iReturn)
        {
        TypeConstant type  = hType.getDataType();
        EnumHandle   hForm = makeFormHandle(frame, type);
        return Utils.assignInitializedEnum(frame, hForm, iReturn);
        }

    /**
     * Implements property: name.get()
     */
    public int getPropertyName(Frame frame, TypeTemplateHandle hType, int iReturn)
        {
        String       sName = null;
        TypeConstant type  = hType.getDataType();
        if (type.isSingleDefiningConstant())
            {
            Constant id = type.getDefiningConstant();
            if (id.getFormat() == Constant.Format.Class)
                {
                sName = ((ClassConstant) id).getPathString();
                }
            }

        return frame.assignValue(iReturn, sName == null ? xNullable.NULL : xString.makeHandle(sName));
        }

    /**
     * Implements property: recursive.get()
     */
    public int getPropertyRecursive(Frame frame, TypeTemplateHandle hType, int iReturn)
        {
        TypeConstant type   = hType.getDataType();
        boolean      fRecur = type.containsRecursiveType();
        return frame.assignValue(iReturn, xBoolean.makeHandle(fRecur));
        }

    /**
     * Implements property: underlyingTypes.get()
     */
    public int getPropertyUnderlyingTypes(Frame frame, TypeTemplateHandle hType, int iReturn)
        {
        TypeConstant   typeTarget  = hType.getDataType();
        TypeConstant[] aUnderlying = TypeConstant.NO_TYPES;
        if (typeTarget.isModifyingType())
            {
            aUnderlying = new TypeConstant[] {typeTarget.getUnderlyingType()};
            }
        else if (typeTarget.isRelationalType())
            {
            aUnderlying = new TypeConstant[] {typeTarget.getUnderlyingType(), typeTarget.getUnderlyingType2()};
            }
        else if (typeTarget.isFormalTypeSequence())
            {
            aUnderlying = new TypeConstant[] {typeTarget}; // turtle type
            }

        TypeTemplateHandle[] ahTypes = new TypeTemplateHandle[aUnderlying.length];
        for (int i = 0, c = ahTypes.length; i < c; ++i)
            {
            ahTypes[i] = makeHandle(aUnderlying[i]);
            }

        ObjectHandle hArray = xArray.createImmutableArray(ensureArrayClassComposition(), ahTypes);
        return frame.assignValue(iReturn, hArray);
        }


    // ----- method implementations ----------------------------------------------------------------

    /**
     * Implementation for: {@code conditional Access accessSpecified()}.
     */
    public int invokeAccessSpecified(Frame frame, TypeTemplateHandle hType, int[] aiReturn)
        {
        TypeConstant type = hType.getDataType();
        if (type.isAccessSpecified())
            {
            ObjectHandle hEnum = Utils.ensureInitializedEnum(frame,
                    makeAccessHandle(frame, type.getAccess()));

            return frame.assignConditionalDeferredValue(aiReturn, hEnum);
            }
        return frame.assignValue(aiReturn[0], xBoolean.FALSE);
        }

    /**
     * Implementation for: {@code conditional Annotation annotated()}.
     */
    public int invokeAnnotated(Frame frame, TypeTemplateHandle hType, int[] aiReturn)
        {
        ObjectHandle hAnnotation = null; // TODO
        return hAnnotation == null
                ? frame.assignValue(aiReturn[0], xBoolean.FALSE)
                : frame.assignValues(aiReturn, xBoolean.TRUE, hAnnotation);
        }

    /**
     * Implementation for: {@code conditional TypeTemplate contained()}.
     */
    public int invokeContained(Frame frame, TypeTemplateHandle hType, int[] aiReturn)
        {
        TypeConstant typeTarget = hType.getDataType();

        // REVIEW GG + CP: include PropertyClassTypeConstant?
        if (typeTarget.isVirtualChild() || typeTarget.isAnonymousClass())
            {
            TypeTemplateHandle hParent = makeHandle(typeTarget.getParentType());
            return frame.assignValues(aiReturn, xBoolean.TRUE, hParent);
            }
        else
            {
            return frame.assignValue(aiReturn[0], xBoolean.FALSE);
            }
        }

    /**
     * Implementation for: {@code conditional Class fromClass()}.
     */
    public int invokeFromClass(Frame frame, TypeTemplateHandle hType, int[] aiReturn)
        {
        TypeConstant type = hType.getDataType();
        if (!type.isExplicitClassIdentity(true))
            {
            return frame.assignValue(aiReturn[0], xBoolean.FALSE);
            }

        IdentityConstant idClz  = type.getSingleUnderlyingClass(true);
        ClassStructure   clz    = (ClassStructure) idClz.getComponent();
        GenericHandle    hClass = xRTComponentTemplate.makeComponentHandle(clz);
        // TODO (temporarily defer) - type could be explicitly annotated (recursively) so we would
        //      have to wrap the handle that many times in an AnnotatingComposition
        return frame.assignValues(aiReturn, xBoolean.TRUE, hClass);
        }

    /**
     * Implementation for: {@code conditional PropertyTemplate fromProperty()}.
     */
    public int invokeFromProperty(Frame frame, TypeTemplateHandle hType, int[] aiReturn)
        {
        TypeConstant type = hType.getDataType();
        if (type.isSingleDefiningConstant())
            {
            Constant constDef = type.getDefiningConstant();
            if (constDef instanceof PropertyConstant)
                {
                PropertyConstant idProp        = (PropertyConstant) constDef;
                ConstantPool      pool         = idProp.getConstantPool();  // note: purposeful
                TypeConstant      typeTarget   = idProp.getClassIdentity().getType();
                TypeInfo          infoTarget   = typeTarget.ensureTypeInfo();
                PropertyInfo      infoProp     = infoTarget.findProperty(idProp);
                TypeConstant      typeReferent = infoProp.getType();
                TypeConstant      typeImpl     = pool.ensurePropertyClassTypeConstant(typeTarget, idProp);
                TypeConstant      typeProperty = pool.ensureParameterizedTypeConstant(pool.typeProperty(),
                                                    typeTarget, typeReferent, typeImpl);
                GenericHandle     hProperty    = null; // TODO PropertyTemplate from typeProperty

                return frame.assignValues(aiReturn, xBoolean.TRUE, hProperty);
                }
            }

        return frame.assignValue(aiReturn[0], xBoolean.FALSE);
        }

    /**
     * Implementation for: {@code Boolean isA(TypeTemplate that)}.
     */
    public int invokeIsA(Frame frame, TypeTemplateHandle hType, ObjectHandle hArg, int iReturn)
        {
        TypeConstant typeThis = hType.getDataType();
        TypeConstant typeThat = ((TypeTemplateHandle) hArg).getDataType();
        return frame.assignValue(iReturn, xBoolean.makeHandle(typeThis.isA(typeThat)));
        }

    /**
     * Implementation for: {@code conditional TypeTemplate modifying()}.
     */
    public int invokeModifying(Frame frame, TypeTemplateHandle hType, int[] aiReturn)
        {
        TypeConstant type = hType.getDataType();
        return type.isModifyingType()
                ? frame.assignValues(aiReturn, xBoolean.TRUE, makeHandle(type.getUnderlyingType()))
                : frame.assignValue(aiReturn[0], xBoolean.FALSE);
        }

    /**
     * Implementation for: {@code conditional (TypeTemplate, TypeTemplate) relational()}.
     */
    public int invokeRelational(Frame frame, TypeTemplateHandle hType, int[] aiReturn)
        {
        TypeConstant type = hType.getDataType();
        return type.isRelationalType()
            ? frame.assignValues(aiReturn, xBoolean.TRUE,
            makeHandle(type.getUnderlyingType()),
            makeHandle(type.getUnderlyingType2()))
            : frame.assignValue(aiReturn[0], xBoolean.FALSE);
        }

    /**
     * Implementation for: {@code conditional TypeTemplate[] parameterized()}.
     */
    public int invokeParameterized(Frame frame, TypeTemplateHandle hType, int[] aiReturn)
        {
        TypeConstant type = hType.getDataType();
        if (!type.isParamsSpecified())
            {
            return frame.assignValue(aiReturn[0], xBoolean.FALSE);
            }

        TypeConstant[]       atypes  = type.getParamTypesArray();
        int                  cTypes  = atypes.length;
        TypeTemplateHandle[] ahTypes = new TypeTemplateHandle[cTypes];
        for (int i = 0; i < cTypes; ++i)
            {
            ahTypes[i] = makeHandle(atypes[i]);
            }

        ObjectHandle hArray = xArray.createImmutableArray(ensureArrayClassComposition(), ahTypes);
        return frame.assignValues(aiReturn, xBoolean.TRUE, hArray);
        }

    /**
     * Implementation for: {@code TypeTemplate purify()}.
     */
    public int invokePurify(Frame frame, TypeTemplateHandle hType, int iReturn)
        {
        return frame.assignValue(iReturn, hType); // TODO GG - implement Pure type constant etc.
        }

    /**
     * Implementation for: {@code TypeTemplate! parameterize(TypeTemplate![] paramTypes = [])}.
     */
    public int invokeParameterize(Frame frame, TypeTemplateHandle hType, ObjectHandle hArg, int iReturn)
        {
        TypeConstant typeThis = hType.getDataType();
        ArrayHandle  hArray   = (ArrayHandle) hArg;

        if (typeThis.isParamsSpecified())
            {
            return frame.raiseException("Already parameterized: " + typeThis.getValueString());
            }

        int            cTypes = (int) hArray.m_hDelegate.m_cSize;
        TypeConstant[] aTypes = new TypeConstant[cTypes];
        for (int i = 0; i < cTypes; i++)
            {
            int iResult = hArray.getTemplate().extractArrayValue(frame, hArray, i, Op.A_STACK);
            if (iResult != Op.R_NEXT)
                {
                return frame.raiseException("Invalid type array argument");
                }
            aTypes[i] = ((TypeTemplateHandle) frame.popStack()).getDataType();

            // TODO: validate constraints
            }
        return frame.assignValue(iReturn,
                makeHandle(frame.poolContext().ensureParameterizedTypeConstant(typeThis, aTypes)));
        }

    /**
     * Implementation for: {@code TypeTemplate! annotate(AnnotationTemplate annotation)}.
     */
    public int invokeAnnotate(Frame frame, TypeTemplateHandle hType, ObjectHandle hArg, int iReturn)
        {
        TypeConstant typeThis = hType.getDataType();
        TypeConstant typeThat = ((TypeTemplateHandle) hArg).getDataType();

        if (typeThat.isExplicitClassIdentity(false))
            {
            ConstantPool  pool    = frame.poolContext();
            ClassConstant clzAnno = (ClassConstant) typeThat.getDefiningConstant();
            Annotation    anno    = pool.ensureAnnotation(clzAnno);

            // TODO: validate mixin

            return frame.assignValue(iReturn,
                    makeHandle(pool.ensureAnnotatedTypeConstant(typeThis, anno)));
            }
        return frame.raiseException("Invalid annotation: " + typeThat.getValueString());
        }

    /**
     * Implementation for: {@code conditional TypeTemplate resolveFormalType(String)}
     */
    public int invokeResolveFormalType(Frame frame, TypeTemplateHandle hType, StringHandle hName, int[] aiReturn)
        {
        TypeConstant type  = hType.getDataType();
        TypeConstant typeR = type.resolveGenericType(hName.getStringValue());

        return typeR == null
            ? frame.assignValue(aiReturn[0], xBoolean.FALSE)
            : frame.assignValues(aiReturn, xBoolean.TRUE, makeHandle(typeR));
        }


    // ----- TypeComposition caching ---------------------------------------------------------------

    /**
     * @return the TypeComposition for the TypeTemplate
     */
    public static TypeComposition ensureClassComposition()
        {
        TypeComposition clz = TYPE_TEMPLATE;
        if (clz == null)
            {
            ConstantPool pool = INSTANCE.pool();
            TypeConstant type = pool.ensureEcstasyTypeConstant("reflect.TypeTemplate");
            TYPE_TEMPLATE = clz = INSTANCE.f_templates.resolveClass(type);
            assert clz != null;
            }
        return clz;
        }

    /**
     * @return the TypeComposition for an Array of TypeTemplate
     */
    public static TypeComposition ensureArrayClassComposition()
        {
        TypeComposition clz = TYPE_TEMPLATE_ARRAY;
        if (clz == null)
            {
            ConstantPool pool = INSTANCE.pool();
            TypeConstant type = pool.ensureArrayType(
                    pool.ensureEcstasyTypeConstant("reflect.TypeTemplate"));
            TYPE_TEMPLATE_ARRAY = clz = INSTANCE.f_templates.resolveClass(type);
            assert clz != null;
            }
        return clz;
        }

    private static TypeComposition TYPE_TEMPLATE;
    private static TypeComposition TYPE_TEMPLATE_ARRAY;


    // ----- helpers -------------------------------------------------------------------------------

    /**
     * Given an Access value, determine the corresponding Ecstasy "Access" value.
     *
     * @param frame   the current frame
     * @param access  an Access value
     *
     * @return the handle to the appropriate Ecstasy {@code Access} enum value
     */
    public EnumHandle makeAccessHandle(Frame frame, Constants.Access access)
        {
        xEnum enumAccess = (xEnum) f_templates.getTemplate("reflect.Access");
        switch (access)
            {
            case PUBLIC:
                return enumAccess.getEnumByName("Public");

            case PROTECTED:
                return enumAccess.getEnumByName("Protected");

            case PRIVATE:
                return enumAccess.getEnumByName("Private");

            case STRUCT:
                return enumAccess.getEnumByName("Struct");

            default:
                throw new IllegalStateException("unknown access value: " + access);
            }
        }

    /**
     * Given a TypeConstant, determine the Ecstasy "Form" value for the type.
     *
     * @param frame  the current frame
     * @param type   a TypeConstant used at runtime
     *
     * @return the handle to the appropriate Ecstasy {@code TypeTemplate.Form} enum value
     */
    protected EnumHandle makeFormHandle(Frame frame, TypeConstant type)
        {
        xEnum enumForm = (xEnum) f_templates.getTemplate("reflect.TypeTemplate.Form");

        switch (type.getFormat())
            {
            case ParameterizedType:
            case TerminalType:
                if (type.isSingleDefiningConstant())
                    {
                    switch (type.getDefiningConstant().getFormat())
                        {
                        case NativeClass:
                            return enumForm.getEnumByName("Pure");

                        case Module:
                        case Package:
                        case Class:
                        case ThisClass:
                        case ParentClass:
                        case ChildClass:
                            return enumForm.getEnumByName("Class");

                        case Property:
                            return enumForm.getEnumByName("FormalProperty");

                        case TypeParameter:
                            return enumForm.getEnumByName("FormalParameter");

                        case FormalTypeChild:
                            return enumForm.getEnumByName("FormalChild");

                        default:
                            throw new IllegalStateException("unsupported format: " +
                                    type.getDefiningConstant().getFormat());
                        }
                    }
                else
                    {
                    return enumForm.getEnumByName("Typedef");
                    }

            case ImmutableType:
                return enumForm.getEnumByName("Immutable");

            case AccessType:
                return enumForm.getEnumByName("Access");

            case AnnotatedType:
                return enumForm.getEnumByName("Annotated");

            case TurtleType:
                return enumForm.getEnumByName("Sequence");

            case VirtualChildType:
                return enumForm.getEnumByName("Child");

            case AnonymousClassType:
                return enumForm.getEnumByName("Class");

            case PropertyClassType:
                return enumForm.getEnumByName("Property");

            case UnionType:
                return enumForm.getEnumByName("Union");

            case IntersectionType:
                return enumForm.getEnumByName("Intersection");

            case DifferenceType:
                return enumForm.getEnumByName("Difference");

            case RecursiveType:
                return enumForm.getEnumByName("Typedef");

            case UnresolvedType:
            default:
                throw new IllegalStateException("unsupported type: " + type);
            }
        }
    }
