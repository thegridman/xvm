package org.xvm.asm.constants;


import java.util.function.Consumer;

import java.io.DataInput;
import java.io.DataOutput;
import java.io.IOException;

import org.xvm.asm.Constant;
import org.xvm.asm.ConstantPool;

import static org.xvm.util.Handy.readMagnitude;
import static org.xvm.util.Handy.writePackedLong;


/**
 * Represent a constant value that contains a number of other constant values. Specifically this
 * supports the array, tuple, and set types.
 */
public class ArrayConstant
        extends ValueConstant
    {
    // ----- constructors --------------------------------------------------------------------------

    /**
     * Constructor used for deserialization.
     *
     * @param pool    the ConstantPool that will contain this Constant
     * @param format  the format of the Constant in the stream
     * @param in      the DataInput stream to read the Constant value from
     *
     * @throws IOException  if an issue occurs reading the Constant value
     */
    public ArrayConstant(ConstantPool pool, Format format, DataInput in)
            throws IOException
        {
        super(pool);

        int iType = readMagnitude(in);
        int cVals = readMagnitude(in);
        int[] aiVal = new int[cVals];
        for (int i = 0; i < cVals; ++i)
            {
            aiVal[i] = readMagnitude(in);
            }

        m_iType = iType;
        m_aiVal = aiVal;
        }

    /**
     * Construct a constant whose value is an array, tuple, or set.
     *
     * @param pool       the ConstantPool that will contain this Constant
     * @param fmt        the format of the constant
     * @param constType  the data type of the constant
     * @param aconstVal  the value of the constant
     */
    public ArrayConstant(ConstantPool pool, Format fmt, TypeConstant constType, Constant... aconstVal)
        {
        super(pool);
        validateFormatAndType(fmt, constType);

        if (aconstVal == null)
            {
            throw new IllegalArgumentException("value required");
            }

        m_fmt       = fmt;
        m_constType = constType;
        m_aconstVal = aconstVal;
        }

    private void validateFormatAndType(Format fmt, TypeConstant constType)
        {
        if (fmt == null)
            {
            throw new IllegalArgumentException("format required");
            }
        String sClassName;
        switch (fmt)
            {
            case Array:
                sClassName = X_CLASS_ARRAY;
                break;
            case Tuple:
                sClassName = X_CLASS_TUPLE;
                break;
            case Set:
                sClassName = X_CLASS_SET;
                break;

            default:
                throw new IllegalArgumentException("unsupported format: " + fmt);
            }

        if (constType == null)
            {
            throw new IllegalArgumentException("type required");
            }
        if (constType instanceof ImmutableTypeConstant)
            {
            constType = ((ImmutableTypeConstant) constType).getType();
            }
        if (!(constType instanceof ClassTypeConstant)
                || !(((ClassTypeConstant) constType).getClassConstant() instanceof ClassConstant))
            {
            throw new IllegalArgumentException("type must be a class type");
            }
        ClassConstant constClass = (ClassConstant) ((ClassTypeConstant) constType).getClassConstant();
        if (!(constClass.isEcstasyClass(sClassName)))
            {
            throw new IllegalArgumentException("type for " + fmt + " must be " + sClassName
                    + " (unsupported type: " + constType + ")");
            }
        }


    // ----- ValueConstant methods -----------------------------------------------------------------

    @Override
    public TypeConstant getType()
        {
        return m_constType;
        }

    /**
     * {@inheritDoc}
     * @return  the constant's contents as an array of constants
     */
    @Override
    public Constant[] getValue()
        {
        return m_aconstVal;
        }


    // ----- Constant methods ----------------------------------------------------------------------

    @Override
    public Format getFormat()
        {
        return m_fmt;
        }

    @Override
    public void forEachUnderlying(Consumer<Constant> visitor)
        {
        visitor.accept(m_constType);
        Constant[] aconst = m_aconstVal;
        for (int i = 0, c = aconst.length; i < c; ++i)
            {
            visitor.accept(aconst[i]);
            }
        }

    @Override
    protected int compareDetails(Constant that)
        {
        int nResult = this.m_constType.compareTo(((ArrayConstant) that).m_constType);
        if (nResult != 0)
            {
            return nResult;
            }

        Constant[] aconstThis = this.m_aconstVal;
        Constant[] aconstThat = ((ArrayConstant) that).m_aconstVal;
        int cThis = aconstThis.length;
        int cThat = aconstThat.length;
        for (int i = 0, c = Math.min(cThis, cThat); i < c; ++i)
            {
            nResult = aconstThis[i].compareTo(aconstThat[i]);
            if (nResult != 0)
                {
                return nResult;
                }
            }
        return cThis - cThat;
        }

    @Override
    public String getValueString()
        {
        Constant[] aconst  = m_aconstVal;
        int        cConsts = aconst.length;

        String sStart;
        String sEnd;
        switch (m_fmt)
            {
            case Array:
                sStart = "{";
                sEnd   = "}";
                break;
            case Tuple:
                sStart = cConsts < 2 ? "Tuple:(" : "(";
                sEnd   = ")";
                break;
            case Set:
                sStart = "Set:{";
                sEnd   = "}";
                break;

            default:
                throw new IllegalArgumentException("illegal format: " + m_fmt);
            }

        StringBuilder sb = new StringBuilder();
        sb.append(sStart);

        for (int i = 0; i < cConsts; ++i)
            {
            if (i > 0)
                {
                sb.append(", ");
                }

            sb.append(aconst[i]);
            }

        sb.append(sEnd);
        return sb.toString();
        }


    // ----- XvmStructure methods ------------------------------------------------------------------

    @Override
    protected void disassemble(DataInput in)
            throws IOException
        {
        final ConstantPool pool = getConstantPool();
        m_constType = (TypeConstant) pool.getConstant(m_iType);

        int[]      aiConst = m_aiVal;
        int        cConsts = aiConst.length;
        Constant[] aconst  = new Constant[cConsts];
        for (int i = 0; i < cConsts; ++i)
            {
            aconst[i] = pool.getConstant(aiConst[i]);
            }
        m_aconstVal = aconst;
        }

    @Override
    protected void registerConstants(ConstantPool pool)
        {
        m_constType = (TypeConstant) pool.register(m_constType);

        Constant[] aconst = m_aconstVal;
        for (int i = 0, c = aconst.length; i < c; ++i)
            {
            aconst[i] = pool.register(aconst[i]);
            }
        }

    @Override
    protected void assemble(DataOutput out)
            throws IOException
        {
        out.writeByte(getFormat().ordinal());
        writePackedLong(out, m_constType.getPosition());
        Constant[] aconst  = m_aconstVal;
        int        cConsts = aconst.length;
        writePackedLong(out, cConsts);
        for (int i = 0; i < cConsts; ++i)
            {
            writePackedLong(out, aconst[i].getPosition());
            }
        }

    @Override
    public String getDescription()
        {
        return "array-length=" + m_aconstVal.length;
        }


    // ----- Object methods ------------------------------------------------------------------------

    @Override
    public int hashCode()
        {
        int nHash = m_nHash;
        if (nHash == 0)
            {
            Constant[] aconst = m_aconstVal;
            nHash = aconst.length;
            for (int of = 0, cb = aconst.length, cbInc = Math.max(1, cb >>> 6); of < cb; of += cbInc)
                {
                nHash *= 19 + aconst[of].hashCode();
                }
            m_nHash = nHash;
            }
        return nHash;
        }


    // ----- fields --------------------------------------------------------------------------------

    /**
     * Holds the indexes of the type during deserialization.
     */
    private transient int m_iType;

    /**
     * Holds the indexes of the constant values during deserialization.
     */
    private transient int[] m_aiVal;

    /**
     * The constant format.
     */
    private Format m_fmt;

    /**
     * The type represented by this constant. Note that this is not the element type, but rather is
     * the type of the array, tuple, or set.
     */
    private TypeConstant m_constType;

    /**
     * The values in the array, tuple, or set.
     */
    private Constant[] m_aconstVal;

    /**
     * Cached hash code.
     */
    private transient int m_nHash;
    }

