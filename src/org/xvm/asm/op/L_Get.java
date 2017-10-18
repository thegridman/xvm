package org.xvm.asm.op;


import java.io.DataInput;
import java.io.DataOutput;
import java.io.IOException;

import org.xvm.asm.Constant;
import org.xvm.asm.OpProperty;

import org.xvm.asm.constants.PropertyConstant;

import org.xvm.runtime.Frame;
import org.xvm.runtime.ObjectHandle;

import static org.xvm.util.Handy.readPackedInt;
import static org.xvm.util.Handy.writePackedLong;


/**
 * L_GET PROPERTY, lvalue ; get local property
 */
public class L_Get
        extends OpProperty
    {
    /**
     * Construct a L_GET op.
     *
     * @param nPropId  the property id
     * @param nRet     the location to store the result
     */
    public L_Get(int nPropId, int nRet)
        {
        super(nPropId);
        m_nRetValue    = nRet;
        }

    /**
     * Deserialization constructor.
     *
     * @param in      the DataInput to read from
     * @param aconst  an array of constants used within the method
     */
    public L_Get(DataInput in, Constant[] aconst)
            throws IOException
        {
        super(readPackedInt(in));
        m_nRetValue    = readPackedInt(in);
        }

    @Override
    public void write(DataOutput out, ConstantRegistry registry)
            throws IOException
        {
        out.writeByte(OP_L_GET);
        writePackedLong(out, m_nPropId);
        writePackedLong(out, m_nRetValue);
        }

    @Override
    public int getOpCode()
        {
        return OP_L_GET;
        }

    @Override
    public int process(Frame frame, int iPC)
        {
        ObjectHandle hTarget = frame.getThis();

        PropertyConstant constProperty = (PropertyConstant)
                frame.f_context.f_pool.getConstant(m_nPropId);

        return hTarget.f_clazz.f_template.getPropertyValue(
                frame, hTarget, constProperty.getName(), m_nRetValue);
        }

    private int m_nRetValue;
    }
