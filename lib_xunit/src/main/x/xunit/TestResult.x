
const TestResult(TestIdentifier id, State state, Duration duration, String? skipReason = Null, Exception? exception = Null, Exception[]? suppressed = Null, Map<String, String> tags = Map:[])
    {
    @Lazy String? skipReason.calc()
        {
        if (state == Skipped)
            {
            if (skipReason.is(String))
                {
                if (skipReason.size > 0)
                    {
                    return skipReason;
                    }
                }
            else if (exception.is(Exception))
                {
                return exception.text;
                }
            return "skipped for unknown reason";
            }
        return Null;
        }

    @Lazy Int testCount.calc()
        {
        Int count = id.kind.isTest ? 1 : 0;
        return count;
        }

	@Lazy Int testsSkipped.calc()
	    {
        Int count = id.kind.isTest && state == Skipped ? 1 : 0;
        return count;
	    }

	@Lazy Int testsAborted.calc()
	    {
        Int count = id.kind.isTest && state == Aborted ? 1 : 0;
        return count;
	    }

	@Lazy Int testsSucceeded.calc()
	    {
        Int count = id.kind.isTest && state == Successful ? 1 : 0;
        return count;
	    }

	@Lazy Int testsFailed.calc()
	    {
        Int count = id.kind.isTest && state == Failed ? 1 : 0;
        return count;
	    }

    // ----- inner enum State ----------------------------------------------------------------------

    enum State
        {
		/**
		 * Execution was successful.
		 */
		Successful,
		/**
		 * Execution was aborted, i.e. execution started but not finished.
		 */
		Aborted,
		/**
		 * Execution failed.
		 */
		Failed,
		/**
		 * Execution skipped.
		 */
		Skipped,
        }
    }