package org.xvm.compiler.ast;


import java.lang.reflect.Field;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;

import org.xvm.asm.Annotation;
import org.xvm.asm.Argument;
import org.xvm.asm.ClassStructure;
import org.xvm.asm.Component;
import org.xvm.asm.Constant;
import org.xvm.asm.ConstantPool;
import org.xvm.asm.Constants.Access;
import org.xvm.asm.ErrorListener;
import org.xvm.asm.MethodStructure;
import org.xvm.asm.MethodStructure.Code;
import org.xvm.asm.Op;
import org.xvm.asm.Parameter;
import org.xvm.asm.PropertyStructure;
import org.xvm.asm.Register;

import org.xvm.asm.ast.ExprAST;
import org.xvm.asm.ast.NewExprAST;
import org.xvm.asm.ast.OuterExprAST;

import org.xvm.asm.constants.AnnotatedTypeConstant;
import org.xvm.asm.constants.ClassConstant;
import org.xvm.asm.constants.DynamicFormalConstant;
import org.xvm.asm.constants.ExpressionConstant;
import org.xvm.asm.constants.MethodConstant;
import org.xvm.asm.constants.PropertyConstant;
import org.xvm.asm.constants.RegisterConstant;
import org.xvm.asm.constants.TypeConstant;
import org.xvm.asm.constants.TypeInfo;
import org.xvm.asm.constants.TypeInfo.MethodKind;

import org.xvm.asm.op.*;

import org.xvm.compiler.Compiler;
import org.xvm.compiler.Compiler.Stage;
import org.xvm.compiler.Token;
import org.xvm.compiler.Token.Id;

import org.xvm.compiler.ast.Context.CaptureContext;

import org.xvm.util.Severity;

import static org.xvm.util.Handy.indentLines;


/**
 * "New object" expression.
 */
