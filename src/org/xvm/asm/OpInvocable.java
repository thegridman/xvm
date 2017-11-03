package org.xvm.asm;


import java.io.DataInput;
import java.io.DataOutput;
import java.io.IOException;

import org.xvm.asm.constants.MethodConstant;

import org.xvm.runtime.CallChain;
import org.xvm.runtime.Frame;
import org.xvm.runtime.TypeComposition;

import static org.xvm.util.Handy.readPackedInt;
import static org.xvm.util.Handy.writePackedLong;


/**
 * Common base for NVOK_ ops.
 *
 * @author gg 2017.02.21
 */
public abstract class OpInvocable extends Op
    {
    /**
     * Construct an op based on the passed arguments.
     *
     * @param argTarget    the target Argument
     * @param constMethod  the method constant
     */
    protected OpInvocable(Argument argTarget, MethodConstant constMethod)
        {
        m_argTarget   = argTarget;
        m_constMethod = constMethod;
        }

    /**
     * Deserialization constructor.
     *
     * @param in      the DataInput to read from
     * @param aconst  an array of constants used within the method
     */
    protected OpInvocable(DataInput in, Constant[] aconst)
            throws IOException
        {
        m_nTarget   = readPackedInt(in);
        m_nMethodId = readPackedInt(in);
        }

    @Override
    public void write(DataOutput out, ConstantRegistry registry)
            throws IOException
        {
        if (m_argTarget != null)
            {
            m_nTarget = encodeArgument(m_argTarget, registry);
            m_nMethodId = encodeArgument(m_constMethod, registry);
            }

        out.writeByte(getOpCode());

        writePackedLong(out, m_nTarget);
        writePackedLong(out, m_nMethodId);
        }

    /**
     * A "virtual constant" indicating whether or not this op has multiple return values.
     *
     * @return true iff the op has multiple return values.
     */
    protected boolean isMultiReturn()
        {
        return false;
        }

    @Override
    public void simulate(Scope scope)
        {
        if (isMultiReturn())
            {
            checkNextRegisters(scope, m_aArgReturn);

            // TODO: remove when deprecated construction is removed
            for (int i = 0, c = m_anRetValue.length; i < c; i++)
                {
                if (scope.isNextRegister(m_anRetValue[i]))
                    {
                    scope.allocVar();
                    }
                }
            }
        else
            {
            checkNextRegister(scope, m_argReturn);

            // TODO: remove when deprecated construction is removed
            if (scope.isNextRegister(m_nRetValue))
                {
                scope.allocVar();
                }
            }
        }

    @Override
    public void registerConstants(ConstantRegistry registry)
        {
        registerArgument(m_argTarget, registry);
        registerArgument(m_constMethod, registry);

        if (isMultiReturn())
            {
            registerArguments(m_aArgReturn, registry);
            }
        else
            {
            registerArgument(m_argReturn, registry);
            }
        }

    // helper method
    protected CallChain getCallChain(Frame frame, TypeComposition clazz)
        {
        if (m_chain != null && m_clazz == clazz)
            {
            return m_chain;
            }

        MethodConstant constMethod = (MethodConstant) frame.getConstant(m_nMethodId);

        m_clazz = clazz;

        Constants.Access access = constMethod.getAccess();
        if (access == Constants.Access.PRIVATE)
            {
            m_chain = new CallChain((MethodStructure) constMethod.getComponent());
            }
        else
            {
            m_chain = clazz.getMethodCallChain(constMethod.getSignature(), access);
            }

        return m_chain;
        }

    protected int   m_nTarget;
    protected int   m_nMethodId;
    protected int   m_nRetValue = Frame.RET_UNUSED;
    protected int[] m_anRetValue;

    protected Argument       m_argTarget;
    protected MethodConstant m_constMethod;
    protected Argument       m_argReturn;  // optional
    protected Argument[]     m_aArgReturn; // optional

    private TypeComposition m_clazz;        // cached class
    private CallChain       m_chain;        // cached call chain
    }
