import xunit.reporter.*;

const TestConfiguration
    {
    construct(Module                  testModule,
              DiscoveryConfiguration  discoveryConfiguration,
              ExecutionConfiguration  executionConfiguration,
              TestResultReporter      reporter)
        {
        this.testModule             = testModule;
        this.discoveryConfiguration = discoveryConfiguration;
        this.executionConfiguration = executionConfiguration;
        this.reporter               = reporter;
        }

    Module testModule;

    DiscoveryConfiguration discoveryConfiguration;

    ExecutionConfiguration executionConfiguration;

    TestResultReporter reporter;

    Builder asBuilder()
        {
        return new Builder(this);
        }

    static TestConfiguration create(Module testModule)
        {
        return builder(testModule).build();
        }

    static Builder builder(Module testModule)
        {
        return new Builder(testModule);
        }

    static class Builder
        {
        construct (Module testModule)
            {
            this.testModule             = testModule;
            this.discoveryConfiguration = DiscoveryConfiguration.create(testModule);
            this.executionConfiguration = ExecutionConfiguration.create();
            this.reporter               = new ConsoleReporter();
            }

        construct(TestConfiguration config)
            {
            this.testModule             = config.testModule;
            this.discoveryConfiguration = config.discoveryConfiguration;
            this.executionConfiguration = config.executionConfiguration;
            this.reporter               = config.reporter;
            }

        Module testModule;

        DiscoveryConfiguration discoveryConfiguration;

        ExecutionConfiguration executionConfiguration;

        TestResultReporter reporter;

        Builder withDiscoveryConfiguration(DiscoveryConfiguration config)
            {
            this.discoveryConfiguration = config;
            return this;
            }

        Builder withExecutionConfiguration(ExecutionConfiguration config)
            {
            this.executionConfiguration = config;
            return this;
            }

        Builder withTestResultReporter(TestResultReporter reporter)
            {
            this.reporter = reporter;
            return this;
            }

        TestConfiguration build()
            {
            return new TestConfiguration(testModule,
                                         discoveryConfiguration,
                                         executionConfiguration,
                                         reporter);
            }
        }
    }