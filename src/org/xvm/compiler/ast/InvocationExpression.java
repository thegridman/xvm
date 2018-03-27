package org.xvm.compiler.ast;


import java.lang.reflect.Field;

import java.util.List;

import org.xvm.asm.ConstantPool;
import org.xvm.asm.ErrorListener;
import org.xvm.asm.Version;

import org.xvm.asm.constants.ConditionalConstant;
import org.xvm.asm.constants.TypeConstant;
import org.xvm.compiler.ast.Statement.Context;


/**
 * Invocation expression represents calling a method or function.
 *
 * If you already have an expression "expr", this is for "expr(args)".
 */
public class InvocationExpression
        extends Expression
    {
    // ----- constructors --------------------------------------------------------------------------

    public InvocationExpression(Expression expr, List<Expression> args, long lEndPos)
        {
        this.expr    = expr;
        this.args    = args;
        this.lEndPos = lEndPos;
        }


    // ----- accessors -----------------------------------------------------------------------------

    @Override
    public boolean validateCondition(ErrorListener errs)
        {
        return expr instanceof NameExpression && ((NameExpression) expr).isDotNameWithNoParams("versionMatches")
                && args.size() == 1 && args.get(0) instanceof VersionExpression
                || super.validateCondition(errs);
        }

    @Override
    public ConditionalConstant toConditionalConstant()
        {
        if (validateCondition(null))
            {
            // build the qualified module name
            NameExpression exprNames = (NameExpression) expr;
            StringBuilder  sb        = new StringBuilder();
            for (int i = 0, c = exprNames.getNameCount() - 1; i < c; ++i)
                {
                if (i > 0)
                    {
                    sb.append('.');
                    }
                sb.append(exprNames.getName(i));
                }

            String       sModule = sb.toString();
            Version      version = ((VersionExpression) args.get(0)).getVersion();
            ConstantPool pool    = pool();
            return pool.ensureImportVersionCondition(
                    pool.ensureModuleConstant(sModule), pool.ensureVersionConstant(version));
            }

        return super.toConditionalConstant();
        }

    @Override
    public long getStartPosition()
        {
        return expr.getStartPosition();
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


    // ----- compilation ---------------------------------------------------------------------------

    // TODO getValueCount() - could be any #?

    @Override
    public boolean isConstant()
        {
        // assume all invocations can have side effects
        return false;
        }

    @Override
    protected boolean validate(Context ctx, TypeConstant typeRequired, ErrorListener errs)
        {
        // TODO we have an "expr" that represents the thing being invoked, and we have "args" that represents the things being passed
        // TODO we may need one to validate the other, i.e. we may need to know the arg types to find the method, the the method to validate the args by required type

        // if (expr.validate(ctx, pool().typeFunction(), errs))
        // TODO
        return true;
        }


    // ----- debugging assistance ------------------------------------------------------------------

    @Override
    public String toString()
        {
        StringBuilder sb = new StringBuilder();
        sb.append(expr)
          .append('(');

        boolean first = true;
        for (Expression arg : args)
            {
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
        return sb.toString();
        }

    @Override
    public String getDumpDesc()
        {
        return toString();
        }


    // ----- fields --------------------------------------------------------------------------------

    protected Expression       expr;
    protected List<Expression> args;
    protected long             lEndPos;

    private static final Field[] CHILD_FIELDS = fieldsForNames(InvocationExpression.class, "expr", "args");
    }
