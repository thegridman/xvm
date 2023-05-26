/**
 * A `Selector` is used by the discovery mechanism to select test fixtures for execution.
 */
interface Selector
    {
    /**
     * Discover test fixtures for execution.
     *
     * @param config  the discovery configuration
     * @param id      the root `UniqueId` to start discovery from
     *
     * @return additional `Selector` instance to use to discover more fixtures
     * @return the discovered test fixtures
     */
    (Selector[], Model[]) select(DiscoveryConfiguration config, UniqueId id);
    }