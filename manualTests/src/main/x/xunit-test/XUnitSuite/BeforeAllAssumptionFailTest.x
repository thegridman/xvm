import callbacks.*;
import xunit.*;

/**
 * Test when assumptions fail in the `@BeforeAll` annotated method.
 */
class BeforeAllAssumptionFailTest
    {
    static Int getNumber()
        {
        return 1;
        }

    @BeforeAll
    static void CheckAssumptions()
        {
        assert:assume getNumber() != 1;
        }

    @BeforeEach
    void shouldNotRunBeforeEach()
        {
        xunit.fail("Should not have run @BeforeEach");
        }

    @Test
    void shouldNotRunTest()
        {
        xunit.fail("Should not have run this test");
        }

    @AfterEach
    void shouldNotRunAfterEach()
        {
        xunit.fail("Should not have run @AfterEach");
        }

    @RegisterExtension
    static FailingBeforeEachCallback beforeEachExtension = new FailingBeforeEachCallback();

    @RegisterExtension
    static FailingBeforeAllCallback beforeTestExtension = new FailingBeforeAllCallback();

    @RegisterExtension
    static FailingAfterTestInvocationCallback afterTestExtension = new FailingAfterTestInvocationCallback();

    @RegisterExtension
    static FailingAfterEachCallback afterEachExtension = new FailingAfterEachCallback();
    }
