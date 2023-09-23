package org.xvm.asm.ast;


import java.io.DataInput;
import java.io.DataOutput;
import java.io.IOException;

import java.util.Arrays;
import java.util.Objects;

import static org.xvm.util.Handy.readMagnitude;
import static org.xvm.util.Handy.writePackedLong;

import static org.xvm.asm.ast.BinaryAST.NodeType.MapExpr;


/**
 * A Map expression that is not a constant.
 */
public class MapExprAST<C>
        extends ExprAST<C> {

    private C            type;
    private ExprAST<C>[] keys;
    private ExprAST<C>[] values;

    MapExprAST() {}

    public MapExprAST(C type, ExprAST<C>[] keys, ExprAST<C>[] values) {
        assert type != null;
        assert keys   != null && Arrays.stream(keys  ).allMatch(Objects::nonNull);
        assert values != null && Arrays.stream(values).allMatch(Objects::nonNull);
        assert keys.length == values.length;
        this.type   = type;
        this.keys   = keys;
        this.values = values;
    }

    public C getType() {
        return type;
    }

    public ExprAST<C>[] getKeys() {
        return keys; // note: caller must not modify returned array in any way
    }

    public ExprAST<C>[] getValues() {
        return values; // note: caller must not modify returned array in any way
    }

    @Override
    public NodeType nodeType() {
        return MapExpr;
    }

    @Override
    public C getType(int i) {
        assert i == 0;
        return type;
    }

    @Override
    protected void readBody(DataInput in, ConstantResolver<C> res)
            throws IOException {
        type   = res.getConstant(readMagnitude(in));
        keys   = readExprArray(in, res);
        values = readExprArray(in, res);
    }

    @Override
    public void prepareWrite(ConstantResolver<C> res) {
        type = res.register(type);
        prepareASTArray(keys, res);
        prepareASTArray(values, res);
    }

    @Override
    protected void writeBody(DataOutput out, ConstantResolver<C> res)
            throws IOException {
        writePackedLong(out, res.indexOf(type));
        writeExprArray(keys, out, res);
        writeExprArray(values, out, res);
    }

    @Override
    public String dump() {
        StringBuilder buf = new StringBuilder();
        buf.append(type).append(":[");
        for (int i = 0, c = keys.length; i < c; i++) {
            ExprAST key   = keys[i];
            ExprAST value = values[i];
            buf.append(key.dump())  .append("=")
               .append(value.dump()).append(", ");
        }
        buf.append(']');
        return buf.toString();
    }

    @Override
    public String toString() {
        StringBuilder buf = new StringBuilder();
        buf.append(type).append(":[");
        for (int i = 0, c = keys.length; i < c; i++) {
            ExprAST key   = keys[i];
            ExprAST value = values[i];
            buf.append(key.toString())  .append("=")
               .append(value.toString()).append(", ");
        }
        buf.append(']');
        return buf.toString();
    }
}