package org.xvm.asm.ast;


import java.io.DataInput;
import java.io.DataOutput;
import java.io.IOException;

import static org.xvm.asm.ast.BinaryAST.NodeType.ContinueStmt;

import static org.xvm.util.Handy.readMagnitude;
import static org.xvm.util.Handy.writePackedLong;


/**
 * A "continue" statement that either "falls through" in a switch/case block, or advances to the
 * start of the next iteration in a loop.
 */
public class ContinueStmtAST
        extends BinaryAST {

    private int depth;

    ContinueStmtAST() {
        depth = -1;
    }

    public ContinueStmtAST(int depth) {
        assert depth >= 0 & depth < 1024;            // arbitrary limit to catch obvious math bugs
        this.depth = depth;
    }

    @Override
    public NodeType nodeType() {
        return ContinueStmt;
    }

    /**
     * @return a value, either 0 to indicate that the continue applies to the first enclosing loop
     *         or switch statement, or non-zero n to indicate that the continue applies to the n-th
     *         "statement parent" of this statement, where 1 is this statement's enclosing statement
     */
    public int getDepth() {
        return depth;
    }

    @Override
    protected void readBody(DataInput in, ConstantResolver res)
            throws IOException {
        depth = readMagnitude(in);
    }

    @Override
    public void prepareWrite(ConstantResolver res) {}

    @Override
    protected void writeBody(DataOutput out, ConstantResolver res)
            throws IOException {
        writePackedLong(out, depth);
    }

    @Override
    public String toString() {
        return depth <= 0
            ? "continue;"
            : "continue ^" + depth + ";";
    }
}