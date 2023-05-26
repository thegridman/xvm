/**
 * An `ExecutionListener` that delegates events to one or more
 * inner `ExecutionListener` instances.
 *
 * @param listeners  the `ExecutionListener` instances to delegate events to
 */
service DelegatingExecutionListener(ExecutionListener[] listeners)
        implements ExecutionListener
    {
    @Override
	void onStarted(TestIdentifier identifier)
	    {
	    for (ExecutionListener listener : listeners)
	        {
	        listener.onStarted(identifier);
	        }
	    }

    @Override
	void onFinished(TestIdentifier identifier, Result result)
	    {
	    for (ExecutionListener listener : listeners)
	        {
	        listener.onFinished(identifier, result);
	        }
	    }

    @Override
	void onSkipped(TestIdentifier identifier, String reason)
	    {
	    for (ExecutionListener listener : listeners)
	        {
	        listener.onSkipped(identifier, reason);
	        }
	    }

    @Override
	void onPublished(TestIdentifier identifier, ReportEntry entry)
        {
	    for (ExecutionListener listener : listeners)
	        {
	        listener.onPublished(identifier, entry);
	        }
	    }
    }
