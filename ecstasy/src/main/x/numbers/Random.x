interface Random
    {
    /**
     * @return a random bit value
     */
    Bit bit();

    /**
     * @return the passed array with random bit values
     */
    void fill(Bit[] bits)
        {
        for (Int i = 0, Int c = bits.size; i < c; ++i)
            {
            bits[i] = bit();
            }
        }

    /**
     * @return a random boolean value
     */
    Boolean boolean()
        {
        return bit().toBoolean();
        }

    /**
     * @return a random byte value
     */
    Byte byte()
        {
        Bit[] bits = new Array<Bit>(8, _ -> bit());
        return new Byte(bits);
        }

    /**
     * @return the passed array with random byte values
     */
    void fill(Byte[] bytes)
        {
        for (Int i = 0, Int c = bytes.size; i < c; ++i)
            {
            bytes[i] = byte();
            }
        }

    /**
     * @return a random 64-bit signed integer value
     */
    Int int()
        {
        Bit[] bits = new Array<Bit>(64, _ -> bit());
        return new Int(bits);
        }

    /**
     * @return a random 64-bit signed integer value in the range `[0..max)`
     */
    Int int(Int max)
        {
        assert max > 0;
        return max == maxvalue ? int() & maxvalue : int() % (max + 1);
        }

    /**
     * @return a random 64-bit signed integer value within in the specified range
     */
    Int int(Range<Int> range)
        {
        // note: range.size is limited to Int64.maxvalue
        return range.effectiveLowerBound + int(range.size);
        }

    /**
     * @return a random 64-bit unsigned integer value
     */
    UInt uint()
        {
        Bit[] bits = new Array<Bit>(64, _ -> bit());
        return new UInt(bits);
        }

    /**
     * @return a random 64-bit signed integer value in the range `[0..max)`
     */
    UInt uint(UInt max)
        {
        assert max > 0;
        return max == maxvalue ? uint() : uint() % (max + 1);
        }

    /**
     * @return a random 64-bit unsigned integer value within in the specified range
     */
    UInt uint(Range<UInt> range)
        {
        // note: range.size is limited to Int64.maxvalue
        return range.effectiveLowerBound + uint(range.size);
        }

    /**
     * @return a random 64-bit decimal value in the range `[0..1)`.
     */
    Dec dec()
        {
        // 16 digits of precision
        static IntLiteral bound  = 10_000_000_000_000_000;
        static Dec        scalar = 1.0 / bound;
        return uint(bound).toDec64() * scalar;
        }

    /**
     * @return a random 64-bit binary floating point value in the range `[0..1)`.
     */
    Float float()
        {
        static Int   precision = 1 << 53;
        static Float scalar    = 1.0 / precision.toFloat64();

        // initialize only the least significant 53 bits of information; leave [0..10] blank
        Int n = new Int(new Array<Bit>(64, i -> {return i > 10 ? bit() : 0;}));
        return n.toFloat64() * scalar;
        }
    }