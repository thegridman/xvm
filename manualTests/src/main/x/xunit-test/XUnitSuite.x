
module XUnitSuite
        incorporates xunit.Suite
    {
    package xunit import xunit.xtclang.org;

    import xunit.AfterAll;
    import xunit.AfterEach;
    import xunit.BeforeAll;
    import xunit.BeforeEach;
    import xunit.Disabled;
    import xunit.DisplayName;
    import xunit.ParameterizedTest;
    import xunit.RepeatedTest;
    import xunit.TestFixture;
    import xunit.TestInfo;

    @Inject Console console;

    void run()
        {
        // test() is declared in xunit.Suite.
        // Normally a module that incorporates xunit.Suite would probably have some other
        // run() method, but we can still run tests on a module that incorporates xunit.Suite
        // directly from the command line using "xec -L $libDir -M test $libDir/$moduleName.xtc"
        test();
        }

    /**
     * Simple class to track counts during tests.
     */
    class TestCounts
        {
        Int constructorCount = 0;

        Int beforeAllCount = 0;

        Int afterAllCount = 0;

        Int beforeEachCount = 0;

        Int afterEachCount = 0;

        Int testCount = 0;
        }

    static TestCounts moduleCounts = new TestCounts();

    @BeforeAll
    static void beforeSuite()
        {
        assert:test moduleCounts.beforeAllCount == 0;
        assert:test moduleCounts.afterAllCount == 0;
        assert:test moduleCounts.beforeEachCount == 0;
        assert:test moduleCounts.afterEachCount == 0;
        assert:test moduleCounts.testCount == 0;
        moduleCounts.beforeAllCount++;
        }

    @BeforeEach
    void beforeEachTest()
        {
        assert:test moduleCounts.beforeAllCount == 1;
        assert:test moduleCounts.afterAllCount == 0;
        assert:test moduleCounts.beforeEachCount == moduleCounts.testCount;
        assert:test moduleCounts.afterEachCount == moduleCounts.testCount;
        moduleCounts.beforeEachCount++;
        }

    @AfterAll
    static void afterSuite()
        {
        assert:test moduleCounts.beforeAllCount == 1;
        assert:test moduleCounts.afterAllCount == 0;
        assert:test moduleCounts.beforeEachCount == moduleCounts.testCount;
        assert:test moduleCounts.afterEachCount == moduleCounts.testCount;
        assert:test moduleCounts.testCount != 0;
        moduleCounts.afterAllCount++;
        }

    @AfterEach
    void afterEachTest()
        {
        assert:test moduleCounts.beforeAllCount == 1;
        assert:test moduleCounts.afterAllCount == 0;
        assert:test moduleCounts.beforeEachCount == moduleCounts.testCount;
        assert:test moduleCounts.afterEachCount == moduleCounts.testCount - 1;
        assert:test moduleCounts.testCount != 0;
        moduleCounts.afterEachCount++;
        }

    @Test
    void shouldRunModuleTest()
        {
        assert:test moduleCounts.beforeAllCount == 1;
        assert:test moduleCounts.afterAllCount == 0;
        moduleCounts.testCount++;
        assert:test moduleCounts.beforeEachCount == moduleCounts.testCount;
        assert:test moduleCounts.afterEachCount == moduleCounts.testCount - 1;
        }

    @Test
    void shouldHaveBadAssumptions()
        {
        moduleCounts.testCount++;
        throw new PreconditionFailed("bad assumptions!");
        }

    /**
     * Assert the `@Test` annotated constructor is used.
     */
    const ExampleConstTest(String value, Int[] numbers = [])
        {
        @Test(Test.Omit)
        construct()
            {
            usedTestConstructor = True;
            construct ExampleConstTest("test");
            }

        private Boolean usedTestConstructor = False;

        @Test
        void shouldInvokeCorrectConstructor()
            {
            assert:test usedTestConstructor == True;
            assert:test value == "test";
            assert:test numbers.size == 0;
            }
        }

    /**
     * Assert the constructor is called once, and the same instance used for all tests.
     */
    @TestFixture(Singleton)
    class ExampleTestOne
        {
        construct ()
            {
            counts.constructorCount++;
            }

        static TestCounts counts = new TestCounts();

        //@Test
        void shouldRunClassMethodOne()
            {
            assert:test counts.constructorCount == 1;
            }

       // @Test
        void shouldRunClassMethodTwo()
            {
            assert:test counts.constructorCount == 1;
            }
        }

    class JustSomeClass
        {
        void noTestsHere()
            {
            xunit.fail($"NOT A TEST METHOD IN JustSomeClass");
            }
        }
    }