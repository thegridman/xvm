package org.xvm.asm.ast;


import java.io.DataInput;
import java.io.DataOutput;
import java.io.IOException;

import static org.xvm.asm.ast.BinaryAST.NodeType.NamedRegAlloc;
import static org.xvm.asm.ast.BinaryAST.NodeType.RegAlloc;

import static org.xvm.util.Handy.readPackedInt;
import static org.xvm.util.Handy.writePackedLong;


/**
 * Allocate a register, i.e. declare a local variable. This AST node is only an "expression" in the
 * sense that the variable (the register itself) can be used as an expression.
 */
public class RegAllocAST<C>
        extends ExprAST<C> {

    /**
     * Registers are numbered sequentially from zero, and are scoped. The register ID is not stored
     * persistently (as it can be calculated). The responsibility for assigning the register number
     * (either during compilation or after loading from disk) is not visible to this class.
     */
    private transient RegisterAST<C> reg;

    private static final RegisterAST NAMED   = new RegisterAST();
    private static final RegisterAST UNNAMED = new RegisterAST();

    RegAllocAST(boolean named) {
        reg = named ? NAMED : UNNAMED;
    }

    /**
     * Construct a register.
     *
     * @param type  the type that the register can hold
     * @param name  the name of the local variable that the register is being created for, or null
     */
    public RegAllocAST(C type, C name) {
        assert type != null;
        this.reg = new RegisterAST<>(type, name);
    }

    public RegisterAST<C> getRegister() {
        return reg;
    }

    public C getType() {
        C type = reg.getType();
        assert type != null;
        return type;
    }

    public C getName() {
        return reg.getName();
    }

    @Override
    public C getType(int i) {
        assert i == 0;
        return getType();
    }

    @Override
    public boolean isAssignable() {
        return true;
    }

    @Override
    public NodeType nodeType() {
        return reg == NAMED || reg.getName() != null ? NamedRegAlloc : RegAlloc;
    }

    @Override
    protected void readBody(DataInput in, ConstantResolver<C> res)
            throws IOException {
        assert reg == NAMED || reg == UNNAMED;

        C type = res.getConstant(readPackedInt(in));
        C name = null;
        if (nodeType() == NamedRegAlloc) {
            name = res.getConstant(readPackedInt(in));
        }

        reg = new RegisterAST<>(type, name);
        res.register(reg);
    }

    @Override
    public void prepareWrite(ConstantResolver<C> res) {
        // while the data is on the RegisterAST instance, it's technically "owned by" this; all
        // other use sites for the RegisterAST rely solely on the register's id
        reg.type = res.register(reg.type);
        reg.name = res.register(reg.name);
        res.register(reg);
    }

    @Override
    protected void writeBody(DataOutput out, ConstantResolver<C> res)
            throws IOException {
        // what is notable about the serialization format is that it does *not* include the register
        // id (number); register ids are required to be gap-less and ascending, so the id can be
        // calculated by the resolver when the AST is read back into its object form from binary
        writePackedLong(out, res.indexOf(reg.type));
        if (nodeType() == NamedRegAlloc) {
            writePackedLong(out, res.indexOf(reg.name));
        }
    }

    @Override
    public String toString() {
        return reg.toString() + ": "
                + reg.type + " " + (reg.name == null ? "_" : reg.name.toString());
    }
}