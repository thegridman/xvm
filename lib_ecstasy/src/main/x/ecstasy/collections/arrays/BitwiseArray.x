import ecstasy.numbers.Bitwise;


/**
 * Functionality specific to arrays of integer numbers.
 */
mixin BitwiseArray<Element extends @Bitwise IntNumber>
        into Array<Element>
        extends NumberArray<Element> {

    construct() {
        toElement = Int.converterTo(Element);
    }

    /**
     * Converts Int values to Element values.
     */
    function Element (Int) toElement;


    // ----- vector operations ---------------------------------------------------------------------

    /**
     * For each value in this array, calculate the most significant (left-most) bit.
     *
     * @param inPlace (optional) pass True to specify that the operation should occur using `this`
     *                to hold the result, if possible
     *
     * @return the array containing the integer values representing the left-most (most significant)
     *         bit of each integer value in this array
     */
    BitwiseArray leftmostBitVector(Boolean inPlace = False) {
        if (inPlace && this.inPlace) {
            for (Int i : 0 ..< size) {
                this[i] = this[i].leftmostBit;
            }
            return this;
        }

        return new Element[size](i -> this[i].leftmostBit).toArray(mutability, inPlace=True);
    }

    /**
     * For each value in this array, calculate the least significant (right-most) bit.
     *
     * @param inPlace (optional) pass True to specify that the operation should occur using `this`
     *                to hold the result, if possible
     *
     * @return the array containing the integer values representing the right-most (least
     *         significant) bit of each integer value in this array
     */
    BitwiseArray rightmostBitVector(Boolean inPlace = False) {
        if (inPlace && this.inPlace) {
            for (Int i : 0 ..< size) {
                this[i] = this[i].rightmostBit;
            }
            return this;
        }

        return new Element[size](i -> this[i].rightmostBit).toArray(mutability, inPlace=True);
    }

    /**
     * Calculate number of bits that are zero preceding the most significant (left-most) `1` bit,
     * for each integer in the array.
     *
     * For a integers with `bitCount==1`, this provides the log2 value of the integers.
     *
     * @param inPlace (optional) pass True to specify that the operation should occur using `this`
     *                to hold the result, if possible
     *
     * @return the array containing the number of bits that are zero preceding the most significant
     *         (left-most) `1` bit of each value in this array
     */
    BitwiseArray leadingZeroCountVector(Boolean inPlace = False) {
        if (inPlace && this.inPlace) {
            for (Int i : 0 ..< size) {
                this[i] = toElement(this[i].leadingZeroCount);
            }
            return this;
        }

        return new Element[size](i -> toElement(this[i].leadingZeroCount)).toArray(mutability, inPlace=True);
    }

    /**
     * Calculate number of bits that are zero following the least significant (right-most) `1` bit,
     * for each integer in the array.
     *
     * For a integers with `bitCount==1`, this provides the log2 value of the integers.
     *
     * @param inPlace (optional) pass True to specify that the operation should occur using `this`
     *                to hold the result, if possible
     *
     * @return the array containing the number of bits that are zero following the least significant
     *         (right-most) `1` bit of each value in this array
     */
    BitwiseArray trailingZeroCountVector(Boolean inPlace = False) {
        if (inPlace && this.inPlace) {
            for (Int i : 0 ..< size) {
                this[i] = toElement(this[i].trailingZeroCount);
            }
            return this;
        }

        return new Element[size](i -> toElement(this[i].trailingZeroCount)).toArray(mutability, inPlace=True);
    }

    /**
     * Calculate the number of bits that are set (non-zero) in each integer in the array.
     *
     * @param inPlace (optional) pass True to specify that the operation should occur using `this`
     *                to hold the result, if possible
     *
     * @return the array containing the bit count of each integer number in this array
     */
    BitwiseArray bitCountVector(Boolean inPlace = False) {
        if (inPlace && this.inPlace) {
            for (Int i : 0 ..< size) {
                this[i] = toElement(this[i].bitCount);
            }
            return this;
        }

        return new Element[size](i -> toElement(this[i].bitCount)).toArray(mutability, inPlace=True);
    }

    /**
     * Bitwise `AND` the passed number to each number in this array, returning the resulting array.
     *
     * @param scalar  the scalar value to `AND` with the numbers in this array
     * @param inPlace (optional) pass True to specify that the operation should occur using `this`
     *                to hold the result, if possible
     *
     * @return the array containing the resulting sums
     */
    BitwiseArray andScalar(Element scalar, Boolean inPlace = False) {
        if (inPlace && this.inPlace) {
            for (Int i : 0 ..< size) {
                this[i] &= scalar;
            }
            return this;
        }

        return new Element[size](i -> this[i] & scalar).toArray(mutability, inPlace=True);
    }

    /**
     * Bitwise `AND` each number in the passed array with the corresponding number in this array,
     * returning the resulting array.
     *
     * @param that    the array of numbers to `AND` with the numbers in this array
     * @param inPlace (optional) pass True to specify that the operation should occur using `this`
     *                to hold the result, if possible
     *
     * @return the array containing the resulting values
     */
    BitwiseArray andVector(BitwiseArray that) {
        assert:bounds this.size == that.size;

        if (inPlace && this.inPlace) {
            for (Int i : 0 ..< size) {
                this[i] &= that[i];
            }
            return this;
        }

        return new Element[size](i -> this[i] & that[i]).toArray(mutability, inPlace=True);
    }

    /**
     * Bitwise `OR` the passed number to each number in this array, returning the resulting array.
     *
     * @param scalar  the scalar value to `OR` with the numbers in this array
     * @param inPlace (optional) pass True to specify that the operation should occur using `this`
     *                to hold the result, if possible
     *
     * @return the array containing the resulting sums
     */
    BitwiseArray orScalar(Element scalar, Boolean inPlace = False) {
        if (inPlace && this.inPlace) {
            for (Int i : 0 ..< size) {
                this[i] |= scalar;
            }
            return this;
        }

        return new Element[size](i -> this[i] | scalar).toArray(mutability, inPlace=True);
    }

    /**
     * Bitwise `OR` each number in the passed array with the corresponding number in this array,
     * returning the resulting array.
     *
     * @param that    the array of numbers to `OR` with the numbers in this array
     * @param inPlace (optional) pass True to specify that the operation should occur using `this`
     *                to hold the result, if possible
     *
     * @return the array containing the resulting values
     */
    BitwiseArray orVector(BitwiseArray that) {
        assert:bounds this.size == that.size;

        if (inPlace && this.inPlace) {
            for (Int i : 0 ..< size) {
                this[i] |= that[i];
            }
            return this;
        }

        return new Element[size](i -> this[i] | that[i]).toArray(mutability, inPlace=True);
    }

    /**
     * Bitwise `XOR` the passed number to each number in this array, returning the resulting array.
     *
     * @param scalar  the scalar value to `XOR` with the numbers in this array
     * @param inPlace (optional) pass True to specify that the operation should occur using `this`
     *                to hold the result, if possible
     *
     * @return the array containing the resulting sums
     */
    BitwiseArray xorScalar(Element scalar, Boolean inPlace = False) {
        if (inPlace && this.inPlace) {
            for (Int i : 0 ..< size) {
                this[i] ^= scalar;
            }
            return this;
        }

        return new Element[size](i -> this[i] ^ scalar).toArray(mutability, inPlace=True);
    }

    /**
     * Bitwise `XOR` each number in the passed array with the corresponding number in this array,
     * returning the resulting array.
     *
     * @param that    the array of numbers to `XOR` with the numbers in this array
     * @param inPlace (optional) pass True to specify that the operation should occur using `this`
     *                to hold the result, if possible
     *
     * @return the array containing the resulting values
     */
    BitwiseArray xorVector(BitwiseArray that) {
        assert:bounds this.size == that.size;

        if (inPlace && this.inPlace) {
            for (Int i : 0 ..< size) {
                this[i] ^= that[i];
            }
            return this;
        }

        return new Element[size](i -> this[i] ^ that[i]).toArray(mutability, inPlace=True);
    }

    /**
     * Calculate the bitwise `NOT` for each number in this array.
     *
     * @param inPlace (optional) pass True to specify that the operation should occur using `this`
     *                to hold the result, if possible
     *
     * @return the array containing the bitwise `NOT` of each number in this array
     */
    BitwiseArray notVector(Boolean inPlace = False) {
        if (inPlace && this.inPlace) {
            for (Int i : 0 ..< size) {
                this[i] = ~this[i];
            }
            return this;
        }

        return new Element[size](i -> ~this[i]).toArray(mutability, inPlace=True);
    }


    /**
     * Shift bits left. This is both a logical left shift and arithmetic left shift, for
     * both signed and unsigned integer values.
     *
     * @param count   the size of the shift
     * @param inPlace (optional) pass True to specify that the operation should occur using `this`
     *                to hold the result, if possible
     *
     * @return the array containing the resulting values
     */
    BitwiseArray shiftLeftVector(Int count, Boolean inPlace = False) {
        if (inPlace && this.inPlace) {
            for (Int i : 0 ..< size) {
                this[i] <<= count;
            }
            return this;
        }

        return new Element[size](i -> this[i] << count).toArray(mutability, inPlace=True);
    }

    /**
     * Shift bits right. For signed integer values, this is an arithmetic right shift. For
     * unsigned integer values, this is both a logical right shift and arithmetic right
     * shift.
     *
     * @param count   the size of the shift
     * @param inPlace (optional) pass True to specify that the operation should occur using `this`
     *                to hold the result, if possible
     *
     * @return the array containing the resulting values
     */
    BitwiseArray shiftRightVector(Int count, Boolean inPlace = False) {
        if (inPlace && this.inPlace) {
            for (Int i : 0 ..< size) {
                this[i] >>= count;
            }
            return this;
        }

        return new Element[size](i -> this[i] >> count).toArray(mutability, inPlace=True);
    }

    /**
     * "Unsigned" shift bits right. For signed integer values, this is an logical right
     * shift. For unsigned integer values, this is both a logical right shift and arithmetic
     * right shift.
     *
     * @param count   the size of the shift
     * @param inPlace (optional) pass True to specify that the operation should occur using `this`
     *                to hold the result, if possible
     *
     * @return the array containing the resulting values
     */
    BitwiseArray shiftAllRightVector(Int count, Boolean inPlace = False) {
        if (inPlace && this.inPlace) {
            for (Int i : 0 ..< size) {
                this[i] >>>= count;
            }
            return this;
        }

        return new Element[size](i -> this[i] >>> count).toArray(mutability, inPlace=True);
    }

    /**
     * Rotate bits left.
     *
     * @param count   the size of the shift
     * @param inPlace (optional) pass True to specify that the operation should occur using `this`
     *                to hold the result, if possible
     *
     * @return the array containing the resulting values
     */
    BitwiseArray rotateLeftVector(Int count, Boolean inPlace = False) {
        if (inPlace && this.inPlace) {
            for (Int i : 0 ..< size) {
                this[i] = this[i].rotateLeft(count);
            }
            return this;
        }

        return new Element[size](i -> this[i].rotateLeft(count)).toArray(mutability, inPlace=True);
    }

    /**
     * Rotate bits right.
     *
     * @param count   the size of the shift
     * @param inPlace (optional) pass True to specify that the operation should occur using `this`
     *                to hold the result, if possible
     *
     * @return the array containing the resulting values
     */
    BitwiseArray rotateRightVector(Int count, Boolean inPlace = False) {
        if (inPlace && this.inPlace) {
            for (Int i : 0 ..< size) {
                this[i] = this[i].rotateRight(count);
            }
            return this;
        }

        return new Element[size](i -> this[i].rotateRight(count)).toArray(mutability, inPlace=True);
    }
}
