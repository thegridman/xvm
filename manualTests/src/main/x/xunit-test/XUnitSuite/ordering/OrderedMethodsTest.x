import callbacks.*;
import xunit.*;

/**
 * Verify methods are called in the order defined by their priorities.
 * Extension and method priority order is highest first (the opposite of
 * the natural order of an Int).
 *
 * * "Before" methods and extensions are called in priority order, highest first
 *   or in the order of discovery if priorities match
 *
 * * "After" methods and extensions are called in reverse priority order, lowest first
 *   or in the reverse order of discovery if priorities match
 *
 */
class OrderedMethodsTest
    {
    static TestCounts counts = new TestCounts();

    @Inject Console console;

    @BeforeAll(10)
    static void beforeAllTwo()
        {
        @Inject Console console;
        console.print($"Executing beforeAllTwo");

        assert:test beforeAllExtensionOne.count == 1;
        assert:test beforeAllExtensionTwo.count == 0;
        assert:test OrderedMethodsTest.counts.beforeAllCount == 1;
        assert:test OrderedMethodsTest.counts.beforeEachCount == 0;
        assertAfterAllZero();
        OrderedMethodsTest.counts.beforeAllCount++;
        console.print($"Executed beforeAllTwo");
        }

    @BeforeAll
    static void beforeAllThree()
        {
        @Inject Console console;
        console.print($"Executing beforeAllThree");

        assert:test beforeAllExtensionOne.count == 1;
        assert:test beforeAllExtensionTwo.count == 1;
        assert:test OrderedMethodsTest.counts.beforeAllCount == 2;
        assert:test OrderedMethodsTest.counts.beforeEachCount == 0;
        assertAfterAllZero();
        OrderedMethodsTest.counts.beforeAllCount++;
        console.print($"Executed beforeAllThree");
        }

    @BeforeAll(100)
    static void beforeAllOne()
        {
        @Inject Console console;
        console.print($"Executing beforeAllOne");

        assert:test beforeAllExtensionOne.count == 0;
        assert:test beforeAllExtensionTwo.count == 0;
        assert:test OrderedMethodsTest.counts.beforeAllCount == 0;
        assert:test OrderedMethodsTest.counts.beforeEachCount == 0;
        assertAfterAllZero();
        OrderedMethodsTest.counts.beforeAllCount++;
        console.print($"Executed beforeAllOne");
        }

    @BeforeEach(10)
    void beforeEachTwo()
        {
        console.print($"Executing beforeEachTwo testCount={OrderedMethodsTest.counts.testCount}");
        assert:test OrderedMethodsTest.counts.testCount < 2;

        assert:test beforeEachExtensionOne.count == 1;
        assert:test beforeEachExtensionTwo.count == 0;

        if (OrderedMethodsTest.counts.testCount == 0)
            {
            assert:test OrderedMethodsTest.counts.beforeAllCount == 3;
            assert:test OrderedMethodsTest.counts.beforeEachCount == 1;
            assertAftersZero();
            }
        else if (OrderedMethodsTest.counts.testCount == 1)
            {
            assert:test OrderedMethodsTest.counts.beforeAllCount == 3;
            assert:test OrderedMethodsTest.counts.beforeEachCount == 4;
            }
        OrderedMethodsTest.counts.beforeEachCount++;
        console.print($"Executed beforeEachTwo testCount={OrderedMethodsTest.counts.testCount}");
        }

    @BeforeEach
    void beforeEachThree()
        {
        console.print($"Executing beforeEachThree testCount={OrderedMethodsTest.counts.testCount}");
        assert:test OrderedMethodsTest.counts.testCount < 2;

        assert:test beforeEachExtensionOne.count == 1;
        assert:test beforeEachExtensionTwo.count == 1;
        assert:test beforeTestExtensionOne.count == 0;
        assert:test beforeTestExtensionTwo.count == 0;

        if (OrderedMethodsTest.counts.testCount == 0)
            {
            assert:test OrderedMethodsTest.counts.beforeAllCount == 3;
            assert:test OrderedMethodsTest.counts.beforeEachCount == 2;
            assertAftersZero();
            }
        else if (OrderedMethodsTest.counts.testCount == 1)
            {
            assert:test OrderedMethodsTest.counts.beforeAllCount == 3;
            assert:test OrderedMethodsTest.counts.beforeEachCount == 5;
            }
        OrderedMethodsTest.counts.beforeEachCount++;
        console.print($"Executed beforeEachThree testCount={OrderedMethodsTest.counts.testCount}");
        }

    @BeforeEach(100)
    void beforeEachOne()
        {
        console.print($"Executing beforeEachOne testCount={OrderedMethodsTest.counts.testCount}");
        assert:test OrderedMethodsTest.counts.testCount < 2;

        assert:test beforeAllExtensionOne.count == 1;
        assert:test beforeAllExtensionTwo.count == 1;
        assert:test beforeEachExtensionOne.count == 0;
        assert:test beforeEachExtensionTwo.count == 0;

        if (OrderedMethodsTest.counts.testCount == 0)
            {
            assert:test OrderedMethodsTest.counts.beforeAllCount == 3;
            assert:test OrderedMethodsTest.counts.beforeEachCount == 0;
            assertAftersZero();
            }
        else if (OrderedMethodsTest.counts.testCount == 1)
            {
            assert:test OrderedMethodsTest.counts.beforeAllCount == 3;
            assert:test OrderedMethodsTest.counts.beforeEachCount == 3;
            }
        OrderedMethodsTest.counts.beforeEachCount++;
        console.print($"Executed beforeEachOne testCount={OrderedMethodsTest.counts.testCount}");
        }

    @Test
    void testTwo()
        {
        console.print($"Executing testTwo testCount={OrderedMethodsTest.counts.testCount}");
        assert:test OrderedMethodsTest.counts.testCount == 1;

        assert:test beforeEachExtensionOne.count == 1;
        assert:test beforeEachExtensionTwo.count == 1;
        assert:test beforeTestExtensionOne.count == 1;
        assert:test beforeTestExtensionTwo.count == 1;
        assert:test afterEachExtensionOne.count == 0;
        assert:test afterEachExtensionTwo.count == 0;
        assert:test afterTestExtensionOne.count == 0;
        assert:test afterTestExtensionTwo.count == 0;

        assert:test OrderedMethodsTest.counts.afterEachCount == 3;
        assert:test OrderedMethodsTest.counts.beforeAllCount == 3;
        assert:test OrderedMethodsTest.counts.beforeEachCount == 6;

        assertAfterAllZero();
        OrderedMethodsTest.counts.testCount++;
        console.print($"Executed testTwo testCount={OrderedMethodsTest.counts.testCount}");
        }

    @Test(priority = 1)
    void testOne()
        {
        console.print($"Executing testOne testCount={OrderedMethodsTest.counts.testCount}");
        assert:test beforeEachExtensionOne.count == 1;
        assert:test beforeEachExtensionTwo.count == 1;
        assert:test beforeTestExtensionOne.count == 1;
        assert:test beforeTestExtensionTwo.count == 1;
        assert:test afterEachExtensionOne.count == 0;
        assert:test afterEachExtensionTwo.count == 0;
        assert:test afterTestExtensionOne.count == 0;
        assert:test afterTestExtensionTwo.count == 0;

        assert:test OrderedMethodsTest.counts.beforeAllCount == 3;
        assert:test OrderedMethodsTest.counts.beforeEachCount == 3;

        assertAftersZero();
        OrderedMethodsTest.counts.testCount++;
        console.print($"Executed testOne testCount={OrderedMethodsTest.counts.testCount}");
        }

    @AfterEach(10)
    void afterEachTwo()
        {
        console.print($"Executing afterEachTwo testCount={OrderedMethodsTest.counts.testCount}");
        assert:test OrderedMethodsTest.counts.testCount == 1 || OrderedMethodsTest.counts.testCount == 2;

        assert:test beforeEachExtensionOne.count == 1;
        assert:test beforeEachExtensionTwo.count == 1;
        assert:test beforeTestExtensionOne.count == 1;
        assert:test beforeTestExtensionTwo.count == 1;
        assert:test afterTestExtensionOne.count == 1;
        assert:test afterTestExtensionTwo.count == 1;
        assert:test afterEachExtensionOne.count == 1;
        assert:test afterEachExtensionTwo.count == 0;

        if (OrderedMethodsTest.counts.testCount == 1)
            {
            assert:test OrderedMethodsTest.counts.beforeAllCount == 3;
            assert:test OrderedMethodsTest.counts.beforeEachCount == 3;
            assert:test OrderedMethodsTest.counts.afterEachCount == 1;
            }
        else if (OrderedMethodsTest.counts.testCount == 2)
            {
            assert:test OrderedMethodsTest.counts.beforeAllCount == 3;
            assert:test OrderedMethodsTest.counts.beforeEachCount == 6;
            assert:test OrderedMethodsTest.counts.afterEachCount == 4;
            }
        assertAfterAllZero();
        OrderedMethodsTest.counts.afterEachCount++;
        console.print($"Executed afterEachTwo testCount={OrderedMethodsTest.counts.testCount}");
        }

    @AfterEach
    void afterEachOne()
        {
        console.print($"Executing afterEachOne testCount={OrderedMethodsTest.counts.testCount}");
        assert:test OrderedMethodsTest.counts.testCount == 1 || OrderedMethodsTest.counts.testCount == 2;

        assert:test beforeEachExtensionOne.count == 1;
        assert:test beforeEachExtensionTwo.count == 1;
        assert:test beforeTestExtensionOne.count == 1;
        assert:test beforeTestExtensionTwo.count == 1;
        assert:test afterEachExtensionOne.count == 0;
        assert:test afterEachExtensionTwo.count == 0;
        assert:test afterTestExtensionOne.count == 1;
        assert:test afterTestExtensionTwo.count == 1;

        if (OrderedMethodsTest.counts.testCount == 1)
            {
            assert:test OrderedMethodsTest.counts.beforeAllCount == 3;
            assert:test OrderedMethodsTest.counts.beforeEachCount == 3;
            assert:test OrderedMethodsTest.counts.afterEachCount == 0;
            }
        else if (OrderedMethodsTest.counts.testCount == 2)
            {
            assert:test OrderedMethodsTest.counts.beforeAllCount == 3;
            assert:test OrderedMethodsTest.counts.beforeEachCount == 6;
            assert:test OrderedMethodsTest.counts.afterEachCount == 3;
            }

        assertAfterAllZero();
        OrderedMethodsTest.counts.afterEachCount++;
        console.print($"Executed afterEachOne testCount={OrderedMethodsTest.counts.testCount}");
        }

    @AfterEach(100)
    void afterEachThree()
        {
        console.print($"Executing afterEachThree testCount={OrderedMethodsTest.counts.testCount}");
        assert:test OrderedMethodsTest.counts.testCount == 1 || OrderedMethodsTest.counts.testCount == 2;

        assert:test beforeEachExtensionOne.count == 1;
        assert:test beforeEachExtensionTwo.count == 1;
        assert:test beforeTestExtensionOne.count == 1;
        assert:test beforeTestExtensionTwo.count == 1;
        assert:test afterTestExtensionOne.count == 1;
        assert:test afterTestExtensionTwo.count == 1;
        assert:test afterEachExtensionOne.count == 1;
        assert:test afterEachExtensionTwo.count == 1;

        if (OrderedMethodsTest.counts.testCount == 1)
            {
            assert:test OrderedMethodsTest.counts.beforeAllCount == 3;
            assert:test OrderedMethodsTest.counts.beforeEachCount == 3;
            assert:test OrderedMethodsTest.counts.afterEachCount == 2;
            }
        else if (OrderedMethodsTest.counts.testCount == 2)
            {
            assert:test OrderedMethodsTest.counts.beforeAllCount == 3;
            assert:test OrderedMethodsTest.counts.beforeEachCount == 6;
            assert:test OrderedMethodsTest.counts.afterEachCount == 5;
            }

        assertAfterAllZero();
        OrderedMethodsTest.counts.afterEachCount++;
        console.print($"Executed afterEachThree testCount={OrderedMethodsTest.counts.testCount}");
        }

    @AfterAll(10)
    static void afterAllTwo()
        {
        @Inject Console console;
        console.print($"Executing afterAllOne testCount={OrderedMethodsTest.counts.testCount}");

        assert:test OrderedMethodsTest.counts.afterAllCount == 1;
        assert:test afterAllExtensionOne.count == 1;
        assert:test afterAllExtensionTwo.count == 0;

        assert:test OrderedMethodsTest.counts.testCount == 2;
        assert:test OrderedMethodsTest.counts.beforeAllCount == 3;
        assert:test OrderedMethodsTest.counts.beforeEachCount == 6;
        assert:test OrderedMethodsTest.counts.afterEachCount == 6;

        OrderedMethodsTest.counts.afterAllCount++;
        console.print($"Executed afterAllOne testCount={OrderedMethodsTest.counts.testCount}");
        }

    @AfterAll
    static void afterAllOne()
        {
        @Inject Console console;
        console.print($"Executing afterAllOne testCount={OrderedMethodsTest.counts.testCount}");

        assert:test OrderedMethodsTest.counts.afterAllCount == 0;
        assert:test afterAllExtensionOne.count == 0;
        assert:test afterAllExtensionTwo.count == 0;
        assert:test OrderedMethodsTest.counts.testCount == 2;
        assert:test OrderedMethodsTest.counts.beforeAllCount == 3;
        assert:test OrderedMethodsTest.counts.beforeEachCount == 6;
        assert:test OrderedMethodsTest.counts.afterEachCount == 6;

        OrderedMethodsTest.counts.afterAllCount++;
        console.print($"Executed afterAllOne testCount={OrderedMethodsTest.counts.testCount}");
        }

    @AfterAll(100)
    static void afterAllThree()
        {
        @Inject Console console;
        console.print($"Executing afterAllOne testCount={OrderedMethodsTest.counts.testCount}");

        assert:test OrderedMethodsTest.counts.afterAllCount == 2;
        assert:test afterAllExtensionOne.count == 1;
        assert:test afterAllExtensionTwo.count == 1;
        assert:test OrderedMethodsTest.counts.testCount == 2;
        assert:test OrderedMethodsTest.counts.beforeAllCount == 3;
        assert:test OrderedMethodsTest.counts.beforeEachCount == 6;
        assert:test OrderedMethodsTest.counts.afterEachCount == 6;

        OrderedMethodsTest.counts.afterAllCount++;
        console.print($"Executed afterAllOne testCount={OrderedMethodsTest.counts.testCount}");
        }

    private void assertAftersZero()
        {
        assert:test OrderedMethodsTest.counts.afterEachCount == 0;
        assert:test afterTestExtensionOne.count == 0;
        assert:test afterTestExtensionTwo.count == 0;
        assert:test afterEachExtensionOne.count == 0;
        assert:test afterEachExtensionTwo.count == 0;
        assertAfterAllZero();
        }

    private static void assertAfterAllZero()
        {
        assert:test OrderedMethodsTest.counts.afterAllCount == 0;
        assert:test afterAllExtensionOne.count == 0;
        assert:test afterAllExtensionTwo.count == 0;
        }

    @RegisterExtension(1)
    static CountingBeforeAllCallback beforeAllExtensionTwo = new CountingBeforeAllCallback("two");

    @RegisterExtension(50)
    static CountingBeforeAllCallback beforeAllExtensionOne = new CountingBeforeAllCallback("one");

    @RegisterExtension(1)
    CountingBeforeEachCallback beforeEachExtensionTwo = new CountingBeforeEachCallback("two");

    @RegisterExtension(50)
    CountingBeforeEachCallback beforeEachExtensionOne = new CountingBeforeEachCallback("one");

    @RegisterExtension(1)
    CountingBeforeTestInvocationCallback beforeTestExtensionTwo = new CountingBeforeTestInvocationCallback("two");

    @RegisterExtension(50)
    CountingBeforeTestInvocationCallback beforeTestExtensionOne = new CountingBeforeTestInvocationCallback("one");

    @RegisterExtension(50)
    CountingAfterTestInvocationCallback afterTestExtensionOne = new CountingAfterTestInvocationCallback("one");

    @RegisterExtension(1)
    CountingAfterTestInvocationCallback afterTestExtensionTwo = new CountingAfterTestInvocationCallback("two");

    @RegisterExtension(1)
    CountingAfterEachCallback afterEachExtensionOne = new CountingAfterEachCallback("one");

    @RegisterExtension(50)
    CountingAfterEachCallback afterEachExtensionTwo = new CountingAfterEachCallback("two");

    @RegisterExtension(1)
    static CountingAfterAllCallback afterAllExtensionOne = new CountingAfterAllCallback("one");

    @RegisterExtension(50)
    static CountingAfterAllCallback afterAllExtensionTwo = new CountingAfterAllCallback("two");
    }