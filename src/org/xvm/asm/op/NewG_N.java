package org.xvm.asm.op;


import java.io.DataInput;
import java.io.DataOutput;
import java.io.IOException;

import org.xvm.asm.Argument;
import org.xvm.asm.Constant;
import org.xvm.asm.MethodStructure;
import org.xvm.asm.OpCallable;

import org.xvm.asm.constants.MethodConstant;

import org.xvm.runtime.ClassComposition;
import org.xvm.runtime.ClassTemplate;
import org.xvm.runtime.Frame;
import org.xvm.runtime.ObjectHandle;
import org.xvm.runtime.ObjectHandle.ExceptionHandle;
import org.xvm.runtime.Utils;

import static org.xvm.util.Handy.readPackedInt;
import static org.xvm.util.Handy.writePackedLong;


/**
 * NEWG_N CONSTRUCT, TYPE, #:(rvalue) lvalue
 */
public class NewG_N
        extends OpCallable
    {
    /**
     * Construct a NEWG_N op based on the passed arguments.
     *
     * @param constMethod  the constructor method
     * @param argType      the type Argument
     * @param aArgValue    the array of value Arguments
     * @param argReturn    the return Argument
     */
    public NewG_N(MethodConstant constMethod, Argument argType, Argument[] aArgValue, Argument argReturn)
        {
        super(constMethod);

        m_aArgValue = aArgValue;
        m_argType = argType;
        m_argReturn = argReturn;
        }

    /**
     * Deserialization constructor.
     *
     * @param in      the DataInput to read from
     * @param aconst  an array of constants used within the method
     */
    public NewG_N(DataInput in, Constant[] aconst)
            throws IOException
        {
        super(in, aconst);

        m_nTypeValue = readPackedInt(in);
        m_anArgValue = readIntArray(in);
        m_nRetValue = readPackedInt(in);
        }

    @Override
    public void write(DataOutput out, ConstantRegistry registry)
            throws IOException
        {
        super.write(out, registry);

        if (m_argType != null)
            {
            m_nTypeValue = encodeArgument(m_argType, registry);
            m_anArgValue = encodeArguments(m_aArgValue, registry);
            m_nRetValue = encodeArgument(m_argReturn, registry);
            }

        writePackedLong(out, m_nTypeValue);
        writeIntArray(out, m_anArgValue);
        writePackedLong(out, m_nRetValue);
        }

    @Override
    public int getOpCode()
        {
        return OP_NEWG_N;
        }

    @Override
    public int process(Frame frame, int iPC)
        {
        try
            {
            MethodStructure constructor = getMethodStructure(frame);

            ObjectHandle[] ahVar = frame.getArguments(m_anArgValue, constructor.getMaxVars());
            if (ahVar == null)
                {
                return R_REPEAT;
                }

            ClassComposition clzTarget = frame.resolveClass(m_nTypeValue);
            ClassTemplate    template  = clzTarget.getTemplate();
            ObjectHandle     hParent   = clzTarget.isInstanceChild() ? frame.getThis() : null;

            if (frame.isNextRegister(m_nRetValue))
                {
                frame.introduceResolvedVar(m_nRetValue, clzTarget.getType());
                }

            if (anyDeferred(ahVar))
                {
                Frame.Continuation stepNext = frameCaller ->
                    template.construct(frame, constructor, clzTarget, hParent, ahVar, m_nRetValue);

                return new Utils.GetArguments(ahVar, stepNext).doNext(frame);
                }
            return template.construct(frame, constructor, clzTarget, hParent, ahVar, m_nRetValue);
            }
        catch (ExceptionHandle.WrapperException e)
            {
            return frame.raiseException(e);
            }
        }

    @Override
    public void registerConstants(ConstantRegistry registry)
        {
        super.registerConstants(registry);

        m_argType = registerArgument(m_argType, registry);
        registerArguments(m_aArgValue, registry);
        }

    @Override
    protected String getParamsString()
        {
        return getParamsString(m_anArgValue, m_aArgValue);
        }

    private int   m_nTypeValue;
    private int[] m_anArgValue;

    private Argument m_argType;
    private Argument[] m_aArgValue;
    }
