import xunit.*;

/**
 * Assert no `@Disabled` annotated tests in this class are run
 */
class DisabledMethodsTest
    {
    @Test
    @Disabled("Should not run method!")
    void testOne()
        {
        xunit.fail("No tests in DisabledClassTest should be executed");
        }

    @Test
    @Disabled("Should not run method!")
    void testTwo()
        {
        xunit.fail("No tests in DisabledClassTest should be executed");
        }
    }