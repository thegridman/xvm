import xunit.AfterAll;
import xunit.RepeatedTest;
import xunit.RepeatedTestInfo;

class RepeatedTests
    {
    static TestCounts countsFive  = new TestCounts();
    static TestCounts countsThree = new TestCounts();
    static TestCounts countsTwo   = new TestCounts();

    @RepeatedTest(5)
    void shouldRunFiveTimes()
        {
        countsFive.testCount++;
        }

    @RepeatedTest(3)
    void shouldRunThreeTimes(RepeatedTestInfo info)
        {
        assert:test countsThree.testCount == info.iteration;
        assert:test info.count == 3;
        countsThree.testCount++;
        }

    @RepeatedTest(2)
    void shouldRunTwice(RepeatedTestInfo info, TestInfo testInfo)
        {
        assert:test countsTwo.testCount == info.iteration;
        assert:test info.count == 2;
        assert:test testInfo.testClass == RepeatedTests;
        countsTwo.testCount++;
        }

    @AfterAll
    static void assertCounts()
        {
        assert:test countsFive.testCount == 5;
        assert:test countsThree.testCount == 3;
        assert:test countsTwo.testCount == 2;
        }
    }
