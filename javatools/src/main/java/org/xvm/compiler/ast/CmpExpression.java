package org.xvm.compiler.ast;


import org.xvm.asm.Argument;
import org.xvm.asm.Constant;
import org.xvm.asm.ConstantPool;
import org.xvm.asm.ErrorListener;
import org.xvm.asm.MethodStructure.Code;
import org.xvm.asm.Op;
import org.xvm.asm.OpCondJump;
import org.xvm.asm.OpTest;

import org.xvm.asm.ast.BiExprAST.Operator;
import org.xvm.asm.ast.CondOpExprAST;
import org.xvm.asm.ast.ExprAST;

import org.xvm.asm.constants.CastTypeConstant;
import org.xvm.asm.constants.TypeConstant;

import org.xvm.asm.op.Cmp;
import org.xvm.asm.op.IsEq;
import org.xvm.asm.op.IsGt;
import org.xvm.asm.op.IsGte;
import org.xvm.asm.op.IsLt;
import org.xvm.asm.op.IsLte;
import org.xvm.asm.op.IsNotEq;
import org.xvm.asm.op.IsNotNull;
import org.xvm.asm.op.IsNull;
import org.xvm.asm.op.JumpEq;
import org.xvm.asm.op.JumpGt;
import org.xvm.asm.op.JumpGte;
import org.xvm.asm.op.JumpLt;
import org.xvm.asm.op.JumpLte;
import org.xvm.asm.op.JumpNotEq;
import org.xvm.asm.op.JumpNotNull;
import org.xvm.asm.op.JumpNull;
import org.xvm.asm.op.Label;

import org.xvm.compiler.Compiler;
import org.xvm.compiler.Token;
import org.xvm.compiler.Token.Id;

import org.xvm.compiler.ast.Context.Branch;

import org.xvm.util.Severity;


/**
 * Comparison binary expression.
 *
 * <ul>
 * <li><tt>COMP_EQ:    "=="</tt> - </li>
 * <li><tt>COMP_NEQ:   "!="</tt> - </li>
 * <li><tt>COMP_LT:    "<"</tt> - </li>
 * <li><tt>COMP_GT:    "><tt>"</tt> - </li>
 * <li><tt>COMP_LTEQ:  "<="</tt> - </li>
 * <li><tt>COMP_GTEQ:  ">="</tt> - </li>
 * <li><tt>COMP_ORD:   "<=><tt>"</tt> - </li>
 * </ul>
 *
 * There are special cases when the left side of a Comparison is itself a similar Comparison:
 *
 * <pre><code>
 *     if (a == b == c) {...}
 *     if (a != b != c) {...}
 *     if (a < b <= c) {...}
 *     if (a > b >= c) {...}
 * </code></pre>
 *
 * <ul><li>The first compares a to b, and if equal, then compares b to c, and if equals, the result
 *         is True; otherwise the result is False.
 * </li><li>The second compares a to b, and if not equal, then compares a to c, and if not equal,
 *          then compares b to c, and if not equal, the result it True; otherwise the result is
 *          False.
 * </li><li>The third compares a to b, and if a is less than b, then it compares b to c, and if b is
 *          less than or equal to c, then the result is True; otherwise the result is False.
 * </li><li>The last compares a to b, and if a is greater than b, then it compares b to c, and if b
 *          is greater than or equal to c, then the result is True; otherwise the result is False.
 * </li></ul>
 *
 * In all examples, the expressions a, b, and c will not be evaluated more than once.
 *
 * The parser will not allow "==" and "!=" to be mixed. The parser will allow "<" and "<=" to be
 * mixed, and ">" and ">=" to be mixed, but will not allow "<"/"<=" and ">"/">=" to be mixed.
 *
 * @see TypeConstant#supportsEquals
 * @see TypeConstant#supportsCompare
 * @see TypeConstant#callEquals
 * @see TypeConstant#callCompare
 */