public class NewExpression
        extends Expression
    {
    // ----- constructors --------------------------------------------------------------------------

    /**
     * Construct a ".new" expression.
     *
     * @param left      the "left" expression
     * @param operator  presumably, the "new" operator
     * @param type      the type being instantiated (can be null for virtual new)
     * @param args      a list of constructor arguments for the type being instantiated
     * @param dims      the number of arguments inside square brackets (the rest are in the trailing
     *                  parenthesized argument list), or -1 if no square brackets
     * @param body      the body of the anonymous inner class being instantiated, or null
     * @param lEndPos   the expression's end position in the source code
     */
    public NewExpression(Expression left, Token operator, TypeExpression type, List<Expression> args, int dims, StatementBlock body, long lEndPos)
        {
        assert operator != null;
        assert args != null;

        this.left     = left;
        this.operator = operator;
        this.type     = type;
        this.args     = args;
        this.dims     = dims;
        this.body     = body;
        this.lEndPos  = lEndPos;
        }


    // ----- accessors -----------------------------------------------------------------------------

    @Override
    public boolean isComponentNode()
        {
        return body != null;
        }

    /**
     * @return true iff the new expression is for a "virtual new" (this.new(...))
     */
    public boolean isVirtualNew()
        {
        return type == null;
        }

    /**
     * @return true iff there were square brackets as part of the new expression
     */
    public boolean hasSquareBrackets()
        {
        return dims >= 0;
        }

    /**
     * @return the number of constructor arguments that were inside of square brackets
     */
    public int getDimensionCount()
        {
        return Math.max(dims, 0);
        }

    @Override
    public boolean isAutoNarrowingAllowed(TypeExpression type)
        {
        // auto-narrowing is allowed for type parameters, but not the type itself
        return type != this.type;
        }

    @Override
    public long getStartPosition()
        {
        return left == null ? operator.getStartPosition() : left.getStartPosition();
        }

    @Override
    public long getEndPosition()
        {
        return lEndPos;
        }

    @Override
    protected Field[] getChildFields()
        {
        return CHILD_FIELDS;
        }


    // ----- AstNode methods -----------------------------------------------------------------------

    @Override
    public AstNode clone()
        {
        NewExpression exprClone = (NewExpression) super.clone();
        // the "body" is not a child and has to be handled manually
        if (body != null)
            {
            exprClone.body = (anon == null)
                    ? (StatementBlock) body.clone()
                    : exprClone.anon.body;
            }
        return exprClone;
        }

    @Override
    protected void discard(boolean fRecurse)
        {
        super.discard(fRecurse);

        if (fRecurse && body != null)
            {
            body.discard(fRecurse);
            }
        }


    // ----- Code Container methods ----------------------------------------------------------------

    @Override
    protected RuntimeException notCodeContainer()
        {
        // while an inner class is technically a code container, it is not directly a code container
        // in the same sense that a method is, because it cannot directly contain a "return"
        throw new IllegalStateException("invalid return from an anonymous inner class: " + this);
        }

    /**
     * @return the AnonInnerClassContext, if captures are available from this expression, or null
     */
    public AnonInnerClassContext getCaptureContext()
        {
        return m_ctxCapture;
        }


    // ----- compilation (Expression) --------------------------------------------------------------

    @Override
    public TypeConstant getImplicitType(Context ctx)
        {
        return calculateTargetType(ctx, null);
        }

    private TypeConstant calculateTargetType(Context ctx, ErrorListener errs)
        {
        if (isValidated())
            {
            return getType();
            }

        if (errs == null)
            {
            errs = ErrorListener.BLACKHOLE;
            }

        TypeConstant typeTarget;
        if (body == null)
            {
            if (isVirtualNew())
                {
                // immutability is not carried over
                typeTarget = (left == null
                        ? ctx.getThisType()
                        : left.getImplicitType(ctx)).removeImmutable();
                }
            else
                {
                typeTarget  = type.ensureTypeConstant(ctx, errs);
                }
            }
        else
            {
            if (anon == null)
                {
                ensureInnerClass(ctx, AnonPurpose.RoughDraft, errs);
                typeTarget = type.ensureTypeConstant(ctx, errs);
                }
            else
                {
                // there must be an anonymous inner class skeleton by this point
                assert anon != null && anon.getComponent() != null;
                return ((ClassStructure) anon.getComponent()).getFormalType();
                }
            }

        if (typeTarget != null && typeTarget.containsUnresolved())
            {
            log(errs, Severity.ERROR, Compiler.NAME_UNRESOLVABLE, type.toString());
            return null;
            }

        return typeTarget;
        }

    @Override
    public TypeFit testFit(Context ctx, TypeConstant typeRequired, boolean fExhaustive, ErrorListener errs)
        {
        return calcFit(ctx, calculateTargetType(ctx, errs), typeRequired);
        }

    @Override
    protected TypeFit calcFit(Context ctx, TypeConstant typeIn, TypeConstant typeOut)
        {
        if (typeIn != null && typeOut != null)
            {
            // right-to-left inference to match the "validate" logic
            TypeConstant typeInferred = inferTypeFromRequired(typeIn, typeOut);
            if (typeInferred != null)
                {
                typeIn = typeInferred;
                }
            }
        return super.calcFit(ctx, typeIn, typeOut);
        }

    @Override
    protected Expression validate(Context ctx, TypeConstant typeRequired, ErrorListener errs)
        {
        ConstantPool pool       = pool();
        TypeConstant typeSuper  = null;   // the super class type of the anon inner class
        TypeConstant typeTarget = null;   // the type to look for a constructor at (could be private)
        TypeConstant typeResult = null;   // the type being returned (always public)

        // being able to obtain a type for a "new anon inner class" expression requires the
        // inner class to exist (so we create a temporary one)
        boolean fAnonymous = body != null;
        boolean fVirtual   = isVirtualNew();
        Plan    plan;
        if (fAnonymous)
            {
            ErrorListener errsTemp = errs.branch(this);

            ensureInnerClass(ctx, AnonPurpose.RoughDraft, errsTemp);

            if (errsTemp.hasSeriousErrors())
                {
                errsTemp.merge();
                return null;
                }
            // don't merge any warnings since we will call "ensureInnerClass" again
            }

        if (left == null)
            {
            typeTarget = ctx.getThisType();
            if (fVirtual)
                {
                // immutability is not carried over
                typeResult = typeTarget.removeImmutable();
                plan       = Plan.Virtual;
                }
            else
                {
                typeResult = type.ensureTypeConstant(ctx, errs);
                if (typeResult.containsUnresolved())
                    {
                    typeResult = checkDynamicAnnotation(typeResult);
                    if (typeResult == null)
                        {
                        log(errs, Severity.ERROR, Compiler.NAME_UNRESOLVABLE, type.toString());
                        return null;
                        }
                    plan = Plan.Regular;
                    }
                else if (typeResult.isFormalType())
                    {
                    if (typeResult.isGenericType())
                        {
                        m_idFormal = (PropertyConstant) typeResult.getDefiningConstant();
                        }
                    else if (typeResult.isTypeParameter())
                        {
                        if (type instanceof NamedTypeExpression exprNamed)
                            {
                            m_regFormal = (Register) ctx.getVar(exprNamed.getName());

                            assert m_regFormal != null;
                            }
                        else
                            {
                            log(errs, Severity.ERROR, Compiler.NEW_ABSTRACT_TYPE,
                                typeResult.getValueString());
                            return null;
                            }
                        }
                    else if (typeResult.isDynamicType())
                        {
                        m_regFormal = ((DynamicFormalConstant) typeResult.
                                getDefiningConstant()).getRegister();
                        }
                    else
                        {
                        log(errs, Severity.ERROR, Compiler.NEW_ABSTRACT_TYPE,
                            typeResult.getValueString());
                        return null;
                        }
                    plan = Plan.Formal;
                    }
                else
                    {
                    plan = Plan.Regular;
                    }
                }
            }
        else
            {
            // it must not be possible for this to parse: "left.new T() {...}"
            assert body == null;

            // validate the expression that occurs _before_ the new, e.g. x in "x.new Y()", which
            // specifies an "outer this" that provides support for virtual construction
            Expression exprLeftOld = this.left;
            Expression exprLeftNew = exprLeftOld.validate(ctx, null, errs);
            if (exprLeftNew == null)
                {
                return null;
                }

            this.left = exprLeftNew;

            TypeConstant typeLeft = exprLeftNew.getType();

            if (fVirtual)
                {
                // left.new(...)
                if (typeLeft.isFormalTypeType())
                    {
                    log(errs, Severity.ERROR, Compiler.NEW_INVALID_FORMAL, left.toString());
                    return null;
                    }
                // immutability is not carried over
                typeResult = typeTarget = typeLeft.removeImmutable();
                plan       = Plan.Virtual;
                }
            else
                {
                // first, assume the name is relative to the parent's class, e.g.:
                //      parent.new [@Mixin] Child<...>(...)
                TypeExpression exprType = type;
                while (exprType instanceof AnnotatedTypeExpression)
                    {
                    exprType = exprType.unwrapIntroductoryType();
                    }

                NamedTypeExpression exprNameType = (NamedTypeExpression) exprType;
                if (exprNameType.isVirtualChild())
                    {
                    String   sChild   = exprNameType.getName();
                    TypeInfo infoLeft = typeLeft.ensureTypeInfo(errs);

                    typeResult = infoLeft.calculateChildType(pool, sChild);
                    if (typeResult != null)
                        {
                        exprNameType.setTypeConstant(typeResult);
                        }
                    plan = Plan.Child;
                    }
                else
                    {
                    plan = Plan.Regular;
                    }

                if (typeResult == null)
                    {
                    // now try to use the NameTypeExpression validation logic for a fully qualified
                    // type scenario, such as:
                    //      parent.new [@Mixin] Parent.Child<...>(...)
                    TypeExpression exprTest = (TypeExpression) type.clone();
                    Context        ctxTest  = ctx.enter();
                    boolean        fValid   = true;
                    if (exprTest.validate(ctxTest, pool.typeType(), errs) == null)
                        {
                        fValid = false;
                        }
                    else
                        {
                        typeResult = exprTest.ensureTypeConstant(ctx, errs);
                        if (typeResult.containsUnresolved())
                            {
                            typeResult = checkDynamicAnnotation(typeResult);
                            if (typeResult == null)
                                {
                                log(errs, Severity.ERROR, Compiler.NAME_UNRESOLVABLE,
                                        exprTest.toString());
                                fValid = false;
                                }
                            }
                        }
                    ctx.exit();
                    exprTest.discard(true);

                    if (!fValid)
                        {
                        return null;
                        }
                    }

                if (typeResult != null)
                    {
                    if (!typeResult.isVirtualChild() ||
                        !typeResult.getParentType().getDefiningConstant().equals(
                            typeLeft.getDefiningConstant()))
                        {
                        log(errs, Severity.ERROR, Compiler.NEW_UNRELATED_PARENT,
                                typeResult.getValueString(), typeLeft.getValueString());
                        return null;
                        }
                    }
                }
            }

        if (!fVirtual)
            {
            if (typeRequired != null)
                {
                // infer type information from the required type; that information needs to be used to
                // inform the validation of the type that we are "new-ing"
                TypeConstant typeInferred = inferTypeFromRequired(typeResult, typeRequired);
                if (typeInferred != null)
                    {
                    if (typeInferred.containsFormalType(true))
                        {
                        typeInferred = ctx.resolveFormalType(typeInferred);
                        }

                    type.setTypeConstant(typeResult = typeInferred);

                    // the inferred type can contain formal types that need to be registered with
                    // the context (used to compute lambda captures)
                    if (typeInferred.containsFormalType(true))
                        {
                        ctx.useFormalType(typeInferred, errs);
                        }
                    }
                }

            // we intentionally do NOT pass the required type to the TypeExpression; instead, we use
            // the inferred target type
            TypeExpression exprTypeOld = this.type;
            TypeExpression exprTypeNew = (TypeExpression) exprTypeOld.validate(ctx,
                    typeResult == null ? null : typeResult.getType(), errs);
            if (exprTypeNew == null)
                {
                return null;
                }

            this.type  = exprTypeNew;
            typeResult = exprTypeNew.ensureTypeConstant(ctx, errs);

            if (m_fDynamicAnno)
                {
                typeResult = ((AnnotatedTypeConstant) typeResult).stripParameters();
                }

            // strip the annotations and, if necessary, apply them later
            Annotation[] annos;
            if (typeResult instanceof AnnotatedTypeConstant typeAnno)
                {
                List<Annotation> listClass = new ArrayList<>();
                List<Annotation> listMixin = new ArrayList<>();

                typeTarget = typeAnno.extractAnnotation(listClass, listMixin, errs);
                if (typeTarget == null)
                    {
                    // errors must have been reported
                    return null;
                    }
                assert listClass.isEmpty() && !listMixin.isEmpty();
                annos = listMixin.toArray(Annotation.NO_ANNOTATIONS);
                }
            else
                {
                assert !typeResult.isAnnotated();
                typeTarget = typeResult;
                annos      = null;
                }

            if (left == null)
                {
                boolean fNestMate = typeTarget.isNestMateOf(ctx.getThisClassId());

                // now we should have enough type information to create the real anon inner class
                if (fAnonymous)
                    {
                    ErrorListener errsTemp = errs.branch(this);

                    ensureInnerClass(ctx, AnonPurpose.Actual, errsTemp);

                    errsTemp.merge();
                    if (errsTemp.hasSeriousErrors())
                        {
                        return null;
                        }

                    // since we are going to be extending the specified type, increase visibility from
                    // the public default to protected, which we get when a class "extends" another;
                    // the real target, though, is not the specified type being "new'd", but rather the
                    // anonymous inner class
                    typeSuper = pool.ensureAccessTypeConstant(typeTarget,
                            fNestMate ? Access.PRIVATE : Access.PROTECTED);

                    ClassStructure clzAnon = (ClassStructure) anon.getComponent();
                    ClassConstant  idAnon  = (ClassConstant) clzAnon.getIdentityConstant();

                    if (ctx.isFunction())
                        {
                        typeResult = pool.ensureAnonymousClassTypeConstant(pool.typeObject(), idAnon);
                        }
                    else
                        {
                        typeResult = pool.ensureAnonymousClassTypeConstant(ctx.getThisType(), idAnon);
                        typeResult = typeResult.adoptParameters(pool, clzAnon.getFormalType());
                        typeResult = typeResult.resolveGenerics(pool, typeTarget);

                        if (!clzAnon.isStatic())
                            {
                            plan = Plan.Child;
                            }
                        }

                    typeTarget = pool.ensureAccessTypeConstant(typeResult, Access.PRIVATE);

                    if (annos != null)
                        {
                        typeResult = pool.ensureAnnotatedTypeConstant(typeResult, annos);
                        }
                    }
                else if (type instanceof ArrayTypeExpression exprArray)
                    {
                    // this is a "new X[]", "new X[c1]", new X[c1](supply),
                    // or "new X[c1, ...]" construct
                    int cDims = exprArray.getDimensions();
                    switch (cDims)
                        {
                        case 0:
                            // dynamically growing array; go the normal route
                            break;

                        case 1:
                            // fixed size array; we'll continue with the standard validation relying
                            // on the fact that Array has two constructors:
                            //      construct(Int capacity)
                            //      construct(Int size, Element | function Element (Int) supply)
                            // since we know that the ArrayTypeExpression has successfully validated,
                            // we will emit the second constructor in leu of the first one
                            // using the default value for the element type as the second argument
                            int cArgs = args.size();
                            if (cArgs == 1)
                                {
                                // array[capacity] is a fixed size array and is allowed only for
                                // types with default values
                                TypeConstant typeElement = typeTarget.getParamType(0);
                                if (typeElement.getDefaultValue() == null)
                                    {
                                    log(errs, Severity.ERROR, Compiler.NO_DEFAULT_VALUE,
                                        typeElement.getValueString());
                                    return null;
                                    }
                                }
                            m_fFixedSizeArray = true;
                            break;

                        default:
                            log(errs, Severity.ERROR, Compiler.NOT_IMPLEMENTED, "Multi-dimensional array");
                            return null;
                        }
                    }
                else if (fNestMate && typeTarget.isVirtualChild() || typeTarget.isInnerChildClass())
                    {
                    ClassStructure clzTarget = (ClassStructure)
                            typeTarget.getSingleUnderlyingClass(false).getComponent();

                    plan = Plan.Child;

                    int nSteps = ctx.getStepsToOuterClass(clzTarget.getOuter());
                    if (nSteps >= 0)
                        {
                        if (nSteps == 0 && ctx.isConstructor())
                            {
                            log(errs, Severity.ERROR, Compiler.PARENT_NOT_CONSTRUCTED,
                                    clzTarget.getSimpleName());
                            return null;
                            }
                        ctx.requireThis(getStartPosition(), errs);
                        m_nParentSteps = nSteps;
                        }
                    else
                        {
                        // TODO: a better error
                        log(errs, Severity.ERROR, Compiler.INVALID_OUTER_THIS);
                        return null;
                        }
                    }
                }
            }

        ErrorListener errsTemp = errs.branch(this);
        TypeInfo infoTarget = fAnonymous
                ? typeTarget.ensureTypeInfo(errsTemp)
                : getTypeInfo(ctx, typeTarget, errsTemp);

        if (errsTemp.hasSeriousErrors())
            {
            // no reason to proceed
            errsTemp.merge();
            return null;
            }

        // for a regular or virtual child construction, the target type must be new-able
        if ((plan == Plan.Regular || plan == Plan.Child) &&
                !infoTarget.isNewable(false, errsTemp))
            {
            String sTarget = infoTarget.getType().removeAccess().getValueString();
            infoTarget.reportNotNewable(sTarget, null, false, errsTemp);
            errsTemp.merge();
            return null;
            }

        List<Expression> listArgs = args;

        MethodConstant idConstruct = findMethod(ctx, typeTarget, infoTarget, "construct", listArgs,
                        MethodKind.Constructor, true, false, null, errsTemp);
        if (fAnonymous)
            {
            // first, see if the constructor that we're looking for is on the anonymous
            // inner class (which -- other than the zero-args case -- will be rare, but it
            // is still supported); however, since it's not an error for the constructor to
            // be missing, trap the errors in a temporary list. if we do find the constructor
            // that we need on the anonymous inner class, then we will simply use that one (and
            // any required dependency that it has one a super class constructor will be handled
            // as if this were any other normal class)
            if (idConstruct == null && !listArgs.isEmpty())
                {
                // the constructor that we're looking for is not on the anonymous inner class,
                // so we need to find the specified constructor on the super class (which means
                // that the super class must NOT be an interface), and we need to verify that
                // there is a default constructor on the anon inner class, and it needs to be
                // replaced by a constructor with the same signature as the super's constructor
                // (note: the automatic creation of the synthetic no-arg constructor in the
                // absence of any explicit constructor must do this same check)
                TypeInfo       infoSuper = typeSuper.ensureTypeInfo(errs);
                MethodConstant idSuper   = findMethod(ctx, typeSuper, infoSuper, "construct",
                            listArgs, MethodKind.Constructor, true, false, null, errs);
                if (idSuper == null)
                    {
                    return null;
                    }
                // we found a super constructor that needs to get called from the
                // constructor on the inner class; find the no-parameter synthetic
                // "construct()" constructor on the inner class and remove it, replacing it
                // with a constructor that matches the super class constructor, so that we
                // correctly invoke it
                destroyDefaultConstructor();

                MethodStructure methodSuper =
                        infoSuper.getMethodById(idSuper).getHead().getMethodStructure();
                idConstruct = createPassThroughConstructor(idSuper, methodSuper);

                // since we just modified the component, flush the TypeInfo cache for
                // the type of the anonymous inner class
                typeTarget.invalidateTypeInfo();
                }
            else
                {
                // we did find a constructor; there were probably no errors, but just in case
                // something got logged, transfer it to the real error list
                errsTemp.merge();
                }
            }
        else
            {
            if (idConstruct == null)
                {
                // as the last resort, validate the arguments before looking for the method again
                // (regardless of the outcome, the validation errors should be reported)
                TypeConstant[] atypeArgs = validateExpressions(ctx, listArgs, null, errs);
                if (atypeArgs == null)
                    {
                    errsTemp.merge();
                    }
                else
                    {
                    idConstruct = findMethod(ctx, typeTarget, infoTarget, "construct", listArgs,
                                    MethodKind.Constructor, true, false, null, errs);
                    }
                }
            }

        if (idConstruct == null)
            {
            return null;
            }

        MethodStructure constructor = (MethodStructure) idConstruct.getComponent();
        if (constructor == null)
            {
            constructor = infoTarget.getMethodById(idConstruct).
                            getTopmostMethodStructure(infoTarget);
            assert constructor != null;
            }
        m_constructor = constructor;

        if (containsNamedArgs(listArgs))
            {
            listArgs = rearrangeNamedArgs(constructor, listArgs, errs);
            if (listArgs == null)
                {
                return null;
                }
            args = listArgs;
            }

        if (validateExpressions(ctx, listArgs, idConstruct.getRawParams(), errs) == null)
            {
            return null;
            }

        if (!typeResult.isParamsSpecified())
            {
            ClassStructure clz = (ClassStructure) constructor.getParent().getParent();
            if (clz.isParameterized())
                {
                // the class is parameterized, but the resulting type is not, which means
                // that the left is the canonical type; let's attempt to narrow it using
                // the constructor's argument types
                TypeConstant typeInferred = inferTypeFromConstructor(ctx, clz, constructor, listArgs);
                if (typeInferred != null)
                    {
                    typeResult = typeInferred;
                    }
                }
            }

        if (fAnonymous)
            {
            // at this point, we need to create a temporary copy of the anonymous inner class for
            // the purpose of determining which local variables from this context will be "captured"
            // by the code in the anonymous inner class; to determine the captures, we need to go
            // much further in the compilation of the inner class, to the point of the emit stage
            // in which the expression validations are done (which means that the inner class will
            // end up emitting code); fortunately, all of that work can be done with temporary
            // structures, such that we can revert it after we collect the information about the
            // captures; force a temp clone of the inner class to go through its validate() stage so
            // that we can determine what variables get captured (and if they are effectively final)
            ensureInnerClass(ctx, AnonPurpose.CaptureAnalysis, ErrorListener.BLACKHOLE);

            // the capture information gets collected in a specialized Context that was created with
            // the inner class
            AnonInnerClassContext ctxAnon = m_ctxCapture;
            boolean               fValid  = new StageMgr(anon, Stage.Emitted, errs).fastForward(20);

            ctxAnon.exit();

            // clean up temporary inner class
            destroyTempInnerClass();

            if (!fValid)
                {
                return null;
                }

            // at this point we have a fair bit of data about which variables get captured, but we
            // still lack the effectively final data that will only get reported when the various
            // nested contexts in which the captured variables were declared go through their exit()
            // logic (as the variables go out of scope in the method body that contains this
            // NewExpression); for now, store off the data from the capture context
            m_mapCapture     = ctxAnon.getCaptureMap();
            m_mapRegisters   = ctxAnon.ensureRegisterMap();
            m_fInstanceChild = ctxAnon.isInstanceChild();
            m_ctxCapture     = null;

            // make sure the capture names don't collide
            ClassStructure clzAnon = ctxAnon.getThisClass();
            for (String sName : m_mapCapture.keySet())
                {
                if (clzAnon.getChild(sName) != null)
                    {
                    log(errs, Severity.ERROR, Compiler.NAME_COLLISION, sName);
                    return null;
                    }
                }
            }

        m_plan = plan;

        Expression exprResult = finishValidation(ctx, typeRequired, typeResult, TypeFit.Fit, null, errs);
        clearAnonTypeInfos();
        return exprResult;
        }

    @Override
    public boolean isStandalone()
        {
        return true;
        }

    @Override
    public boolean isCompletable()
        {
        for (Expression expr : args)
            {
            if (!expr.isCompletable())
                {
                return false;
                }
            }

        return true;
        }

    @Override
    public boolean isShortCircuiting()
        {
        for (Expression expr : args)
            {
            if (expr.isShortCircuiting())
                {
                return true;
                }
            }

        return false;
        }

    @Override
    public void generateAssignment(Context ctx, Code code, Assignable LVal, ErrorListener errs)
        {
        // 1. To avoid an out-of-order execution, we cannot allow the use of local properties
        //    except for the parent when there are no arguments
        // 2. The arguments are allowed to be pushed on the stack since the run-time knows to load
        //    them up in the inverse order; however, the parent (for the NEWC_* ops should not be
        //    put on the stack unless there are no arguments

        if (LVal.isLocalArgument())
            {
            List<Expression>    listArgs = args;
            int                 cArgs    = listArgs.size();
            Argument[]          aArgs    = new Argument[cArgs];
            ExprAST<Constant>[] aAstArgs = new ExprAST[cArgs];
            for (int i = 0; i < cArgs; ++i)
                {
                Expression expr = listArgs.get(i);
                Argument   arg  = expr.generateArgument(ctx, code, false, true, errs);
                aArgs[i] = i == cArgs-1
                        ? arg
                        : ensurePointInTime(code, arg);
                aAstArgs[i] = expr.getExprAST();
                }

            if (anon != null)
                {
                aArgs = addCaptures(code, aArgs);
                }

            generateNew(ctx, code, aArgs, LVal.getLocalArgument(), aAstArgs, errs);
            }
        else
            {
            super.generateAssignment(ctx, code, LVal, errs);
            }
        }

    @Override
    public ExprAST<Constant> getExprAST()
        {
        return m_astNew == null
                ? super.getExprAST()
                : m_astNew;
        }


    // ----- compilation helpers -------------------------------------------------------------------

    /**
     * Check if the specified unresolved type is unresolved only due to some unresolved annotation
     * parameters.
     *
     * @return the resolved annotation type stripped of the unresolved parameters; null otherwise
     */
    private TypeConstant checkDynamicAnnotation(TypeConstant typeUnresolved)
        {
        if (typeUnresolved instanceof AnnotatedTypeConstant typeAnno)
            {
            TypeConstant typeResolved = typeAnno.stripParameters();
            if (!typeResolved.containsUnresolved())
                {
                m_fDynamicAnno = true;
                return typeResolved;
                }
            }
        return null;
        }

    /**
     * Generate the NEW_* op-code
     */
    private void generateNew(Context ctx, Code code, Argument[] aArgs, Argument argResult,
                             ExprAST<Constant>[] aAstArgs, ErrorListener errs)
        {
        assert m_constructor.getTypeParamCount() == 0;

        TypeConstant typeTarget;
        if (m_fDynamicAnno)
            {
            // the annotated type cannot have any ref annotations, but can have multiple type
            // annotations (e.g. @A1(arg1) @A2(arg2) C(arg)
            AnnotatedTypeConstant typeAnno = (AnnotatedTypeConstant) type.ensureTypeConstant(ctx, errs);

            typeTarget = generateDynamicParameters(ctx, code, typeAnno, errs);
            }
        else
            {
            typeTarget = getType();
            }

        MethodConstant idConstruct = m_constructor.getIdentityConstant();
        int            cParams     = m_constructor.getParamCount();
        int            cArgs       = aArgs.length;
        int            cDefaults   = cParams - cArgs;

        if (m_fTupleArg)
            {
            // TODO
            throw notImplemented();
            }
        else
            {
            if (cDefaults > 0)
                {
                Argument[] aArgAll = new Argument[cParams];
                System.arraycopy(aArgs, 0, aArgAll, 0, cArgs);
                aArgs = aArgAll;

                for (int i = 0; i < cDefaults; i++)
                    {
                    aArgs[cArgs + i] = Register.DEFAULT;
                    }
                }

            Argument          argOuter = null;
            ExprAST<Constant> astOuter = null;
            if (m_plan == Plan.Child)
                {
                if (left == null)
                    {
                    if (m_nParentSteps == 0)
                        {
                        argOuter = ctx.getThisRegister();
                        astOuter = ctx.getThisRegisterAST();
                        }
                    else
                        {
                        TypeConstant typeParent = typeTarget.getParentType();
                        int          cSteps     = m_nParentSteps;

                        argOuter = new Register(typeParent, null, Op.A_STACK);
                        code.add(new MoveThis(cSteps, argOuter));
                        astOuter = new OuterExprAST<>(ctx.getThisRegisterAST(), cSteps, typeParent);
                        }
                    }
                else
                    {
                    argOuter = left.generateArgument(ctx, code, true, true, errs);
                    astOuter = left.getExprAST();
                    }
                }

            if (m_plan == Plan.Virtual || m_plan == Plan.Formal)
                {
                Register regType;
                if (m_plan == Plan.Virtual)
                    {
                    Register regThis = new Register(ctx.getThisType(), null, Op.A_TARGET);

                    regType = new Register(pool().typeType(), null, Op.A_STACK);
                    code.add(new MoveType(regThis, regType));
                    }
                else
                    {
                    if (typeTarget.isGenericType())
                        {
                        regType = new Register(pool().typeType(), null, Op.A_STACK);
                        code.add(new L_Get(m_idFormal, regType));
                        }
                    else
                        {
                        regType = m_regFormal;
                        }
                    }
                switch (cParams)
                    {
                    case 0:
                        code.add(new NewV_0(idConstruct, regType, argResult));
                        break;

                    case 1:
                        code.add(new NewV_1(idConstruct, regType, aArgs[0], argResult));
                        break;

                    default:
                        code.add(new NewV_N(idConstruct, regType, aArgs, argResult));
                        break;
                    }
                m_astNew = new NewExprAST<>(typeTarget, idConstruct, aAstArgs, true);
                }
            else if (isTypeRequired(typeTarget))
                {
                if (argOuter == null)
                    {
                    switch (cParams)
                        {
                        case 0:
                            code.add(new NewG_0(idConstruct, typeTarget, argResult));
                            break;

                        case 1:
                            if (m_fFixedSizeArray)
                                {
                                Argument[] aArg2 = new Argument[2];
                                aArg2[0] = aArgs[0];
                                aArg2[1] = Register.DEFAULT;
                                idConstruct = ((ArrayTypeExpression) type).getSupplyConstructor();
                                code.add(new NewG_N(idConstruct, typeTarget, aArg2, argResult));
                                }
                            else
                                {
                                code.add(new NewG_1(idConstruct, typeTarget, aArgs[0], argResult));
                                }
                            break;

                        default:
                            code.add(new NewG_N(idConstruct, typeTarget, aArgs, argResult));
                            break;
                        }
                    m_astNew = new NewExprAST<>(typeTarget, idConstruct, aAstArgs, false);
                    }
                else
                    {
                    switch (cParams)
                        {
                        case 0:
                            code.add(new NewCG_0(idConstruct, argOuter, typeTarget, argResult));
                            break;

                        case 1:
                            code.add(new NewCG_1(idConstruct, argOuter, typeTarget, aArgs[0], argResult));
                            break;

                        default:
                            code.add(new NewCG_N(idConstruct, argOuter, typeTarget, aArgs, argResult));
                            break;
                        }
                    m_astNew = new NewExprAST<>(astOuter, typeTarget, idConstruct, aAstArgs);
                    }
                }
            else
                {
                if (argOuter == null)
                    {
                    switch (cParams)
                        {
                        case 0:
                            code.add(new New_0(idConstruct, argResult));
                            break;

                        case 1:
                            code.add(new New_1(idConstruct, aArgs[0], argResult));
                            break;

                        default:
                            code.add(new New_N(idConstruct, aArgs, argResult));
                            break;
                        }
                    m_astNew = new NewExprAST<>(typeTarget, idConstruct, aAstArgs, false);
                    }
                else
                    {
                    switch (cParams)
                        {
                        case 0:
                            code.add(new NewC_0(idConstruct, argOuter, argResult));
                            break;

                        case 1:
                            code.add(new NewC_1(idConstruct, argOuter, aArgs[0], argResult));
                            break;

                        default:
                            code.add(new NewC_N(idConstruct, argOuter, aArgs, argResult));
                            break;
                        }
                    m_astNew = new NewExprAST<>(astOuter, typeTarget, idConstruct, aAstArgs);
                    }
                }
            }
        }

    /**
     * Generate registers for any dynamic (non-constant) parameter of the underlying annotated type
     * and produce the resolved type constant to be used by the NEW_ op.
     */
    private TypeConstant generateDynamicParameters(Context ctx, Code code,
                                                   AnnotatedTypeConstant typeAnno, ErrorListener errs)
        {
        ConstantPool pool = pool();

        TypeConstant typeUnderlying = typeAnno.getUnderlyingType();
        if (typeUnderlying instanceof AnnotatedTypeConstant typeUnder)
            {
            typeUnderlying = generateDynamicParameters(ctx, code, typeUnder, errs);
            }

        Constant[] aConst = typeAnno.getAnnotationParams();
        boolean    fDiff  = false;
        for (int j = 0, c = aConst.length; j < c; j++)
            {
            Constant constArg = aConst[j];
            if (constArg instanceof ExpressionConstant constExpr)
                {
                Expression exprArg = constExpr.getExpression();

                Argument argArg = exprArg.generateArgument(ctx, code, true, false, errs);
                Register regArg;
                if (argArg instanceof Register regA)
                    {
                    regArg = regA;
                    }
                else
                    {
                    regArg = code.createRegister(exprArg.getType());
                    code.add(new Var(regArg));
                    code.add(new Move(argArg, regArg));
                    }
                aConst[j] = new RegisterConstant(pool, regArg);
                fDiff     = true;
                }
            }
        return fDiff
                ? pool.ensureAnnotatedTypeConstant(typeAnno.getAnnotationClass(), aConst, typeUnderlying)
                : typeAnno;
        }

    /**
     * Create the necessary AST and Component nodes for the anonymous inner class.
     *
     * @param ctx      the current compilation context
     * @param purpose  explains what the inner class that we're creating here will be used for
     * @param errs     the error listener to log any errors to
     */
    private void ensureInnerClass(Context ctx, AnonPurpose purpose, ErrorListener errs)
        {
        assert body != null;

        // check if we're already done
        if (m_purposeCurrent == purpose)
            {
            return;
            }

        // check if there is already a temp copy of the anonymous inner class floating around, and
        // if so, get rid of it
        destroyTempInnerClass();

        if (m_purposeCurrent == purpose)
            {
            // we've already accomplished the purpose at this point (either "None" or "Actual")
            return;
            }

        // backup the actual inner class, if it exists
        if (m_purposeCurrent == AnonPurpose.Actual)
            {
            assert anon != null;
            assert anon.getComponent() != null;

            m_anonActualBackup = anon;
            m_clzActualBackup  = (ClassStructure) anon.getComponent();
            }

        // select a unique (and purposefully syntactically illegal) name for the anonymous inner
        // class
        AnonInnerClass info     = type.inferAnonInnerClass(errs);
        Component      parent   = getComponent();
        String         sDefault = info.getDefaultName();
        int            nSuffix  = 1;
        String         sName;
        while (parent.getChild(sName = sDefault + ":" + nSuffix) != null)
            {
            ++nSuffix;
            }
        Token tokName = new Token(type.getStartPosition(), type.getEndPosition(), Id.IDENTIFIER, sName);

        switch (purpose)
            {
            case RoughDraft:
                // until we create the actual inner class composition, we need to avoid destroying
                // the virgin AST nodes
                assert m_purposeCurrent == AnonPurpose.None;
                anon = adopt(new TypeCompositionStatement(
                        this,
                        clone(info.getAnnotations()),
                        info.getCategory(),
                        tokName,
                        clone(info.getTypeParameters()),
                        clone(info.getCompositions()),
                        clone(args),
                        (StatementBlock) body.clone(),
                        type.getStartPosition(),
                        body.getEndPosition()));
                break;

            case Actual:
                // at this point, we are creating the inner class composition that will ultimately
                // generate the final code
                anon = adopt(new TypeCompositionStatement(
                        this,
                        info.getAnnotations(),
                        info.getCategory(),
                        tokName,
                        info.getTypeParameters(),
                        info.getCompositions(),
                        args,
                        body,
                        type.getStartPosition(),
                        body.getEndPosition()));
                break;

            case CaptureAnalysis:
                // the current inner class composition statement MUST be the "actual" one
                assert m_purposeCurrent == AnonPurpose.Actual;
                anon = (TypeCompositionStatement) adopt(anon.clone());
                anon.setComponent(m_clzActualBackup.replaceWithTemporary());
                break;
            }

        m_ctxCapture = new AnonInnerClassContext(ctx);

        catchUpChildren(errs);

        if (purpose != AnonPurpose.CaptureAnalysis)
            {
            // the context is ONLY retained to provide capture information
            m_ctxCapture = null;
            }

        m_purposeCurrent = purpose;
        }

    /**
     * If the inner class was created on a temporary basis, then clean up the temporary data and
     * objects. If there was an actual inner class before the temporary was created, then restore
     * that actual inner class.
     */
    private void destroyTempInnerClass()
        {
        if (anon != null && m_purposeCurrent != AnonPurpose.Actual)
            {
            // discard any temporary inner class structure
            ClassStructure clzTemp = (ClassStructure) anon.getComponent();
            if (clzTemp != null)
                {
                Component componentParent = clzTemp.getParent();
                assert componentParent == getComponent();       // the parent should be this method

                ClassStructure clzActual = m_clzActualBackup;
                if (clzActual == null)
                    {
                    componentParent.removeChild(clzTemp);
                    }
                else
                    {
                    clzTemp.replaceTemporaryWith(clzActual);
                    }
                }

            // discard the temporary AST
            anon.discard(true);
            anon             = null;
            m_purposeCurrent = AnonPurpose.None;

            // restore the real AST, if the actual one exists
            if (m_anonActualBackup != null)
                {
                anon               = m_anonActualBackup;
                m_anonActualBackup = null;
                m_clzActualBackup  = null;
                m_purposeCurrent   = AnonPurpose.Actual;
                }
            }
        }

    /**
     * Remove synthetic default constructor on the anonymous inner class.
     */
    private void destroyDefaultConstructor()
        {
        ClassStructure clz = (ClassStructure) anon.getComponent();
        MethodConstant id  = pool().ensureMethodConstant(clz.getIdentityConstant(), "construct",
                TypeConstant.NO_TYPES, TypeConstant.NO_TYPES);
        MethodStructure constrDefault = (MethodStructure) id.getComponent();
        if (constrDefault != null)
            {
            clz.getChild("construct").removeChild(constrDefault);
            }
        }

    /**
     * Helper to clone a list of AST nodes.
     *
     * @param list  the list of AST nodes (may be null)
     *
     * @return a deeply cloned list
     */
    private <T extends AstNode> List<T> clone(List<? extends AstNode> list)
        {
        if (list == null || list.isEmpty())
            {
            return (List<T>) list;
            }

        List listCopy = new ArrayList<>(list.size());
        for (AstNode node : list)
            {
            listCopy.add(node.clone());
            }
        return listCopy;
        }

    /**
     * Create a synthetic constructor on the inner class that calls the specified super constructor.
     *
     * @param idSuper      the super constructor id
     * @param methodSuper  the super constructor method
     *
     * @return the identity of the new constructor on the anonymous inner class
     */
    private MethodConstant createPassThroughConstructor(MethodConstant idSuper,
                                                        MethodStructure methodSuper)
        {
        // create a constructor that matches the one that we need to route to on the super class
        Parameter[]     aParams     = methodSuper.getParamArray();
        int             cParams     = aParams.length;
        ClassStructure  clzAnon     = (ClassStructure) anon.getComponent();
        MethodStructure constrThis  = clzAnon.createMethod(true, Access.PUBLIC, null,
                Parameter.NO_PARAMS, "construct", aParams, true, false);
        constrThis.setSynthetic(true);

        Code code = constrThis.createCode();

        // call the default initializer
        assert constrThis.isAnonymousClassWrapperConstructor();
        if (!methodSuper.isAnonymousClassWrapperConstructor())
            {
            code.add(new SynInit());
            }

        if (cParams == 1)
            {
            code.add(new Construct_1(idSuper, new Register(aParams[0].getType(), null, 0)));
            }
        else
            {
            assert cParams > 1;
            Register[] aArgs = new Register[cParams];
            for (int i = 0; i < cParams; ++i)
                {
                aArgs[i] = new Register(aParams[i].getType(), null, i);
                }
            code.add(new Construct_N(idSuper, aArgs));
            }
        code.add(new Return_0());

        return constrThis.getIdentityConstant();
        }

    /**
     * Apply information that was collected by analyzing the capture behavior of the anonymous inner
     * class.
     *
     * @param code  the code being emitted for the site of the NewExpression
     */
    private Argument[] addCaptures(Code code, Argument[] aOldArgs)
        {
        // we're going to be making changes, so get rid of any cached TypeInfo
        clearAnonTypeInfos();

        // if the anonymous inner class captures the "outer this", then it has to be an instance
        // child
        anon.getComponent().setStatic(!m_fInstanceChild);

        // if nothing else is captured, then we're done
        Map<String, Boolean>  mapCapture   = m_mapCapture;
        Map<String, Register> mapRegisters = m_mapRegisters;
        if (mapCapture == null || mapCapture.isEmpty())
            {
            return aOldArgs;
            }

        // we're going to replace the constructor by creating a new constructor that calls the old
        // one, but that first stores off all the passed-in binding values
        ConstantPool pool       = pool();
        Parameter[]  aOldParams = m_constructor.getParamArray();
        int          cOldParams = aOldParams.length;
        int          cCaptures  = mapCapture.size();
        int          cNewParams = cOldParams + cCaptures;
        Parameter[]  aNewParams = new Parameter[cNewParams];
        int          iNewParam  = cOldParams;
        Argument[]   aNewArgs   = new Argument[cNewParams];
        assert cOldParams == aOldArgs.length;
        System.arraycopy(aOldParams, 0, aNewParams, 0, cOldParams);
        System.arraycopy(aOldArgs  , 0, aNewArgs  , 0, cOldParams);
        for (Entry<String, Boolean> entry : mapCapture.entrySet())
            {
            String       sName = entry.getKey();
            Register     reg   = mapRegisters.get(sName);
            Boolean      FVar  = entry.getValue();
            TypeConstant type  = reg.getType();
            Register     arg   = reg;
            if (FVar)
                {
                // it's a read/write capture; obtain the Var of the capture
                type = pool.ensureParameterizedTypeConstant(pool.typeVar(), type);
                arg  = new Register(type, null, Op.A_STACK);
                code.add(new MoveVar(reg, arg));
                }
            else if (!reg.isEffectivelyFinal())
                {
                // it's a read-only capture, but since we were unable to prove that the
                // register was effectively final, we need to capture the Ref
                type = pool.ensureParameterizedTypeConstant(pool.typeRef(), type);
                arg  = new Register(type, null, Op.A_STACK);
                code.add(new MoveRef(reg, arg));
                }

            // the new constructor will have the value/Ref/Var passed in as an additional parameter
            aNewParams[iNewParam] = new Parameter(pool, type, sName, null, false, iNewParam, false);
            aNewArgs  [iNewParam] = arg;
            ++iNewParam;
            }

        // create a wrapper constructor that takes the additional capture values and then delegates
        // to the original constructor
        ClassStructure  clzAnon   = (ClassStructure) anon.getComponent();
        MethodStructure constrOld = m_constructor;
        MethodStructure constrNew = clzAnon.createMethod(true, Access.PUBLIC, null,
                Parameter.NO_PARAMS, "construct", aNewParams, true, false);
        constrNew.setSynthetic(true);
        Code codeConstr = constrNew.createCode();

        // for each capture variable needed by the anonymous inner class, create a property that
        // will hold it, and store the value (which is being passed into the new constructor) into
        // that property
        for (int iCapture = 0; iCapture < cCaptures; ++iCapture)
            {
            iNewParam = cOldParams + iCapture;
            Parameter    param = aNewParams[iNewParam];
            String       sName = param.getName();
            TypeConstant type  = param.getType();
            Register     reg   = new Register(type, null, iNewParam);

            // create the property as a private synthetic
            PropertyStructure prop = clzAnon.createProperty(
                    false, Access.PRIVATE, Access.PRIVATE, type, sName);   // TODO @Final
            // mark the property as unassigned to prevent default initialization
            prop.addAnnotation(pool.clzUnassigned());
            prop.setSynthetic(true);

            // store the constructor parameter into the property
            codeConstr.add(new L_Set(prop.getIdentityConstant(), reg));
            }

        if (!constrOld.isAnonymousClassWrapperConstructor())
            {
            // call the default initializer
            codeConstr.add(new SynInit());
            }

        // call the previous constructor
        MethodConstant idOld = constrOld.getIdentityConstant();
        switch (cOldParams)
            {
            case 0:
                codeConstr.add(new Construct_0(idOld));
                break;

            case 1:
                codeConstr.add(new Construct_1(idOld, new Register(aNewParams[0].getType(), null, 0)));
                break;

            default:
                Register[] aArgs = new Register[cOldParams];
                for (int i = 0; i < cOldParams; ++i)
                    {
                    aArgs[i] = new Register(aOldParams[i].getType(), null, i);
                    }
                codeConstr.add(new Construct_N(constrOld.getIdentityConstant(), aArgs));
                break;
            }
        codeConstr.add(new Return_0());

        // the new constructor calls the old constructor, so we need to call the new constructor
        m_constructor = constrNew;

        return aNewArgs;
        }

    private void clearAnonTypeInfos()
        {
        if (anon != null)
            {
            getType().invalidateTypeInfo();
            }
        }

    /**
     * @return true iff the name specifies a captured variable
     */
    protected boolean isCapture(String sCaptureName)
        {
        return m_mapCapture != null && m_mapCapture.containsKey(sCaptureName);
        }

    /**
     * @return the type of the value (not the Ref or Var, if implicit deref is used)
     */
    protected TypeConstant getCaptureType(String sCaptureName)
        {
        assert m_mapRegisters.containsKey(sCaptureName);

        return m_mapRegisters.get(sCaptureName).getType();
        }

    /**
     * @return true iff the captured variable has been marked as being effectively final
     */
    protected boolean isCaptureFinal(String sCaptureName)
        {
        assert m_mapRegisters.containsKey(sCaptureName);

        return m_mapRegisters.get(sCaptureName).isEffectivelyFinal();
        }

    /**
     * @return true iff a capture variable needs to be implicitly de-ref'd (via a CVAR)
     */
    protected boolean isImplicitDeref(String sCaptureName)
        {
        assert m_mapCapture.containsKey(sCaptureName);

        Register reg    = m_mapRegisters.get(sCaptureName);
        Boolean  FVar   = m_mapCapture  .get(sCaptureName);
        return FVar || !reg.isEffectivelyFinal();
        }

    /**
     * @return iff constructing the specified type requires the type in addition to the constructor
     */
    private static boolean isTypeRequired(TypeConstant type)
        {
        if (type.isParamsSpecified() || type.isAnnotated())
            {
            return true;
            }
        if (type.isAnonymousClass())
            {
            return isTypeRequired(type.getParentType());
            }
        return false;
        }

    // ----- debugging assistance ------------------------------------------------------------------

    /**
     * @return the signature of the constructor invocation
     */
    public String toSignatureString()
        {
        StringBuilder sb = new StringBuilder();

        if (left != null)
            {
            sb.append(left)
              .append('.');
            }

        sb.append(operator.getId().TEXT);

        if (type != null)
            {
            sb.append(' ')
              .append(type);
            }

        if (args != null)
            {
            int iFirst = 0;

            if (hasSquareBrackets())
                {
                iFirst = getDimensionCount();

                sb.append('[');
                boolean first = true;
                for (int i = 0; i < iFirst; ++i)
                    {
                    Expression arg = args.get(i);
                    if (first)
                        {
                        first = false;
                        }
                    else
                        {
                        sb.append(", ");
                        }
                    sb.append(arg);
                    }
                sb.append(']');
                }

            sb.append('(');
            boolean first = true;
            for (int i = iFirst, c = args.size(); i < c; ++i)
                {
                Expression arg = args.get(i);
                if (first)
                    {
                    first = false;
                    }
                else
                    {
                    sb.append(", ");
                    }
                sb.append(arg);
                }
            sb.append(')');
            }

        return sb.toString();
        }

    @Override
    public String toString()
        {
        StringBuilder sb = new StringBuilder();

        sb.append(toSignatureString());

        if (body != null)
            {
            sb.append('\n')
              .append(indentLines(body.toString(), "        "));
            }

        return sb.toString();
        }

    @Override
    public String getDumpDesc()
        {
        String s = toSignatureString();

        return body == null
                ? s
                : s + "{..}";
        }


    // ----- inner class: CaptureContext -----------------------------------------------------------

    /**
     * A context for compiling new expressions that define an anonymous inner class.
     */
    public class AnonInnerClassContext
            extends CaptureContext
        {
        /**
         * Construct a NewExpression CaptureContext.
         *
         * @param ctxOuter  the context within which this context is nested
         */
        public AnonInnerClassContext(Context ctxOuter)
            {
            super(ctxOuter);
            }

        @Override
        public TypeConstant getThisType()
            {
            TypeConstant typeBase = type.ensureTypeConstant();
            TypeConstant typeThis = getThisClass().getFormalType();
            return typeThis.resolveGenerics(pool(), typeBase);
            }

        @Override
        public ClassStructure getThisClass()
            {
            return (ClassStructure) anon.getComponent();
            }

        @Override
        public void requireThis(long lPos, ErrorListener errs)
            {
            if (getMethod().isStatic())
                {
                errs.log(Severity.ERROR, Compiler.NO_THIS, null, getSource(), lPos, lPos);
                }
            else
                {
                super.requireThis(lPos, errs);
                }
            }

        /**
         * @return true iff the inner class captures the outer "this"
         */
        public boolean isInstanceChild()
            {
            // there is no reason to capture a singleton parent
            return isThisCaptured() ||
                    !getMethod().isStatic() && !getMethod().getContainingClass().isSingleton();
            }
        }


    // ----- fields --------------------------------------------------------------------------------

    private enum AnonPurpose {None, RoughDraft, CaptureAnalysis, Actual}

    protected Expression               left;
    protected Token                    operator;
    protected TypeExpression           type;
    protected List<Expression>         args;
    protected int                      dims;        // -1 == no [dims]
    protected StatementBlock           body;        // NOT a child
    protected TypeCompositionStatement anon;        // synthetic, added as a child
    protected long                     lEndPos;

    private transient MethodStructure m_constructor;
    private transient boolean         m_fTupleArg;  // indicates that arguments come from a tuple
                                                    // (currently not implemented)

    private transient AnonPurpose              m_purposeCurrent = AnonPurpose.None;
    private transient TypeCompositionStatement m_anonActualBackup;
    private transient ClassStructure           m_clzActualBackup;

    /**
     * The capture context, while it is active.
     */
    private transient AnonInnerClassContext m_ctxCapture;
    /**
     * The variables captured by the anonymous inner class, with an associated "true" flag if the
     * inner class needs to capture the variable in a read/write mode.
     */
    private transient Map<String, Boolean>  m_mapCapture;
    /**
     * A map from variable name to register, built by the anonymous inner class context.
     */
    private transient Map<String, Register> m_mapRegisters;

    /**
     * The construction plan:
     *  - Regular - use NEW_* or NEWG_* op-codes
     *  - Child   - virtual child; use NEWC_* or NEWCG_* op-codes
     *  - Virtual - virtual constructor; use MoveType, NEWV_* op-code sequence
     *  - Formal  - formal type constructor; use NEWV_* op-codes
     */
    enum Plan{Regular, Child, Virtual, Formal}
    private transient Plan m_plan;

    /**
     * In the case of "m_plan == Plan.Child" and "left == null", steps to the child's parent.
     */
    private transient int m_nParentSteps;
    /**
     * In the case of "m_plan == Plan.Formal" and the formal type is generic, the formal property id.
     */
    private transient PropertyConstant m_idFormal;
    /**
     * In the case of "m_plan == Plan.Formal" and the formal type is parameter, the corresponding register.
     */
    private transient Register m_regFormal;
    /**
     * True if the class is a fixed size array to be filled with the corresponding default value.
     */
    private transient boolean m_fFixedSizeArray;
    /**
     * True if the inner class captures "this" (i.e. not static).
     */
    private transient boolean m_fInstanceChild;
    /**
     * True if the newable type has non-constant annotation parameters.
     */
    private transient boolean m_fDynamicAnno;
    /**
     * Cached NewExprAST node.
     */
    private transient ExprAST<Constant> m_astNew;

    private static final Field[] CHILD_FIELDS = fieldsForNames(NewExpression.class, "left", "type", "args", "anon");
    }