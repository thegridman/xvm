/**
 * The configuration used to determine how test fixtures and tests are discovered
 * for a specific test execution.
 *
 * A test discovery configuration may be to discover just a single test method, or
 * discover all tests in a class, package or module, or all tests of a specific
 * test group, or a combination of any of these.
 */
const DiscoveryConfiguration(Selector[] selectors,
        DisplayNameGenerator displayNameGenerator = DisplayNameGenerator.Default)
    {
    Builder asBuilder()
        {
        return new Builder(this);
        }

    static DiscoveryConfiguration create(Module testModule)
        {
        return builder(testModule).build();
        }

    static DiscoveryConfiguration create(Selector[] selectors)
        {
        return builder(selectors).build();
        }

    static Builder builder(Module testModule)
        {
        return builder([new ModuleSelector(testModule)]);
        }

    static Builder builder(Selector[] selectors)
        {
        return new Builder(selectors);
        }

    static class Builder(Selector[] selectors)
        {
        construct(DiscoveryConfiguration config)
            {
            this.selectors            = config.selectors;
            this.displayNameGenerator = config.displayNameGenerator;
            }

        DisplayNameGenerator displayNameGenerator = DisplayNameGenerator.Default;

        Builder withSelector(Selector selector)
            {
            this.selectors += selector;
            return this;
            }

        Builder withDisplayNameGenerator(DisplayNameGenerator generator)
            {
            displayNameGenerator = generator;
            return this;
            }

        DiscoveryConfiguration build()
            {
            return new DiscoveryConfiguration(selectors, displayNameGenerator);
            }
        }
    }