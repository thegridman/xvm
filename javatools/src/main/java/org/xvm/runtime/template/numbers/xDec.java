package org.xvm.runtime.template.numbers;


import java.math.BigDecimal;
import java.math.MathContext;

import java.util.Arrays;

import org.xvm.asm.ClassStructure;
import org.xvm.runtime.Container;
import org.xvm.runtime.ObjectHandle;

import org.xvm.type.Decimal;
import org.xvm.type.Decimal64;


/**
 * Native Dec support.
 */
public class xDec
        extends BaseDecFP
    {
    public static xDec INSTANCE;

    public xDec(Container container, ClassStructure structure, boolean fInstance)
        {
        super(container, structure, 64);

        if (fInstance)
            {
            INSTANCE = this;
            }
        }

    // ----- helpers -------------------------------------------------------------------------------

    @Override
    protected Decimal fromDouble(double d)
        {
        try
            {
            return new Decimal64(new BigDecimal(d, MathContext.DECIMAL64));
            }
        catch (Decimal.RangeException e)
            {
            return e.getDecimal();
            }
        }

    @Override
    protected ObjectHandle makeHandle(byte[] abValue, int cBytes)
        {
        assert cBytes >= 8;
        if (cBytes > 8)
            {
            abValue = Arrays.copyOfRange(abValue, 0, 8);
            }
        return makeHandle(new Decimal64(abValue));
        }
    }