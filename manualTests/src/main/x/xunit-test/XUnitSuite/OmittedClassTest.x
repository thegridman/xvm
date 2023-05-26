import callbacks.*;
import xunit.*;

/**
 *
 */
@Test(Test.Omit)
class OmittedClassTest
    {
    @BeforeAll
    static void beforeAll()
        {
        xunit.fail("No methods in OmittedClassTest should be executed");
        }

    @BeforeEach
    void beforeEach()
        {
        xunit.fail("No methods in OmittedClassTest should be executed");
        }

    @AfterAll
    static void afterAll()
        {
        xunit.fail("No methods in OmittedClassTest should be executed");
        }

    @AfterEach
    void afterEach()
        {
        xunit.fail("No methods in OmittedClassTest should be executed");
        }

    @Test
    void testOne()
        {
        xunit.fail("No tests in OmittedClassTest should be executed");
        }

    @Test
    void testTwo()
        {
        xunit.fail("No tests in OmittedClassTest should be executed");
        }

    @RegisterExtension
    static FailingBeforeAllCallback beforeAllExtension = new FailingBeforeAllCallback();

    @RegisterExtension
    static FailingBeforeEachCallback beforeEachExtension = new FailingBeforeEachCallback();

    @RegisterExtension
    static FailingBeforeAllCallback beforeTestExtension = new FailingBeforeAllCallback();

    @RegisterExtension
    static FailingAfterTestInvocationCallback afterTestExtension = new FailingAfterTestInvocationCallback();

    @RegisterExtension
    static FailingAfterEachCallback afterEachExtension = new FailingAfterEachCallback();

    @RegisterExtension
    static FailingAfterAllCallback afterAllExtension = new FailingAfterAllCallback();
    }