import ecstasy.collections.Hasher;
import ecstasy.collections.NaturalHasher;

/**
 * Tests for hashes.
 */
class Hash {

    @Test
    void hashInt() {
        Int         i = 1;
        Hasher<Int> h = new NaturalHasher();

        assert Int.hashCode(i) == 1;
        assert h.hashOf(i) == 1;
    }
    @Test
    void hashString() {
        String         s = "abc";
        Hasher<String> h = new NaturalHasher();

        assert String.hashCode(s) == hasher.hashOf(s);
    }

    @Test
    void hashConstants() {
        NamedPoint         point1  = new NamedPoint("a", 0, 2);
        NamedPoint         point2  = new NamedPoint("b", 0, 2);
        Hasher<Point>      hasherP = new NaturalHasher();
        Hasher<NamedPoint> hasherN = new NaturalHasher();

        assert Point.hashCode(point1)      == Point.hashCode(point2);
        assert NamedPoint.hashCode(point1) != NamedPoint.hashCode(point2);
        assert Point.hashCode(point1)      == hasherP.hashOf(point1);
        assert NamedPoint.hashCode(point2) == hasherN.hashOf(point2);
    }

    const Point(Int x, Int y);

    const NamedPoint(String name, Int x, Int y)
        extends Point(x, y);
}
