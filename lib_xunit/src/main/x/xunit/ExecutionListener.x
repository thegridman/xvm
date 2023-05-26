import executor.Result;

/**
 * A listener that receives events related to the execution of test fixtures.
 */
interface ExecutionListener
    {
	/**
	 * Called when the execution of a `TestIdentifier` in the test hierarchy has been started.
	 *
	 * @param identifier  the `TestIdentifier` of the skipped test or container
	 */
	void onStarted(TestIdentifier identifier)
	    {
	    }

	/**
	 * Called when the execution of a `TestIdentifier` in the test hierarchy has finsihed.
	 *
	 * @param identifier  the `TestIdentifier` of the test or container
	 * @param result      the `TestResult` from the test execution
	 */
	void onFinished(TestIdentifier identifier, Result result)
	    {
	    }

	/**
	 * Called when the execution of a `TestIdentifier` in the test hierarchy has been skipped.
	 *
	 * @param identifier  the `TestIdentifier` of the test or container
	 * @param reason      a message describing why the test was skipped
	 */
	void onSkipped(TestIdentifier identifier, String reason)
	    {
	    }

	/**
	 * Called for a `TestIdentifier` to publish additional information.
	 *
	 * @param identifier  the `TestIdentifier` the additional information is related to
	 * @param entry       a `ReportEntry` instance to be published
	 */
	void onPublished(TestIdentifier identifier, ReportEntry entry)
        {
	    }

    // ---- inner const: ReportEntry ---------------------------------------------------------------

    /**
     * An entry in a test report.
     */
    static const ReportEntry
        {
        /**
         * Create a `ReportEntry`.
         *
         * @param timestamp  the timestamp of the report entry
         * @param tags       optional test information tags
         */
        construct(Time? timestamp, Map<String, String> tags = Map:[])
            {
            if (timestamp.is(Time))
                {
                this.timestamp = timestamp.as(Time);
                }
            else
                {
                @Inject Clock clock;
                this.timestamp = clock.now;
                }
            this.tags = tags;
            }

        /**
         * The timestamp of this report entry.
         */
        Time timestamp;

        /**
         * Additional report information tags.
         */
        Map<String, String> tags;

        // ---- Orderable --------------------------------------------------------------------------

        /**
         * Compare two ReportEntry values for the purposes of ordering.
         */
        static <CompileType extends ReportEntry> Ordered compare(CompileType value1, CompileType value2)
            {
            return value1.timestamp <=> value2.timestamp;
            }

        /**
         * Compare two ReportEntry values for equality.
         */
        static <CompileType extends ReportEntry> Boolean equals(CompileType value1, CompileType value2)
            {
            return value1.timestamp == value2.timestamp;
            }
        }

    // ---- inner const: NoOpListener --------------------------------------------------------------

    /**
     * The singleton `NoOpListener` instance.
     */
    static ExecutionListener NoOp = new NoOpListener();

    /**
     * An `ExecutionListener` that does nothing.
     */
    static const NoOpListener
            implements ExecutionListener
        {
        }
    }