package org.xvm.asm.ast;


import java.io.DataInput;
import java.io.DataOutput;
import java.io.IOException;

import java.util.Arrays;
import java.util.Objects;

import static org.xvm.util.Handy.indentLines;


/**
 * Base class for Invoke, Call and Construct nodes.
 */
public abstract class CallableExprAST<C>
        extends ExprAST<C> {

    private Object[]     retTypes;
    private ExprAST<C>[] args;

    CallableExprAST() {
    }

    /**
     * Construct an CallableExprAST.
     */
    protected CallableExprAST(C[] retTypes, ExprAST<C>[] args) {
        assert retTypes != null && Arrays.stream(retTypes).allMatch(Objects::nonNull);
        assert args     == null || Arrays.stream(args).allMatch(Objects::nonNull);

        this.retTypes = retTypes;
        this.args     = args == null ? NO_EXPRS : args;
    }

    @Override
    public int getCount() {
        return retTypes.length;
    }

    @Override
    public C getType(int i) {
        return (C) retTypes[i];
    }

    @Override
    public abstract NodeType nodeType();

    public ExprAST<C>[] getArgs() {
        return args; // note: caller must not modify returned array in any way
    }

    @Override
    protected void readBody(DataInput in, ConstantResolver<C> res)
            throws IOException {
        retTypes = readConstArray(in, res);
        args     = readExprArray(in, res);
    }

    @Override
    public void prepareWrite(ConstantResolver<C> res) {
        prepareConstArray(retTypes, res);
        prepareASTArray(args, res);
    }

    @Override
    protected void writeBody(DataOutput out, ConstantResolver<C> res)
            throws IOException {
        writeConstArray(retTypes, out, res);
        writeExprArray(args, out, res);
    }

    @Override
    public String dump() {
        StringBuilder buf = new StringBuilder();
        for (ExprAST arg : args) {
            buf.append('\n').append(indentLines(arg.dump(), "  "));
        }
        return buf.toString();
    }

    @Override
    public String toString() {
        StringBuilder buf = new StringBuilder();
        for (ExprAST arg : args) {
            buf.append('\n').append(indentLines(arg.toString(), "  "));
        }
        return buf.toString();
    }
}