/**
 * A service that records the progress of execution of test fixtures.
 */
service TestRecorder
    implements ExecutionListener
    {
    /**
     * The `Clock` used to time test fixture execution.
     */
    @Inject Clock clock;

    @Inject Console console;

    private String pad = "";

    static String ANSI_RESET = "\e[0m";
    static String ANSI_BLACK = "\e[30m";
    static String ANSI_RED = "\e[31m";
    static String ANSI_GREEN = "\e[32m";
    static String ANSI_YELLOW = "\e[33m";
    static String ANSI_BLUE = "\e[34m";
    static String ANSI_PURPLE = "\e[35m";
    static String ANSI_CYAN = "\e[36m";
    static String ANSI_WHITE = "\e[37m";

    @Override
	void onSkipped(TestIdentifier identifier, String reason)
	    {
        console.print($"--- {ANSI_YELLOW}SKIPPED{ANSI_RESET} ❎  {pad}{identifier.displayName} (reason: {reason})");
	    }

    @Override
	void onStarted(TestIdentifier identifier)
	    {
        console.print($"--- Starting    {pad}{identifier.displayName}");
	    }

    @Override
	void onFinished(TestIdentifier identifier, Result result)
	    {
	    if (result.state == Successful)
	        {
            console.print($"--- {ANSI_GREEN}PASS{ANSI_RESET}    ✅  {pad}{identifier.displayName} (in {result.duration})");
	        }
	    else if (result.state == Failed)
	        {
	        if (result.exception != Null)
	            {
	            console.print($"{result.exception}");
	            }
            console.print($"--- {ANSI_RED}FAILED{ANSI_RESET}  ❌  {pad}{identifier.displayName}");
	        }
	    else if (result.state == Skipped)
	        {
	        String reason = "";
	        if (Exception e ?= result.exception)
	            {
	            reason = $" (reason: {e.text})";
	            }
            console.print($"--- {ANSI_YELLOW}SKIPPED{ANSI_RESET} ❎  {pad}{identifier.displayName}{reason}");
	        }
	    else if (result.state == Aborted)
	        {
	        if (result.exception != Null)
	            {
	            console.print($"{result.exception}");
	            }
            console.print($"--- {ANSI_RED}ABORTED{ANSI_RESET} ❌  {pad}{identifier.displayName}");
	        }
	    }

    @Override
	void onPublished(TestIdentifier identifier, ReportEntry entry)
        {
            if (entry.tags.size > 0)
                {
                console.print($"--- {ANSI_BLUE}INFO{ANSI_RESET}      {pad}Report (timestamp: {entry.timestamp})");
                for (Map.Entry tagEntry : entry.tags.entries)
                    {
                    console.print($"              {pad}- {tagEntry.key}: {tagEntry.value}");
                    }
                }
	    }
    }
