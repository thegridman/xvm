package org.xvm.asm.ast;


import java.io.DataInput;
import java.io.DataOutput;
import java.io.IOException;

import java.util.Arrays;
import java.util.Objects;

import org.xvm.asm.ast.LanguageAST.ExprAST;

import static org.xvm.util.Handy.readMagnitude;
import static org.xvm.util.Handy.writePackedLong;

import static org.xvm.asm.ast.LanguageAST.NodeType.LIST_EXPR;


/**
 * A List expression that is not a constant.
 */
public class ListExprAST<C>
        extends ExprAST<C> {

    private C            type;
    private ExprAST<C>[] values;

    ListExprAST() {}

    public ListExprAST(C type, ExprAST<C>[] values) {
        assert type != null;
        assert values != null && Arrays.stream(values).allMatch(Objects::nonNull);
        this.type   = type;
        this.values = values;
    }

    public C getType() {
        return type;
    }

    public ExprAST<C>[] getValues() {
        return values; // note: caller must not modify returned array in any way
    }

    @Override
    public C getType(int i) {
        assert i == 0;
        return type;
    }

    @Override
    public NodeType nodeType() {
        return LIST_EXPR;
    }

    @Override
    public void read(DataInput in, ConstantResolver<C> res)
            throws IOException {
        type   = res.getConstant(readMagnitude(in));
        values = readExprArray(in, res);
    }

    @Override
    public void prepareWrite(ConstantResolver<C> res) {
        type = res.register(type);
        prepareWriteASTArray(res, values);
    }

    @Override
    public void write(DataOutput out, ConstantResolver<C> res)
            throws IOException {
        out.writeByte(nodeType().ordinal());

        writePackedLong(out, res.indexOf(type));
        writeASTArray(out, res, values);
    }

    @Override
    public String dump() {
        StringBuilder buf = new StringBuilder();
        buf.append(type).append(":[");
        for (ExprAST value : values) {
            buf.append(value.dump()).append(", ");
        }
        buf.append(']');
        return buf.toString();
    }

    @Override
    public String toString() {
        StringBuilder buf = new StringBuilder();
        buf.append(type).append(":[");
        for (ExprAST value : values) {
            buf.append(value.toString()).append(", ");
        }
        buf.append(']');
        return buf.toString();
    }
}