public class CmpExpression
        extends BiExpression
    {
    // ----- constructors --------------------------------------------------------------------------

    public CmpExpression(Expression expr1, Token operator, Expression expr2)
        {
        super(expr1, operator, expr2);

        switch (operator.getId())
            {
            case COMP_EQ:
            case COMP_NEQ:
            case COMP_LT:
            case COMP_GT:
            case COMP_LTEQ:
            case COMP_GTEQ:
            case COMP_ORD:
                break;

            default:
                throw new IllegalArgumentException("operator: " + operator);
            }
        }


    // ----- accessors -----------------------------------------------------------------------------

    /**
     * @return true iff the expression produces a Boolean value, or false iff the expression
     *         produces an Ordered value
     */
    public boolean producesBoolean()
        {
        return operator.getId() != Id.COMP_ORD;
        }

    /**
     * @return true iff the expression uses a type composition's equals() function, or false iff the
     *         expression uses a type composition's compare() function
     */
    public boolean usesEquals()
        {
        Id id = operator.getId();
        return id == Id.COMP_EQ | id == Id.COMP_NEQ;
        }

    public boolean isAscending()
        {
        Id id = operator.getId();
        return id == Id.COMP_LT | id == Id.COMP_LTEQ;
        }


    // ----- compilation ---------------------------------------------------------------------------

    @Override
    public TypeConstant getImplicitType(Context ctx)
        {
        return producesBoolean()
                ? pool().typeBoolean()
                : pool().typeOrdered();
        }

    @Override
    protected Expression validate(Context ctx, TypeConstant typeRequired, ErrorListener errs)
        {
        ConstantPool pool   = pool();
        boolean      fValid = true;
        boolean      fEqual = usesEquals();

        // attempt to guess the types that are being compared
        TypeConstant type1 = expr1.getImplicitType(ctx);

        // allow the second expression to resolve names based on the first value type's
        // contributions
        boolean fInfer = type1 != null;
        if (fInfer)
            {
            ctx = ctx.enterInferring(type1);
            }
        TypeConstant type2 = expr2.getImplicitType(ctx);
        if (fInfer)
            {
            ctx = ctx.exit();
            }

        TypeConstant typeRequest = chooseCommonType(pool, fEqual, type1, type2);
        Expression   expr1New    = expr1.validate(ctx, typeRequest, errs);
        if (expr1New == null)
            {
            fValid = false;
            }
        else
            {
            expr1 = expr1New;
            type1 = expr1New.getType();

            // if we weren't previously able to determine a "target" type to use, then try again now
            // that the first expression is validated
            if (typeRequest == null)
                {
                typeRequest = chooseCommonType(pool, fEqual, type1, type2);
                }

            // if nothing worked, use the left type for the right expression validation
            if (typeRequest == null)
                {
                typeRequest = type1;
                }
            }

        if (fInfer)
            {
            ctx = ctx.enterInferring(type1);
            }
        Expression expr2New = expr2.validate(ctx, typeRequest, errs);
        if (fInfer)
            {
            ctx = ctx.exit();
            }

        if (expr2New == null)
            {
            fValid = false;
            }
        else
            {
            expr2 = expr2New;
            type2 = expr2New.getType();

            if (fValid)
                {
                boolean fConst1 = expr1New.isConstant();
                boolean fConst2 = expr2New.isConstant();

                // make sure that we can compare the left value to the right value
                TypeConstant typeCommon = chooseCommonType(pool, fEqual, type1, fConst1, type2, fConst2, true);
                if (typeCommon == null)
                    {
                    // try to resolve the types using the current context
                    TypeConstant type1R = ctx.resolveFormalType(type1);
                    TypeConstant type2R = ctx.resolveFormalType(type2);

                    typeCommon = chooseCommonType(pool, fEqual, type1R, fConst1, type2R, fConst2, true);
                    }

                if (typeCommon == null)
                    {
                    fValid = false;
                    if (type1.equals(pool.typeNull()))
                        {
                        log(errs, Severity.ERROR, Compiler.EXPRESSION_NOT_NULLABLE,
                                type2.getValueString());
                        }
                    else if (type2.equals(pool.typeNull()))
                        {
                        log(errs, Severity.ERROR, Compiler.EXPRESSION_NOT_NULLABLE,
                                type1.getValueString());
                        }
                    else
                        {
                        log(errs, Severity.ERROR, Compiler.TYPES_NOT_COMPARABLE,
                                type1.getValueString(), type2.getValueString());
                        }
                    }
                else
                    {
                    m_typeCommon = typeCommon;
                    }
                }
            }

        TypeConstant typeResult = getImplicitType(ctx);
        Constant     constVal   = null;

        CheckInference:
        if (fValid)
            {
            if (expr1New.isConstant() && expr2New.isConstant())
                {
                try
                    {
                    constVal = expr1New.toConstant().apply(operator.getId(), expr2New.toConstant());
                    }
                catch (RuntimeException ignore) {}
                break CheckInference;
                }

            if (expr1New instanceof NameExpression expr1Name)
                {
                if (type2.equals(pool().typeNull()))
                    {
                    m_fArg2Null = true;
                    fValid      = checkNullComparison(ctx, expr1Name, errs);
                    break CheckInference;
                    }
                if (type2.isTypeOfType())
                    {
                    checkFormalType(ctx, expr1Name, type2);
                    break CheckInference;
                    }
                }

            if (expr2New instanceof NameExpression expr2Name)
                {
                if (type1.equals(pool().typeNull()))
                    {
                    m_fArg1Null = true;
                    fValid      = checkNullComparison(ctx, expr2Name, errs);
                    break CheckInference;
                    }
                if (type1.isTypeOfType())
                    {
                    checkFormalType(ctx, expr2Name, type1);
                    break CheckInference;
                    }
                }
            }

        return finishValidation(ctx, typeRequired, typeResult,
                fValid ? TypeFit.Fit : TypeFit.NoFit, constVal, errs);
        }

    /**
     * Choose a common type for the specified types without checking for a required function.
     *
     * @param fEqual  true if we need the equality comparison; false for ordering comparison
     * @param type1   the first type
     * @param type2   the second type
     *
     * @return the common type; null if there is no common type
     */
    protected static TypeConstant chooseCommonType(
            ConstantPool pool, boolean fEqual, TypeConstant type1, TypeConstant type2)
        {
        return chooseCommonType(pool, fEqual, type1, false, type2, false, false);
        }

    /**
     * Choose a common type for the specified types.
     *
     * @param fEqual   true if we need the equality comparison; false for ordering comparison
     * @param type1    the first type
     * @param fConst1  specifies if the first expression is a constant; used only if fCheck is true
     * @param type2    the second type
     * @param fConst2  specifies if the second expression is a constant; used only if fCheck is true
     * @param fCheck   if true, ensure the common type has the required function
     *
     * @return the common type; null if there is no common type
     */
    protected static TypeConstant chooseCommonType(ConstantPool pool,  boolean fEqual,
                                                   TypeConstant type1, boolean fConst1,
                                                   TypeConstant type2, boolean fConst2,
                                                   boolean fCheck)
        {
        if (type1 != null && type1.containsUnresolved() ||
            type2 != null && type2.containsUnresolved())
            {
            return null;
            }

        if (type1 instanceof CastTypeConstant)
            {
            type1 = type1.getUnderlyingType2();
            }
        if (type2 instanceof CastTypeConstant)
            {
            type2 = type2.getUnderlyingType2();
            }

        TypeConstant typeCommon = Op.selectCommonType(type1, type2, ErrorListener.BLACKHOLE);

        if (type1 == null || type2 == null)
            {
            return typeCommon;
            }

        if (typeCommon != null && fCheck)
            {
            if (fEqual
                    ? typeCommon.supportsEquals (type1, fConst1) &&
                      typeCommon.supportsEquals (type2, fConst2)
                   // Compare
                    : typeCommon.supportsCompare(type1, fConst1) &&
                      typeCommon.supportsCompare(type2, fConst2))
                {
                return typeCommon;
                }

            // the support check failed; go to the resolution logic
            typeCommon = null;
            }

        if (typeCommon == null)
            {
            // equality check for any Ref objects is allowed
            if (fEqual
                    && type1.isA(pool.typeRef())
                    && type2.isA(pool.typeRef()))
                {
                return pool.typeRef();
                }

            // equality check between Class and Type is allowed as a Type
            if (fEqual &&
                    (type1.isA(pool.typeType()) && type2.isA(pool.typeClass()) ||
                     type2.isA(pool.typeType()) && type1.isA(pool.typeClass())))
                {
                return pool.typeType();
                }

            // try to resolve formal types
            boolean fFormal1 = type1.containsFormalType(true);
            boolean fFormal2 = type2.containsFormalType(true);

            if (fFormal1 ^ fFormal2)
                {
                if (fFormal1)
                    {
                    type1 = type1.resolveConstraints();
                    }
                if (fFormal2)
                    {
                    type2 = type2.resolveConstraints();
                    }
                // since it's guaranteed that neither type contains formal, we can recurse
                typeCommon = chooseCommonType(pool, fEqual, type1, fConst1, type2, fConst2, fCheck);
                }
            }
        return typeCommon;
        }

    private boolean checkNullComparison(Context ctx, NameExpression exprTarget, ErrorListener errs)
        {
        TypeConstant typeTarget = exprTarget.getType();
        TypeConstant typeNull   = pool().typeNull();
        TypeConstant typeTrue   = null;
        TypeConstant typeFalse  = null;

        if (!typeTarget.isNullable() && !typeNull.isA(typeTarget.resolveConstraints()))
            {
            log(errs, Severity.ERROR, Compiler.EXPRESSION_NOT_NULLABLE, typeTarget.getValueString());
            return false;
            }

        switch (operator.getId())
            {
            case COMP_EQ:
                typeTrue  = typeNull;
                typeFalse = typeTarget.removeNullable();
                break;

            case COMP_NEQ:
                typeTrue  = typeTarget.removeNullable();
                typeFalse = typeNull;
                break;
            }

        exprTarget.narrowType(ctx, Branch.WhenTrue,  typeTrue);
        exprTarget.narrowType(ctx, Branch.WhenFalse, typeFalse);
        return true;
        }

    private void checkFormalType(Context ctx, NameExpression exprTarget, TypeConstant typeType)
        {
        TypeConstant typeTarget = exprTarget.getType();
        if (typeTarget.isFormalTypeType())
            {
            switch (operator.getId())
                {
                case COMP_EQ:
                    exprTarget.narrowType(ctx, Branch.WhenTrue, typeType);
                    break;

                case COMP_NEQ:
                    exprTarget.narrowType(ctx, Branch.WhenFalse, typeType);
                    break;
                }
            }
        }

    @Override
    public void generateAssignment(Context ctx, Code code, Assignable LVal, ErrorListener errs)
        {
        if (LVal.isLocalArgument())
            {
            // evaluate the sub-expressions
            Argument arg1      = ensurePointInTime(code,
                                 expr1.generateArgument(ctx, code, true, true, errs));
            Argument arg2      = expr2.generateArgument(ctx, code, true, true, errs);
            Argument argResult = LVal.getLocalArgument();
            OpTest   op = switch (operator.getId())
                {
                case COMP_EQ ->
                    m_fArg1Null ? new IsNull(arg2, argResult) :
                    m_fArg2Null ? new IsNull(arg1, argResult) :
                                  new IsEq(arg1, arg2, argResult);

                case COMP_NEQ ->
                    m_fArg1Null ? new IsNotNull(arg2, argResult) :
                    m_fArg2Null ? new IsNotNull(arg1, argResult) :
                                  new IsNotEq(arg1, arg2, argResult);

                case COMP_LT   -> new IsLt(arg1, arg2, argResult);
                case COMP_GT   -> new IsGt(arg1, arg2, argResult);
                case COMP_LTEQ -> new IsLte(arg1, arg2, argResult);
                case COMP_GTEQ -> new IsGte(arg1, arg2, argResult);
                case COMP_ORD  -> new Cmp(arg1, arg2, argResult);
                default        -> throw new IllegalStateException();
                };

            // generate the op that combines the two sub-expressions

            op.setCommonType(m_typeCommon);
            code.add(op);
            return;
            }

        super.generateAssignment(ctx, code, LVal, errs);
        }

    @Override
    public void generateConditionalJump(
            Context ctx, Code code, Label label, boolean fWhenTrue, ErrorListener errs)
        {
        if (!isConstant() && producesBoolean())
            {
            // evaluate the sub-expressions
            Argument   arg1 = ensurePointInTime(code,
                              expr1.generateArgument(ctx, code, true, true, errs));
            Argument   arg2 = expr2.generateArgument(ctx, code, true, true, errs);
            OpCondJump op = switch (operator.getId())
                {
                case COMP_EQ ->
                    fWhenTrue
                        ? (m_fArg1Null ? new JumpNull(arg2, label) :
                           m_fArg2Null ? new JumpNull(arg1, label) :
                                         new JumpEq(arg1, arg2, label))
                        : (m_fArg1Null ? new JumpNotNull(arg2, label) :
                           m_fArg2Null ? new JumpNotNull(arg1, label) :
                                         new JumpNotEq(arg1, arg2, label));
                case COMP_NEQ ->
                    fWhenTrue
                        ? (m_fArg1Null ? new JumpNotNull(arg2, label) :
                           m_fArg2Null ? new JumpNotNull(arg1, label) :
                                         new JumpNotEq(arg1, arg2, label))

                        : (m_fArg1Null ? new JumpNull(arg2, label) :
                           m_fArg2Null ? new JumpNull(arg1, label) :
                                         new JumpEq(arg1, arg2, label));
                case COMP_LT ->
                    fWhenTrue
                        ? new JumpLt(arg1, arg2, label)
                        : new JumpGte(arg1, arg2, label);

                case COMP_GT ->
                    fWhenTrue
                        ? new JumpGt(arg1, arg2, label)
                        : new JumpLte(arg1, arg2, label);

                case COMP_LTEQ ->
                    fWhenTrue
                        ? new JumpLte(arg1, arg2, label)
                        : new JumpGt(arg1, arg2, label);

                case COMP_GTEQ -> fWhenTrue
                    ? new JumpGte(arg1, arg2, label)
                    : new JumpLt(arg1, arg2, label);

                default ->
                    throw new IllegalStateException();
                };

            // generate the op that combines the two sub-expressions

            op.setCommonType(m_typeCommon);
            code.add(op);
            return;
            }

        super.generateConditionalJump(ctx, code, label, fWhenTrue, errs);
        }

    @Override
    public ExprAST getExprAST()
        {
        Operator op = switch (operator.getId())
            {
            case COMP_EQ   -> Operator.CompEq;
            case COMP_NEQ  -> Operator.CompNeq;
            case COMP_LT   -> Operator.CompLt;
            case COMP_GT   -> Operator.CompGt;
            case COMP_LTEQ -> Operator.CompLtEq;
            case COMP_GTEQ -> Operator.CompGtEq;
            case COMP_ORD  -> Operator.CompOrd;
            default -> throw new UnsupportedOperationException(operator.getValueText());
            };
        return new CondOpExprAST(expr1.getExprAST(), op, expr2.getExprAST());
        }


    // ----- fields --------------------------------------------------------------------------------

    /**
     * The common type used for the comparison.
     */
    protected TypeConstant m_typeCommon;

    private transient boolean m_fArg1Null; // is the first arg equal to "Null"
    private transient boolean m_fArg2Null; // is the second arg equal to "Null"
    }