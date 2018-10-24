package org.xvm.asm.op;


import java.io.DataInput;
import java.io.IOException;

import org.xvm.asm.Argument;
import org.xvm.asm.Constant;
import org.xvm.asm.OpInPlaceAssign;

import org.xvm.runtime.Frame;
import org.xvm.runtime.ObjectHandle;

import org.xvm.runtime.template.xRef.RefHandle;


/**
 * IP_SHL rvalue-target, rvalue2 ; T <<= T
 */
public class IP_Shl
        extends OpInPlaceAssign
    {
    /**
     * Construct a IP_SHL op based on the passed arguments.
     *
     * @param argTarget  the target Argument
     * @param argValue   the value Argument
     */
    public IP_Shl(Argument argTarget, Argument argValue)
        {
        super(argTarget, argValue);
        }

    /**
     * Deserialization constructor.
     *
     * @param in      the DataInput to read from
     * @param aconst  an array of constants used within the method
     */
    public IP_Shl(DataInput in, Constant[] aconst)
            throws IOException
        {
        super(in, aconst);
        }

    @Override
    public int getOpCode()
        {
        return OP_IP_SHL;
        }

    @Override
    protected int completeWithRegister(Frame frame, ObjectHandle hTarget, ObjectHandle hValue)
        {
        return hTarget.getOpSupport().invokeShl(frame, hTarget, hValue, m_nTarget);
        }

    @Override
    protected int completeWithVar(Frame frame, RefHandle hTarget, ObjectHandle hValue)
        {
        return hTarget.getVarSupport().invokeVarShl(frame, hTarget, hValue);
        }

    @Override
    protected int completeWithProperty(Frame frame, ObjectHandle hTarget, String sProperty, ObjectHandle hValue)
        {
        return hTarget.getTemplate().invokePropertyShl(frame, hTarget, sProperty, hValue);
        }
    }