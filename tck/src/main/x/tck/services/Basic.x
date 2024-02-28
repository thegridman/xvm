/**
 * Basic service tests.
 */
class Basic {
    static service Tester(Journal journal) {
        void simulateSlowIO(Duration duration, String endMsg) {
            Utils.simulateSlowIO(duration);
            journal.add(endMsg);
        }

        void simulateLongCompute(Int count, String endMsg) {
            Utils.simulateLongCompute(count);
            journal.add(endMsg);
        }

        void sync() {
        }
    }

    @Test
    void testSlowIO() {
        Journal journal = new Journal();
        Tester  svc     = new Tester(journal);
        // this:service is "A", Tester is "B"

        journal.add("A0");
        svc.simulateSlowIO^(Duration.ofMillis(50), "B1"); // async call
        journal.add("A2");
        svc.sync();

        // the scheduling of fibers is a prerogative of the run-time, so theoretically speaking
        // there is a tiny chance that the scheduler doesn't "resume" A until after B is done;
        // with our current implementation, however, that would be a 1:1_000_000_000_000 chance
        assert journal.collect() == ["A0", "A2", "B1"];
    }

    @Test
    void testLongCompute() {
        Journal journal = new Journal();
        Tester  svc     = new Tester(journal);
        // this:service is "A", Tester is "B"

        journal.add("A0");
        svc.simulateLongCompute^(100_000, "B1"); // async call
        journal.add("A2");
        svc.sync();

        // the scheduling of fibers is a prerogative of the run-time, so theoretically speaking
        // there is a tiny chance that the scheduler doesn't "resume" A until after B is done
        assert journal.collect() == ["A0", "A2", "B1"];
    }
}