package org.xvm.runtime.template.numbers;


import java.math.BigInteger;

import org.xvm.asm.ClassStructure;
import org.xvm.asm.Constant;
import org.xvm.asm.MethodStructure;
import org.xvm.asm.Op;

import org.xvm.asm.constants.DecimalAutoConstant;
import org.xvm.asm.constants.DecimalConstant;

import org.xvm.runtime.ClassComposition;
import org.xvm.runtime.Frame;
import org.xvm.runtime.ObjectHandle;
import org.xvm.runtime.ObjectHandle.JavaLong;
import org.xvm.runtime.Container;
import org.xvm.runtime.TypeComposition;

import org.xvm.runtime.template.xBoolean;
import org.xvm.runtime.template.xEnum.EnumHandle;
import org.xvm.runtime.template.xException;
import org.xvm.runtime.template.xOrdered;

import org.xvm.runtime.template.collections.xArray;
import org.xvm.runtime.template.collections.xArray.Mutability;

import org.xvm.runtime.template.text.xString;

import org.xvm.type.Decimal;


/**
 * Base class for native DecimalFPNumber (Dec*) support.
 */
abstract public class BaseDecFP
        extends BaseFP
    {
    public BaseDecFP(Container container, ClassStructure structure, int cBits)
        {
        super(container, structure, cBits);
        }

    @Override
    public int createConstHandle(Frame frame, Constant constant)
        {
        if (constant instanceof DecimalConstant constDec)
            {
            return frame.pushStack(makeHandle(constDec.getValue()));
            }

        if (constant instanceof DecimalAutoConstant constDec)
            {
            // TODO GG: this is not right
            return frame.pushStack(makeHandle(constDec.getValue()));
            }

        return super.createConstHandle(frame, constant);
        }

    @Override
    public int invokeNativeGet(Frame frame, String sPropName, ObjectHandle hTarget, int iReturn)
        {
        Decimal dec = ((DecimalHandle) hTarget).getValue();

        switch (sPropName)
            {
            case "bits":
                return frame.assignValue(iReturn,
                    xArray.makeBitArrayHandle(dec.toByteArray(), f_cBits, Mutability.Constant));

            case "infinity":
                return frame.assignValue(iReturn, xBoolean.makeHandle(!dec.isFinite()));

            case "NaN":
                return frame.assignValue(iReturn, xBoolean.makeHandle(dec.isNaN()));
            }

        return super.invokeNativeGet(frame, sPropName, hTarget, iReturn);
        }

    @Override
    public int invokeNative1(Frame frame, MethodStructure method, ObjectHandle hTarget,
                             ObjectHandle hArg, int iReturn)
        {
        switch (method.getName())
            {
            case "add":
                return invokeAdd(frame, hTarget, hArg, iReturn);

            case "sub":
                return invokeSub(frame, hTarget, hArg, iReturn);

            case "mul":
                return invokeMul(frame, hTarget, hArg, iReturn);

            case "div":
                return invokeDiv(frame, hTarget, hArg, iReturn);

            case "mod":
                return invokeMod(frame, hTarget, hArg, iReturn);

            case "pow":
                {
                Decimal dec1 = ((DecimalHandle) hTarget).getValue();
                Decimal dec2 = ((DecimalHandle) hArg).getValue();

                return frame.assignValue(iReturn, makeHandle(dec1.pow(dec2)));
                }

            case "round":
                {
                Decimal dec   = ((DecimalHandle) hTarget).getValue();
                int     iMode = hArg == ObjectHandle.DEFAULT
                            ? 0
                            : ((EnumHandle) hArg).getOrdinal();

                return frame.assignValue(iReturn,
                    makeHandle(dec.round(Rounding.values()[iMode].getMode())));
                }

            case "scaleByPow":
                {
                Decimal dec  = ((DecimalHandle) hTarget).getValue();
                long    lPow = ((JavaLong) hArg).getValue();

                return frame.assignValue(iReturn, makeHandle(dec.pow((int) lPow)));
                }

            case "atan2":
                {
                Decimal dec1 = ((DecimalHandle) hTarget).getValue();
                Decimal dec2 = ((DecimalHandle) hArg).getValue();

                return frame.assignValue(iReturn, makeHandle(dec1.atan2(dec2)));
                }
            }

        return super.invokeNative1(frame, method, hTarget, hArg, iReturn);
        }

    @Override
    public int invokeNativeN(Frame frame, MethodStructure method, ObjectHandle hTarget,
                             ObjectHandle[] ahArg, int iReturn)
        {
        // hTarget could be null for a native function call
        Decimal dec = hTarget == null ? null : ((DecimalHandle) hTarget).getValue();
        switch (method.getName())
            {
            case "abs":
                return frame.assignValue(iReturn, makeHandle(dec.abs()));

            case "toFloat64":
                return dec.isFinite()
                    ? frame.assignValue(iReturn, xFloat64.INSTANCE.makeHandle(dec.toBigDecimal().doubleValue()))
                    : overflow(frame);

            case "toInt64":
                {
                ObjectHandle hTrunc = ahArg[0];            // TODO CP find all "hTrunc" and "fTruncate" and flip them to "check bounds"
                ObjectHandle hRound = ahArg[1];

                int iMode = hRound == ObjectHandle.DEFAULT
                    ? 3
                    : ((EnumHandle) hRound).getOrdinal();
                dec = dec.round(Rounding.values()[iMode].getMode());

                BigInteger n  = dec.toBigDecimal().unscaledValue();
                int        cb = (n.bitLength() + 7) / 8;
                if (cb <= 8)
                    {
                    return frame.assignValue(iReturn, xInt64.makeHandle(n.longValue()));
                    }

                return frame.raiseException(xException.outOfBounds(frame,
                        "Decimal value out of Int range: " + dec));
                }

            case "toIntN":
            case "toUIntN":
            case "toFloatN":
            case "toDecN":
                throw new UnsupportedOperationException(); // TODO

            case "neg":
                // same as invokeNeg()
                return frame.assignValue(iReturn, makeHandle(dec.neg()));

            case "floor":
                return frame.assignValue(iReturn, makeHandle(dec.floor()));

            case "ceil":
                return frame.assignValue(iReturn, makeHandle(dec.ceil()));

            case "exp":
                return frame.assignValue(iReturn, makeHandle(dec.exp()));

            case "log":
                return frame.assignValue(iReturn, makeHandle(dec.log()));

            case "log2":
                return frame.assignValue(iReturn, makeHandle(dec.log2()));

            case "log10":
                return frame.assignValue(iReturn, makeHandle(dec.log10()));

            case "sqrt":
                return frame.assignValue(iReturn, makeHandle(dec.sqrt()));

            case "cbrt":
                return frame.assignValue(iReturn, makeHandle(dec.cbrt()));

            case "sin":
                return frame.assignValue(iReturn, makeHandle(dec.sin()));

            case "tan":
                return frame.assignValue(iReturn, makeHandle(dec.tan()));

            case "asin":
                return frame.assignValue(iReturn, makeHandle(dec.asin()));

            case "acos":
                return frame.assignValue(iReturn, makeHandle(dec.acos()));

            case "atan":
                return frame.assignValue(iReturn, makeHandle(dec.atan()));

            case "sinh":
                return frame.assignValue(iReturn, makeHandle(dec.sinh()));

            case "cosh":
                return frame.assignValue(iReturn, makeHandle(dec.cosh()));

            case "tanh":
                return frame.assignValue(iReturn, makeHandle(dec.tanh()));

            case "asinh":
                return frame.assignValue(iReturn, makeHandle(dec.asinh()));

            case "acosh":
                return frame.assignValue(iReturn, makeHandle(dec.acosh()));

            case "atanh":
                return frame.assignValue(iReturn, makeHandle(dec.atanh()));

            case "deg2rad":
                return frame.assignValue(iReturn, makeHandle(dec.deg2rad()));

            case "rad2deg":
                return frame.assignValue(iReturn, makeHandle(dec.rad2deg()));

            case "nextUp":
                return frame.assignValue(iReturn, makeHandle(dec.nextUp()));

            case "nextDown":
                return frame.assignValue(iReturn, makeHandle(dec.nextDown()));

            }

        return super.invokeNativeN(frame, method, hTarget, ahArg, iReturn);
        }

    @Override
    public int invokeNativeNN(Frame frame, MethodStructure method, ObjectHandle hTarget, ObjectHandle[] ahArg, int[] aiReturn)
        {
        switch (method.getName())
            {
            case "split":
                {
                Decimal dec = ((DecimalHandle) hTarget).getValue();

                // TODO CP
                boolean fSign     = dec.isSigned();
                int     iExp      = 0;
                long    lMantissa = 0;
                return frame.assignValues(aiReturn, xBoolean.makeHandle(fSign),
                                          xInt64.makeHandle(lMantissa), xInt64.makeHandle(iExp));
                }
            }

        return super.invokeNativeNN(frame, method, hTarget, ahArg, aiReturn);
        }

    @Override
    public int invokeAdd(Frame frame, ObjectHandle hTarget, ObjectHandle hArg, int iReturn)
        {
        Decimal dec1 = ((DecimalHandle) hTarget).getValue();
        Decimal dec2 = ((DecimalHandle) hArg).getValue();

        return frame.assignValue(iReturn, makeHandle(dec1.add(dec2)));
        }

    @Override
    public int invokeSub(Frame frame, ObjectHandle hTarget, ObjectHandle hArg, int iReturn)
        {
        Decimal dec1 = ((DecimalHandle) hTarget).getValue();
        Decimal dec2 = ((DecimalHandle) hArg).getValue();

        return frame.assignValue(iReturn, makeHandle(dec1.subtract(dec2)));
        }

    @Override
    public int invokeMul(Frame frame, ObjectHandle hTarget, ObjectHandle hArg, int iReturn)
        {
        Decimal dec1 = ((DecimalHandle) hTarget).getValue();
        Decimal dec2 = ((DecimalHandle) hArg).getValue();

        return frame.assignValue(iReturn, makeHandle(dec1.multiply(dec2)));
        }

    @Override
    public int invokeDiv(Frame frame, ObjectHandle hTarget, ObjectHandle hArg, int iReturn)
        {
        Decimal dec1 = ((DecimalHandle) hTarget).getValue();
        Decimal dec2 = ((DecimalHandle) hArg).getValue();

        if (dec1.getSignum() == 0)
            {
            return overflow(frame);
            }

        return frame.assignValue(iReturn, makeHandle(dec1.divide(dec2)));
        }

    @Override
    public int invokeMod(Frame frame, ObjectHandle hTarget, ObjectHandle hArg, int iReturn)
        {
        Decimal dec1 = ((DecimalHandle) hTarget).getValue();
        Decimal dec2 = ((DecimalHandle) hArg).getValue();

        if (dec2.getSignum() <= 0)
            {
            return dec2.getSignum() == 0
                ? overflow(frame)
                : frame.raiseException("Modulus is negative: " + dec2);
            }

        return frame.assignValue(iReturn, makeHandle(dec1.mod(dec2)));
        }

    @Override
    public int invokeNeg(Frame frame, ObjectHandle hTarget, int iReturn)
        {
        Decimal dec = ((DecimalHandle) hTarget).getValue();

        return frame.assignValue(iReturn, makeHandle(dec.neg()));
        }


    // ----- comparison support --------------------------------------------------------------------

    @Override
    public int callCompare(Frame frame, TypeComposition clazz,
                           ObjectHandle hValue1, ObjectHandle hValue2, int iReturn)
        {
        DecimalHandle h1 = (DecimalHandle) hValue1;
        DecimalHandle h2 = (DecimalHandle) hValue2;

        return frame.assignValue(iReturn,
            xOrdered.makeHandle(h1.getValue().compareForObjectOrder(h2.getValue())));
        }

    @Override
    public boolean compareIdentity(ObjectHandle hValue1, ObjectHandle hValue2)
        {
        return ((DecimalHandle) hValue1).getValue().equals(((DecimalHandle) hValue2).getValue());
        }

    @Override
    protected int buildHashCode(Frame frame, TypeComposition clazz, ObjectHandle hTarget, int iReturn)
        {
        Decimal dec = ((DecimalHandle) hTarget).getValue();

        return frame.assignValue(iReturn, xInt64.makeHandle(dec.hashCode()));
        }

    @Override
    protected int callEstimateLength(Frame frame, ObjectHandle hTarget, int iReturn)
        {
        Decimal dec = ((DecimalHandle) hTarget).getValue();

        return frame.assignValue(iReturn, xInt64.makeHandle(dec.toString().length()));
        }

    @Override
    protected int callAppendTo(Frame frame, ObjectHandle hTarget, ObjectHandle hAppender, int iReturn)
        {
        Decimal dec = ((DecimalHandle) hTarget).getValue();

        return xString.callAppendTo(frame, xString.makeHandle(dec.toString()), hAppender, iReturn);
        }

    @Override
    protected int buildStringValue(Frame frame, ObjectHandle hTarget, int iReturn)
        {
        Decimal dec = ((DecimalHandle) hTarget).getValue();

        return frame.assignValue(iReturn, xString.makeHandle(dec.toString()));
        }


    // ----- helpers -------------------------------------------------------------------------------

    /**
     * Convert a long value into a handle for the type represented by this template.
     *
     * @return one of the {@link Op#R_NEXT} or {@link Op#R_EXCEPTION} values
     */
    public int convertLong(Frame frame, long lValue, int iReturn)
        {
        return frame.assignValue(iReturn, makeHandle((double) lValue));
        }

    /**
     * @return a decimal value for the specified double
     */
    abstract protected Decimal fromDouble(double d);


    // ----- handle --------------------------------------------------------------------------------

    @Override
    public DecimalHandle makeHandle(double d)
        {
        return makeHandle(fromDouble(d));
        }

    /**
     * @return an ObjectHandle based on the specified Decimal value
     */
    public DecimalHandle makeHandle(Decimal decValue)
        {
        return new DecimalHandle(getCanonicalClass(), decValue);
        }

    protected static class DecimalHandle
            extends ObjectHandle
        {
        protected DecimalHandle(ClassComposition clz, Decimal decValue)
            {
            super(clz);

            f_decValue = decValue;
            }

        public Decimal getValue()
            {
            return f_decValue;
            }

        @Override
        public int hashCode()
            {
            return f_decValue.hashCode();
            }

        @Override
        public int compareTo(ObjectHandle that)
            {
            return f_decValue.compareForObjectOrder(((DecimalHandle) that).f_decValue);
            }

        @Override
        public boolean equals(Object obj)
            {
            return obj instanceof DecimalHandle that &&
                    f_decValue.compareForObjectOrder(that.f_decValue) == 0;
            }

        @Override
        public String toString()
            {
            return super.toString() + f_decValue;
            }

        private final Decimal f_decValue;
        }
    }