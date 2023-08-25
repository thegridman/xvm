package org.xvm.asm.ast;


import java.io.DataInput;
import java.io.IOException;


/**
 * An expressions that follow the pattern "expression operator expression" and produces a Boolean.
 */
public class CondOpExprAST<C>
        extends BiExprAST<C> {

    private transient C type;

    CondOpExprAST() {}

    public CondOpExprAST(Operator op, ExprAST<C> expr1, ExprAST<C> expr2) {
        super(op, expr1, expr2);
    }

    @Override
    public C getType(int i) {
        return type;
    }

    @Override
    public NodeType nodeType() {
        return NodeType.CondOpExpr;
    }

    @Override
    public void read(DataInput in, ConstantResolver<C> res)
            throws IOException {
        super.read(in, res);

        type = res.typeForName("Boolean");
    }
}