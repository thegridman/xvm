package org.xvm.asm.ast;


import java.io.DataInput;
import java.io.DataOutput;
import java.io.IOException;

import org.xvm.asm.ast.LanguageAST.StmtAST;

import static org.xvm.util.Handy.readUtf8String;
import static org.xvm.util.Handy.writeUtf8String;


/**
 * Place-holder that advertises that an implementation was missing.
 */
public class StmtNotImplAST<C>
        extends StmtAST<C> {

    private String name;

    StmtNotImplAST() {}

    public StmtNotImplAST(String name) {
        assert name != null;
        this.name = name;
    }

    @Override
    public NodeType nodeType() {
        return NodeType.StmtNotImplYet;
    }

    @Override
    public void read(DataInput in, ConstantResolver<C> res)
            throws IOException {
        name = readUtf8String(in);
    }

    @Override
    public void prepareWrite(ConstantResolver<C> res) {}

    @Override
    public void write(DataOutput out, ConstantResolver<C> res)
            throws IOException {
        out.writeByte(nodeType().ordinal());

        writeUtf8String(out, name);
    }

    @Override
    public String toString() {
        return "TODO CP: Implement statement " + name;
    }
}