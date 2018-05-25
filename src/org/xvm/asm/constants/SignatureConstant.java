package org.xvm.asm.constants;


import java.io.DataInput;
import java.io.DataOutput;
import java.io.IOException;

import java.util.Arrays;
import java.util.List;

import java.util.function.Consumer;

import org.xvm.asm.Constant;
import org.xvm.asm.ConstantPool;
import org.xvm.asm.GenericTypeResolver;

import static org.xvm.util.Handy.readMagnitude;
import static org.xvm.util.Handy.writePackedLong;


/**
 * Represent a method signature constant. A signature constant identifies a method's call signature
 * for the purpose of invocation; in other words, it specifies what name, parameters, and return
 * values a method must have in order to be selected for invocation. This is particularly useful for
 * supporting virtual method invocation with auto-narrowing types, as the invocation site does not
 * have to specify which exact method is being invoked (such as a particular method on a particular
 * class), but rather that some virtual method chain exists such that it matches a particular
 * signature.
 * <p/>
 * In Ecstasy, a type is simply a collection of methods and properties. Even properties can be
 * expressed as methods; a property of type T and name N can be represented as a method N that takes
 * no parameters and returns a single value of type T. As such, a type can represented as a
 * collection of method signatures.
 * <p/>
 * Method signatures are not necessarily exact, however. Consider the support in Ecstasy for auto-
 * narrowing types:
 * <p/>
 * <code><pre>
 *     interface I
 *         {
 *         I foo();
 *         void bar(I i);
 *         }
 * </pre></code>
 * <p/>
 * Now consider a class:
 * <p/>
 * <code><pre>
 *     class C
 *         {
 *         C! foo() {...}
 *         void bar(C! c) {...}
 *         }
 * </pre></code>
 * <p/>
 * While the class does not explicitly implement the interface I, and while the methods on the class
 * are explicit (not auto-narrowing), the class C does implicitly implement interface I, and thus an
 * instance of C can be passed to (or returned from) any method that accepts (or returns) an "I".
 * <p/>
 * A SignatureConstant can also be used to represent a property, but such a use is never serialized;
 * i.e. it is a transient use case.
 */
