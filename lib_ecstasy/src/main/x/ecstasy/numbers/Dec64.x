const Dec64
        extends DecimalFPNumber
        default(0.0) {
    // ----- constructors --------------------------------------------------------------------------

    /**
     * Construct a 64-bit decimal floating point number from its bitwise machine representation.
     *
     * @param bits  an array of bit values that represent this number, ordered from left-to-right,
     *              Most Significant Bit (MSB) to Least Significant Bit (LSB)
     */
    @Override
    construct(Bit[] bits) {
        assert:bounds bits.size == 64;
        super(bits);
    }

    /**
     * Construct a 64-bit decimal floating point number from its network-portable representation.
     *
     * @param bytes  an array of byte values that represent this number, ordered from left-to-right,
     *               as they would appear on the wire or in a file
     */
    @Override
    construct(Byte[] bytes) {
        assert:bounds bytes.size == 8;
        super(bytes);
    }

    /**
     * Construct a 64-bit decimal floating point number from its `String` representation.
     *
     * @param text  a floating point number, in text format
     */
    @Override
    construct(String text) {
        construct Dec64(new FPLiteral(text).toDec64().bits);
    }


    // ----- Numeric funky interface ---------------------------------------------------------------

    @Override
    static conditional Int fixedBitLength() {
        return True, 64;
    }

    @Override
    static Dec64 zero() {
        return 0.0;
    }

    @Override
    static Dec64 one() {
        return 1.0;
    }


    // ----- Number operations ---------------------------------------------------------------------

    @Override
    @Op Dec64 add(Dec64 n) {
        TODO
    }

    @Override
    @Op Dec64 sub(Dec64 n) {
        TODO
    }

    @Override
    @Op Dec64 mul(Dec64 n) {
        TODO
    }

    @Override
    @Op Dec64 div(Dec64 n) {
        TODO
    }

    @Override
    @Op Dec64 mod(Dec64 n) {
        TODO
    }

    @Override
    Dec64 abs() {
        return this < 0 ? -this : this;
    }

    @Override
    @Op Dec64 neg() {
        TODO
    }

    @Override
    Dec64 pow(Dec64 n) {
        TODO
    }


    // ----- FPNumber properties -------------------------------------------------------------------

    @Override
    @RO Int emax.get() {
        return 384;
    }

    @Override
    Int emin.get() {
        return 1 - emax;
    }

    @Override
    Int bias.get() {
        return 398;
    }


    // ----- FPNumber operations -------------------------------------------------------------------

    @Override
    (Boolean negative, Int significand, Int exponent) split() {
        TODO
    }

    @Override
    Dec64 round(Rounding direction = TiesToAway) {
        TODO
    }

    @Override
    Dec64 floor() {
        TODO
    }

    @Override
    Dec64 ceil() {
        TODO
    }

    @Override
    Dec64 exp() {
        TODO
    }

    @Override
    Dec64 scaleByPow(Int n) {
        TODO
    }

    @Override
    Dec64 log() {
        TODO
    }

    @Override
    Dec64 log2() {
        TODO
    }

    @Override
    Dec64 log10() {
        TODO
    }

    @Override
    Dec64 sqrt() {
        TODO
    }

    @Override
    Dec64 cbrt() {
        TODO
    }

    @Override
    Dec64 sin() {
        TODO
    }

    @Override
    Dec64 cos() {
        TODO
    }

    @Override
    Dec64 tan() {
        TODO
    }

    @Override
    Dec64 asin() {
        TODO
    }

    @Override
    Dec64 acos() {
        TODO
    }

    @Override
    Dec64 atan() {
        TODO
    }

    @Override
    Dec64 atan2(Dec64 y) {
        TODO
    }

    @Override
    Dec64 sinh() {
        TODO
    }

    @Override
    Dec64 cosh() {
        TODO
    }

    @Override
    Dec64 tanh() {
        TODO
    }

    @Override
    Dec64 asinh() {
        TODO
    }

    @Override
    Dec64 acosh() {
        TODO
    }

    @Override
    Dec64 atanh() {
        TODO
    }

    @Override
    Dec64 deg2rad() {
        TODO
    }

    @Override
    Dec64 rad2deg() {
        TODO
    }

    @Override
    Dec64 nextUp() {
        TODO
    }

    @Override
    Dec64 nextDown() {
        TODO
    }


    // ----- conversions ---------------------------------------------------------------------------

    @Override
    Int8 toInt8(Boolean truncate = False, Rounding direction = TowardZero);

    @Override
    Int16 toInt16(Boolean truncate = False, Rounding direction = TowardZero);

    @Override
    Int32 toInt32(Boolean truncate = False, Rounding direction = TowardZero);

    @Override
    Int64 toInt64(Boolean truncate = False, Rounding direction = TowardZero);

    @Override
    Int128 toInt128(Boolean truncate = False, Rounding direction = TowardZero);

    @Override
    IntN toIntN(Rounding direction = TowardZero) {
        return round(direction).toIntN();
    }

    @Override
    UInt8 toUInt8(Boolean truncate = False, Rounding direction = TowardZero);

    @Override
    UInt16 toUInt16(Boolean truncate = False, Rounding direction = TowardZero);

    @Override
    UInt32 toUInt32(Boolean truncate = False, Rounding direction = TowardZero);

    @Override
    UInt64 toUInt64(Boolean truncate = False, Rounding direction = TowardZero);

    @Override
    UInt128 toUInt128(Boolean truncate = False, Rounding direction = TowardZero);

    @Override
    UIntN toUIntN(Rounding direction = TowardZero) {
        return round(direction).toUIntN();
    }

    @Override
    Float8e4 toFloat8e4();

    @Override
    Float8e5 toFloat8e5();

    @Override
    BFloat16 toBFloat16();

    @Override
    Float16 toFloat16();

    @Override
    Float32 toFloat32();

    @Override
    Float64 toFloat64();

    @Auto
    @Override
    Float128 toFloat128();

    @Auto
    @Override
    FloatN toFloatN() {
        return toFPLiteral().toFloatN();
    }

    @Override
    Dec32 toDec32();

    @Override
    Dec64 toDec64() {
        return this;
    }

    @Auto
    @Override
    Dec128 toDec128();

    @Auto
    @Override
    DecN toDecN() {
        return new DecN(bits);
    }
}