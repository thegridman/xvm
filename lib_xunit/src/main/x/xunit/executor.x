/**
 * The `executor` package contains classes responsible for controlling
 * execution of test fixtures.
 */
package executor
    {
    // ---- inner const: Result --------------------------------------------------------------------

    /**
     * The result of a test fixture execution.
     *
     * @param state       the final result state
     * @param exception   any `Exception` thrown by the test execution
     * @param suppressed  any additional suppressed exceptions, for example thrown
     *                    during test cleanup
     */
    const Result(TestResult.State state, Exception? exception = Null, Exception[]? suppressed = Null, Duration duration = Duration.NONE)
        {
        Result withDuration(Duration d)
            {
            return new Result(state, exception, suppressed, d);
            }

        /**
         * A singleton `Result` representing a successful test fixture.
         */
        static Result Passed = new Result(Successful);
        }

    // ---- inner const: SkipResult ----------------------------------------------------------------

    /**
     * A skipped test `Result`.
     */
	const SkipResult(Boolean skipped, String reason = "unknown")
	    {
	    static SkipResult NotSkipped = new SkipResult(False);
	    }
    }