public class SignatureConstant
        extends PseudoConstant
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
    public SignatureConstant(ConstantPool pool, Format format, DataInput in)
            throws IOException
        {
        super(pool);
        m_iName     = readMagnitude(in);
        m_aiReturns = readMagnitudeArray(in);
        m_aiParams  = readMagnitudeArray(in);
        }

    /**
     * Construct a constant whose value is a method signature identifier.
     *
     * @param pool     the ConstantPool that will contain this Constant
     * @param sName    the name of the method
     * @param params   the param types
     * @param returns  the return types
     */
    public SignatureConstant(ConstantPool pool, String sName, TypeConstant[] params, TypeConstant[] returns)
        {
        super(pool);

        if (sName == null)
            {
            throw new IllegalArgumentException("name required");
            }

        m_constName     = pool.ensureStringConstant(sName);
        m_aconstParams  = validateTypes(params);
        m_aconstReturns = validateTypes(returns);
        }

    /**
     * Construct a constant whose value is a property signature identifier.
     * <p/>
     * This use case allows methods and properties to both be represented in a transient data
     * structure as SignatureConstants; this form of a SignatureConstant cannot be serialized.
     *
     * @param pool           the ConstantPool that will contain this Constant
     * @param constProperty  the property
     */
    public SignatureConstant(ConstantPool pool, PropertyConstant constProperty)
        {
        super(pool);

        if (constProperty == null)
            {
            throw new IllegalArgumentException("property required");
            }

        m_constName     = pool.ensureStringConstant(constProperty.getName());
        m_aconstParams  = ConstantPool.NO_TYPES;
        m_aconstReturns = new TypeConstant[] {constProperty.getType()};
        m_fProperty     = true;
        }


    // ----- type-specific functionality -----------------------------------------------------------

    /**
     * @return the name of the method specified by this signature
     */
    public String getName()
        {
        return m_constName.getValue();
        }

    /**
     * @return the method's parameter types
     */
    public TypeConstant[] getRawParams()
        {
        return m_aconstParams;
        }

    /**
     * @return the method's parameter types
     */
    public List<TypeConstant> getParams()
        {
        return Arrays.asList(m_aconstParams);
        }

    /**
     * @return the method's return types
     */
    public TypeConstant[] getRawReturns()
        {
        return m_aconstReturns;
        }

    /**
     * @return the method's return types
     */
    public List<TypeConstant> getReturns()
        {
        return Arrays.asList(m_aconstReturns);
        }

    /**
     * @return whether this signature represents a property
     */
    public boolean isProperty()
        {
        return m_fProperty;
        }

    /**
     * @return an equivalent signature without any generic types
     */
    public SignatureConstant resolveGenericTypes(GenericTypeResolver resolver)
        {
        TypeConstant[] aconstParamOriginal = m_aconstParams;
        TypeConstant[] aconstParamResolved = null;
        for (int i = 0, c = aconstParamOriginal.length; i < c; ++i)
            {
            TypeConstant constOriginal = aconstParamOriginal[i];
            TypeConstant constResolved = constOriginal.resolveGenerics(resolver);
            if (constOriginal != constResolved)
                {
                if (aconstParamResolved == null)
                    {
                    aconstParamResolved = new TypeConstant[c];
                    System.arraycopy(aconstParamOriginal, 0, aconstParamResolved, 0, c);
                    }
                aconstParamResolved[i] = constResolved;
                }
            }

        TypeConstant[] aconstReturnOriginal = m_aconstReturns;
        TypeConstant[] aconstReturnResolved = null;
        for (int i = 0, c = aconstReturnOriginal.length; i < c; ++i)
            {
            TypeConstant constOriginal = aconstReturnOriginal[i];
            TypeConstant constResolved = constOriginal.resolveGenerics(resolver);
            if (constOriginal != constResolved)
                {
                if (aconstReturnResolved == null)
                    {
                    aconstReturnResolved = new TypeConstant[c];
                    System.arraycopy(aconstReturnOriginal, 0, aconstReturnResolved, 0, c);
                    }
                aconstReturnResolved[i] = constResolved;
                }
            }

        if (aconstParamResolved == null && aconstReturnResolved == null)
            {
            return this;
            }

        if (aconstParamResolved == null)
            {
            aconstParamResolved = aconstParamOriginal;
            }
        if (aconstReturnResolved == null)
            {
            aconstReturnResolved = aconstReturnOriginal;
            }

        return getConstantPool().
            ensureSignatureConstant(getName(), aconstParamResolved, aconstReturnResolved);
        }

    /**
     * If any of the signature components are auto-narrowing (or have any references to auto-narrowing
     * types), replace the any auto-narrowing portion with an explicit class identity.
     *
     * @return the SignatureConstant with explicit identities swapped in for any auto-narrowing
     *         identities
     */
    public SignatureConstant resolveAutoNarrowing()
        {
        TypeConstant[] aconstParamOriginal = m_aconstParams;
        TypeConstant[] aconstParamResolved = null;
        for (int i = 0, c = aconstParamOriginal.length; i < c; ++i)
            {
            TypeConstant constOriginal = aconstParamOriginal[i];
            TypeConstant constResolved = constOriginal.resolveAutoNarrowing();
            if (constOriginal != constResolved)
                {
                if (aconstParamResolved == null)
                    {
                    aconstParamResolved = new TypeConstant[c];
                    System.arraycopy(aconstParamOriginal, 0, aconstParamResolved, 0, c);
                    }
                aconstParamResolved[i] = constResolved;
                }
            }

        TypeConstant[] aconstReturnOriginal = m_aconstReturns;
        TypeConstant[] aconstReturnResolved = null;
        for (int i = 0, c = aconstReturnOriginal.length; i < c; ++i)
            {
            TypeConstant constOriginal = aconstReturnOriginal[i];
            TypeConstant constResolved = constOriginal.resolveAutoNarrowing();
            if (constOriginal != constResolved)
                {
                if (aconstReturnResolved == null)
                    {
                    aconstReturnResolved = new TypeConstant[c];
                    System.arraycopy(aconstReturnOriginal, 0, aconstReturnResolved, 0, c);
                    }
                aconstReturnResolved[i] = constResolved;
                }
            }

        if (aconstParamResolved == null && aconstReturnResolved == null)
            {
            return this;
            }

        if (aconstParamResolved == null)
            {
            aconstParamResolved = aconstParamOriginal;
            }
        if (aconstReturnResolved == null)
            {
            aconstReturnResolved = aconstReturnOriginal;
            }

        return getConstantPool().
            ensureSignatureConstant(getName(), aconstParamResolved, aconstReturnResolved);
        }

    /**
     * Check if this signature could be called via the specified signature.
     *
     * @param that      the signature of the matching method (resolved)
     * @param resolver  the generic type resolver
     */
    public boolean isSubstitutableFor(SignatureConstant that, GenericTypeResolver resolver)
        {
        /*
         * From Method.x # isSubstitutableFor() (where m2 == this and m1 == that)
         *
         * 1. for each _m1_ in _M1_, there exists an _m2_ in _M2_ for which all of the following hold
         *    true:
         *    1. _m1_ and _m2_ have the same name
         *    2. _m1_ and _m2_ have the same number of parameters, and for each parameter type _p1_ of
         *       _m1_ and _p2_ of _m2_, at least one of the following holds true:
         *       1. _p1_ is assignable to _p2_
         *       2. both _p1_ and _p2_ are (or are resolved from) the same type parameter, and both of
         *          the following hold true:
         *          1. _p2_ is assignable to _p1_
         *          2. _T1_ produces _p1_
         *    3. _m1_ and _m2_ have the same number of return values, and for each return type _r1_ of
         *       _m1_ and _r2_ of _m2_, the following holds true:
         *      1. _r2_ is assignable to _r1_
         */

        // Note, that rule 1.2.2 does not apply in our case (duck typing)

        // number of param types and return values must match
        // REVIEW consider relaxing this later, i.e. allow sub-classes to add return values
        if (!this.getName().equals(that.getName())
                || this.getRawParams().length != that.getRawParams().length
                || this.getRawReturns().length != that.getRawReturns().length)
            {
            return false;
            }

        SignatureConstant sigM1 = that;
        SignatureConstant sigM2 = resolver == null ? this : this.resolveGenericTypes(resolver);

        TypeConstant[] aR1 = sigM1.getRawReturns();
        TypeConstant[] aR2 = sigM2.getRawReturns();
        for (int i = 0, c = aR1.length; i < c; i++)
            {
            if (!aR2[i].isA(aR1[i]))
                {
                return false;
                }
            }

        TypeConstant[] aP1 = sigM1.getRawParams();
        TypeConstant[] aP2 = sigM2.getRawParams();
        for (int i = 0, c = aP1.length; i < c; i++)
            {
            if (!aP1[i].isA(aP2[i]))
                {
                return false;
                }
            }

        return true;
        }

    /**
     * Determine if this SignatureConstant is an unambiguously better fit as a "super" of the
     * specified SignatureConstant when compared to another potential "super" SignatureConstant.
     *
     * @param that     the other potential "super" SignatureConstant
     *
     * @param sigSub   the SignatureConstant of the method that is calling super
     * @param typeSub  the type within which the potential super call would occur
     * @return true iff this signature is an unambiguously better "super" than that signature
     */
    public boolean isUnambiguouslyBetterSuperThan(SignatureConstant that, SignatureConstant sigSub,
            TypeConstant typeSub)
        {
        // these assertions can eventually be removed
        assert this.isSubstitutableFor(sigSub, typeSub);
        assert that.isSubstitutableFor(sigSub, typeSub);

        // TODO handle auto-narrowing

        TypeConstant[] aThisParam = this.getRawParams();
        TypeConstant[] aThatParam = that.getRawParams();
        for (int i = 0, c = aThisParam.length; i < c; ++i)
            {
            if (!aThisParam[i].isA(aThatParam[i]))
                {
                return false;
                }
            }

        TypeConstant[] aThisReturn = this.getRawReturns();
        TypeConstant[] aThatReturn = that.getRawReturns();
        for (int i = 0, c = aThisReturn.length; i < c; ++i)
            {
            if (!aThisReturn[i].isA(aThatReturn[i]))
                {
                return false;
                }
            }

        return true;
        }

    /**
     * @return the type of the function that corresponds to this SignatureConstant
     */
    public TypeConstant asFunctionType()
        {
        ConstantPool pool = getConstantPool();
        return pool.ensureParameterizedTypeConstant(pool.typeFunction(),
                pool.ensureParameterizedTypeConstant(pool.typeTuple(), m_aconstParams),
                pool.ensureParameterizedTypeConstant(pool.typeTuple(), m_aconstReturns));
        }


    // ----- Constant methods ----------------------------------------------------------------------

    @Override
    public Format getFormat()
        {
        return Format.Signature;
        }

    @Override
    public boolean containsUnresolved()
        {
        if (m_constName.containsUnresolved())
            {
            return true;
            }
        for (Constant constant : m_aconstParams)
            {
            if (constant.containsUnresolved())
                {
                return true;
                }
            }
        for (Constant constant : m_aconstReturns)
            {
            if (constant.containsUnresolved())
                {
                return true;
                }
            }
        return false;
        }

    @Override
    public void forEachUnderlying(Consumer<Constant> visitor)
        {
        visitor.accept(m_constName);
        for (TypeConstant constant : m_aconstParams)
            {
            visitor.accept(constant);
            }
        for (TypeConstant constant : m_aconstReturns)
            {
            visitor.accept(constant);
            }
        }

    @Override
    public SignatureConstant resolveTypedefs()
        {
        // params
        TypeConstant[] atypeOldParams = m_aconstParams;
        TypeConstant[] atypeNewParams = null;
        for (int i = 0, c = atypeOldParams.length; i < c; ++i)
            {
            TypeConstant constOld = atypeOldParams[i];
            TypeConstant constNew = constOld.resolveTypedefs();
            if (constNew != constOld)
                {
                if (atypeNewParams == null)
                    {
                    atypeNewParams = atypeOldParams.clone();
                    }
                atypeNewParams[i] = constNew;
                }
            }

        // returns
        TypeConstant[] atypeOldReturns = m_aconstReturns;
        TypeConstant[] atypeNewReturns = null;
        for (int i = 0, c = atypeOldReturns.length; i < c; ++i)
            {
            TypeConstant constOld = atypeOldReturns[i];
            TypeConstant constNew = constOld.resolveTypedefs();
            if (constNew != constOld)
                {
                if (atypeNewReturns == null)
                    {
                    atypeNewReturns = atypeOldReturns.clone();
                    }
                atypeNewReturns[i] = constNew;
                }
            }

        return atypeNewParams == null && atypeNewReturns == null
                ? this
                : getConstantPool().ensureSignatureConstant(getName(), atypeNewParams, atypeNewReturns);
        }

    @Override
    protected int compareDetails(Constant obj)
        {
        SignatureConstant that = (SignatureConstant) obj;
        int n = this.m_constName.compareTo(that.m_constName);
        if (n == 0)
            {
            n = compareTypes(this.m_aconstParams, that.m_aconstParams);
            if (n == 0)
                {
                n = compareTypes(this.m_aconstReturns, that.m_aconstReturns);
                if (n == 0)
                    {
                    n = (this.m_fProperty ? 1 : 0) - (that.m_fProperty ? 1 : 0);
                    }
                }
            }
        return n;
        }

    @Override
    public String getValueString()
        {
        StringBuilder sb = new StringBuilder();

        switch (m_aconstReturns.length)
            {
            case 0:
                sb.append("void");
                break;

            case 1:
                sb.append(m_aconstReturns[0].getValueString());
                break;

            default:
                sb.append('(');
                boolean first = true;
                for (TypeConstant type : m_aconstReturns)
                    {
                    if (first)
                        {
                        first = false;
                        }
                    else
                        {
                        sb.append(", ");
                        }
                    sb.append(type.getValueString());
                    }
                sb.append(')');
                break;
            }

        sb.append(' ')
          .append(m_constName.getValue());

        if (!m_fProperty)
            {
            sb.append('(');

            boolean first = true;
            for (TypeConstant type : m_aconstParams)
                {
                if (first)
                    {
                    first = false;
                    }
                else
                    {
                    sb.append(", ");
                    }
                sb.append(type.getValueString());
                }

            sb.append(')');
            }

        return sb.toString();
        }


    // ----- XvmStructure methods ------------------------------------------------------------------

    @Override
    protected void disassemble(DataInput in)
            throws IOException
        {
        ConstantPool pool = getConstantPool();
        m_constName     = (StringConstant) pool.getConstant(m_iName);
        m_aconstParams  = lookupTypes(pool, m_aiParams);
        m_aconstReturns = lookupTypes(pool, m_aiReturns);

        m_aiReturns = null;
        m_aiParams  = null;
        }

    @Override
    protected void registerConstants(ConstantPool pool)
        {
        m_constName = (StringConstant) pool.register(m_constName);
        registerTypes(pool, m_aconstParams);
        registerTypes(pool, m_aconstReturns);
        }

    @Override
    protected void assemble(DataOutput out)
            throws IOException
        {
        if (m_fProperty)
            {
            throw new IllegalStateException("Signature refers to a property");
            }

        out.writeByte(getFormat().ordinal());
        writePackedLong(out, m_constName.getPosition());
        writeTypes(out, m_aconstParams);
        writeTypes(out, m_aconstReturns);
        }

    @Override
    public String getDescription()
        {
        return "name=" + getName()
                + ", params=" + formatTypes(m_aconstParams)
                + ", returns=" + formatTypes(m_aconstReturns);
        }


    // ----- Object methods ------------------------------------------------------------------------

    @Override
    public int hashCode()
        {
        return (m_constName.hashCode() * 17 + m_aconstParams.length * 3) + m_aconstReturns.length;
        }


    // ----- helpers -------------------------------------------------------------------------------

    /**
     * Read a length encoded array of constant indexes.
     *
     * @param in  a DataInput stream to read from
     *
     * @return an array of integers, which are the indexes of the constants
     *
     * @throws IOException  if an error occurs attempting to read from the stream
     */
    protected static int[] readMagnitudeArray(DataInput in)
            throws IOException
        {
        int   c  = readMagnitude(in);
        int[] an = new int[c];
        for (int i = 0; i < c; ++i)
            {
            an[i] = readMagnitude(in);
            }
        return an;
        }

    /**
     * Convert the passed array of constant indexes into an array of type constants.
     *
     * @param pool  the ConstantPool
     * @param an    an array of constant indexes
     *
     * @return an array of type constants
     */
    protected static TypeConstant[] lookupTypes(ConstantPool pool, int[] an)
        {
        int c = an.length;
        TypeConstant[] aconst = new TypeConstant[c];
        for (int i = 0; i < c; ++i)
            {
            aconst[i] = (TypeConstant) pool.getConstant(an[i]);
            }
        return aconst;
        }

    /**
     * Register each of the type constants in the passed array.
     *
     * @param pool    the ConstantPool
     * @param aconst  an array of constants
     */
    protected static void registerTypes(ConstantPool pool, TypeConstant[] aconst)
        {
        for (int i = 0, c = aconst.length; i < c; ++i)
            {
            aconst[i] = (TypeConstant) pool.register(aconst[i]);
            }
        }

    /**
     * Write a length-encoded series of type constants to the specified stream.
     *
     * @param out     a DataOutput stream
     * @param aconst  an array of constants
     *
     * @throws IOException  if an error occurs while writing the type constants
     */
    protected static void writeTypes(DataOutput out, TypeConstant[] aconst)
            throws IOException
        {
        int c = aconst.length;
        writePackedLong(out, c);

        for (int i = 0; i < c; ++i)
            {
            writePackedLong(out, aconst[i].getPosition());
            }
        }

    /**
     * Internal helper to scan a type array for nulls.
     *
     * @param aconst  an array of TypeConstant; may be null
     *
     * @return a non-null array of TypeConstant, each element of which is non-null
     */
    protected static TypeConstant[] validateTypes(TypeConstant[] aconst)
        {
        if (aconst == null)
            {
            return ConstantPool.NO_TYPES;
            }

        for (TypeConstant constant : aconst)
            {
            if (constant == null)
                {
                throw new IllegalArgumentException("type required");
                }
            }

        return aconst;
        }

    /**
     * Compare two arrays of type constants for order, as per the rules described by
     * {@link Comparable}.
     *
     * @param aconstThis  the first array of type constants
     * @param aconstThat  the second array of type constants
     *
     * @return a negative, zero, or a positive integer, depending on if the first array is less
     *         than, equal to, or greater than the second array for purposes of ordering
     */
    protected static int compareTypes(TypeConstant[] aconstThis, TypeConstant[] aconstThat)
        {
        int cThis = aconstThis.length;
        int cThat = aconstThat.length;
        for (int i = 0, c = Math.min(cThis, cThat); i < c; ++i)
            {
            int n = aconstThis[i].compareTo(aconstThat[i]);
            if (n != 0)
                {
                return n;
                }
            }
        return cThis - cThat;
        }

    /**
     * Render an array of TypeConstant objects as a comma-delimited string containing those types.
     *
     * @param aconst  the array of type constants
     *
     * @return a parenthesized, comma-delimited string of types
     */
    protected static String formatTypes(TypeConstant[] aconst)
        {
        StringBuilder sb = new StringBuilder();
        sb.append('(');
        for (int i = 0, c = aconst.length; i < c; ++i)
            {
            if (i > 0)
                {
                sb.append(", ");
                }
            sb.append(aconst[i].getValueString());
            }
        sb.append(')');
        return sb.toString();
        }


    // ----- fields --------------------------------------------------------------------------------

    /**
     * During disassembly, this holds the index of the constant that specifies the name of this
     * method.
     */
    private int m_iName;

    /**
     * During disassembly, this holds the indexes of the type constants for the parameters.
     */
    private int[] m_aiParams;

    /**
     * During disassembly, this holds the indexes of the type constants for the return values.
     */
    private int[] m_aiReturns;

    /**
     * The constant that represents the parent of this method.
     */
    private StringConstant m_constName;

    /**
     * The invocation parameters of the method.
     */
    private TypeConstant[] m_aconstParams;

    /**
     * The return values from the method.
     */
    private TypeConstant[] m_aconstReturns;

    /**
     * An indicator that this signature refers to a property.
     */
    private transient boolean m_fProperty;
    }
