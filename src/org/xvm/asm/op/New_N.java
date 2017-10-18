package org.xvm.asm.op;


import java.io.DataInput;
import java.io.DataOutput;
import java.io.IOException;

import org.xvm.asm.Constant;
import org.xvm.asm.MethodStructure;
import org.xvm.asm.OpCallable;
import org.xvm.asm.Register;

import org.xvm.asm.constants.IdentityConstant;

import org.xvm.runtime.ClassTemplate;
import org.xvm.runtime.Frame;
import org.xvm.runtime.ObjectHandle;
import org.xvm.runtime.ObjectHandle.ExceptionHandle;
import org.xvm.runtime.Utils;

import static org.xvm.util.Handy.readPackedInt;
import static org.xvm.util.Handy.writePackedLong;


/**
 * NEW_N CONST-CONSTRUCT, #params:(rvalue), lvalue-return
 */
public class New_N
        extends OpCallable
    {
    /**
     * Construct a NEW_N op.
     *
     * @param nConstructorId  identifies the constructor
     * @param anArg           the constructor arguments
     * @param nRet            the location to store the new object
     *
     * @deprecated
     */
    public New_N(int nConstructorId, int[] anArg, int nRet)
        {
        super(nConstructorId);

        m_anArgValue = anArg;
        m_nRetValue = nRet;
        }

    /**
     * Construct a NEW_1 op based on the passed arguments.
     *
     * @param argConstructor  the constructor Argument
     * @param aArgValue       the array of value Arguments
     * @param regReturn       the return Register
     */
    public New_N(Argument argConstructor, Argument[] aArgValue, Register regReturn)
        {
        super(argConstructor);

        m_aArgValue = aArgValue;
        m_regReturn = regReturn;
        }

    /**
     * Deserialization constructor.
     *
     * @param in      the DataInput to read from
     * @param aconst  an array of constants used within the method
     */
    public New_N(DataInput in, Constant[] aconst)
            throws IOException
        {
        super(readPackedInt(in));

        m_anArgValue = readIntArray(in);
        m_nRetValue = readPackedInt(in);
        }

    @Override
    public void write(DataOutput out, ConstantRegistry registry)
            throws IOException
        {
        super.write(out, registry);

        if (m_aArgValue != null)
            {
            m_anArgValue = encodeArguments(m_aArgValue, registry);
            m_nRetValue = encodeArgument(m_regReturn, registry);
            }

        writeIntArray(out, m_anArgValue);
        writePackedLong(out, m_nRetValue);
        }

    @Override
    public int getOpCode()
        {
        return OP_NEW_N;
        }

    @Override
    public int process(Frame frame, int iPC)
        {
        MethodStructure constructor = getMethodStructure(frame);

        try
            {
            ObjectHandle[] ahVar = frame.getArguments(m_anArgValue, constructor.getMaxVars());
            if (ahVar == null)
                {
                return R_REPEAT;
                }

            IdentityConstant constClass = constructor.getParent().getParent().getIdentityConstant();
            ClassTemplate template = frame.f_context.f_types.getTemplate(constClass);

            if (anyProperty(ahVar))
                {
                Frame.Continuation stepNext = frameCaller -> template.construct(frame, constructor,
                    template.f_clazzCanonical, ahVar, m_nRetValue);

                return new Utils.GetArguments(ahVar, new int[]{0}, stepNext).doNext(frame);
                }
            return template.construct(frame, constructor,
                    template.f_clazzCanonical, ahVar, m_nRetValue);
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

        registerArguments(m_aArgValue, registry);
        }

    private int[] m_anArgValue;
    private int   m_nRetValue;

    private Argument[] m_aArgValue;
    private Register m_regReturn;
    }