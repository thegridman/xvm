/**
 * The configuration controlling how discovered test fixtures are executed.
 */
const ExecutionConfiguration(ExecutionListener[] listeners = [])
    {
    Builder asBuilder()
        {
        return new Builder(this);
        }
        
    static ExecutionConfiguration create()
        {
        return builder().build();
        }
        
    static Builder builder()
        {
        return new Builder();
        }
    
    static class Builder
        {
        construct()
            {
            }

        construct(ExecutionConfiguration config)
            {
            this.listeners = config.listeners;
            }

        ExecutionListener[] listeners = [];

        Builder withExecutionListener(ExecutionListener listener)
            {
            this.listeners += listener;
            return this;
            }
        
        Builder withExecutionListeners(ExecutionListener[] listeners)
            {
            this.listeners += listeners;
            return this;
            }

        ExecutionConfiguration build()
            {
            return new ExecutionConfiguration(listeners);
            }
        }
    }