package org.xvm.compiler.ast;


import org.xvm.asm.Constant;

import org.xvm.asm.constants.ResolvableConstant;
import org.xvm.asm.constants.TypeConstant;


/**
 * A type expression is used to specify an abstract data type. In its compiled form, there are many
 * different possible representations of an abstract data type, depending on how it is declared, and
 * depending on how it is used. A TypeExpression may be used to indicate eitherh an Constant
 * (such as a ModuleConstant, PackageConstant, ClassConstant, etc.) or a TypeConstant (such as a
 * ClassTypeConstant, a ParameterTypeConstant, etc.) Often, a type expression must provide a
 * compiled representation of itself before it is able to resolve what its actual ADT will be; in
 * these cases, the type expression can create a temporary place-holder, known as an unresolved
 * constant, which will later be replaced with the real ADT information once the type information
 * has been fully resolved.
 *
 * @author cp 2017.03.28
 */
public abstract class TypeExpression
        extends Expression
    {
    // ----- type specific functionality -----------------------------------------------------------

    @Override
    public TypeExpression toTypeExpression()
        {
        return this;
        }

    /**
     * Obtain the TypeConstant currently associated with this TypeExpression, creating an unresolved
     * TypeConstant if necessary.
     *
     * @return a TypeConstant
     */
    public TypeConstant ensureTypeConstant()
        {
        TypeConstant constType = getTypeConstant();
        if (constType == null)
            {
            constType = instantiateTypeConstant();
            setTypeConstant(constType);
            }
        return constType;
        }

    /**
     * This needs to be overridden by any TypeExpression that evaluates to something other than a
     * class type.
     *
     * @return
     */
    protected abstract TypeConstant instantiateTypeConstant();


    // ----- accessors -----------------------------------------------------------------------------

    /**
     * @return the TypeConstant currently associated with this TypeExpression, or null
     */
    protected TypeConstant getTypeConstant()
        {
        return m_constType;
        }

    /**
     * @param constType  the TypeConstant to associate with this TypeExpression
     */
    protected void setTypeConstant(TypeConstant constType)
        {
        // store the new type constant
        m_constType = constType;
        }


    // ----- fields --------------------------------------------------------------------------------

    /**
     * The TypeConstant currently associated with this TypeExpression.
     */
    private TypeConstant m_constType;
    }
