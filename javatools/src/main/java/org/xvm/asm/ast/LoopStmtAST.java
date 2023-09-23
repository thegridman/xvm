package org.xvm.asm.ast;


import java.io.DataInput;
import java.io.DataOutput;
import java.io.IOException;

import static org.xvm.asm.ast.BinaryAST.NodeType.LoopStmt;

import static org.xvm.util.Handy.indentLines;

/**
 * A "while(True){...}" statement.
 */
public class LoopStmtAST<C>
        extends BinaryAST<C> {

    private ExprAST<C>[] specialRegs; // RegAllocAST<C>[]
    private BinaryAST<C> body;

    LoopStmtAST() {}

    public LoopStmtAST(ExprAST<C>[] specialRegs, BinaryAST<C> body) {
        assert body != null;

        this.specialRegs = specialRegs == null  ? NO_ALLOCS : specialRegs;
        this.body        = body;
    }

    @Override
    public NodeType nodeType() {
        return LoopStmt;
    }

    public BinaryAST<C> getBody() {
        return body;
    }

    @Override
    protected void readBody(DataInput in, ConstantResolver<C> res)
            throws IOException {
        res.enter();
        specialRegs = readExprArray(in, res);
        body        = readAST(in, res);
        res.exit();
    }

    @Override
    public void prepareWrite(ConstantResolver<C> res) {
        res.enter();
        prepareASTArray(specialRegs, res);
        prepareAST(body, res);
        res.exit();
    }

    @Override
    protected void writeBody(DataOutput out, ConstantResolver<C> res)
            throws IOException {
        writeExprArray(specialRegs, out, res);
        writeAST(body, out, res);
    }

    @Override
    public String dump() {
        return this + "\n" + indentLines(body.dump(), "  ");
    }

    @Override
    public String toString() {
        return "while(True){}";
    }
}