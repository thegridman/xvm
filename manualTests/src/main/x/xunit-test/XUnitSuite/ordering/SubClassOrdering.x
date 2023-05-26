import callbacks.*;
import xunit.*;

class SubClassOrdering
    {
    static TestCounts counts = new TestCounts();

    @Test
    void shouldRun()
        {
        // Outer class methods should run first
        assert:test SubClassOrdering.counts.testCount == 0;
        SubClassOrdering.counts.testCount++;
        }

    @Abstract
    static class BaseClassTest
        {
        // cannot really rely on base-class methods running first,
        // so highest priority will ensure it does
        @Test(priority = 100)
        void shouldRunParentMethod()
            {
            assert:test SubClassOrdering.counts.testCount == 1;
            SubClassOrdering.counts.testCount++;
            }
        }

    static class ChildClassTest
            extends BaseClassTest
        {
        // lower priority than parent class, so runs last
        @Test(priority = 10)
        void shouldRunChildMethod()
            {
            assert:test SubClassOrdering.counts.testCount == 2;
            }
        }
    }