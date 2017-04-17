package org.xvm.compiler.ast;


import org.xvm.asm.ErrorList;
import org.xvm.asm.StructureContainer;


/**
 * Represents a statement that corresponds to a StructureContainer in an Ecstasy FileStructure.
 *
 * @author cp 2017.04.12
 */
public abstract class StructureContainerStatement
        extends Statement
    {
    // ----- accessors -----------------------------------------------------------------------------

    public StructureContainer getStructure()
        {
        return struct;
        }

    protected void setStructure(StructureContainer struct)
        {
        this.struct = struct;
        }


    // ----- fields --------------------------------------------------------------------------------

    @Override
    protected abstract AstNode registerNames(AstNode parent, ErrorList errs);


    // ----- fields --------------------------------------------------------------------------------

    protected StructureContainer struct;
    }
