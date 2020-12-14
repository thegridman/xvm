import ecstasy.reflect.Parameter;

/**
 * A registry of ParameterBinder instances for a given source type.
 *
 * @param <S> the source type
 */
public interface ParameterBinderRegistry<S> 
    {
    /**
     * Adds a parameter binder to the registry.
     *
     * @param binder the binder to add
     *
     * @param <T> The parameter type
     * @param <ST> The source type
     */
    <T, ST extends S> void addParameterBinder(ParameterBinder<T, ST> binder)
        {
        throw new UnsupportedOperation("Binder registry is not mutable");
        }

    /**
     * Locate a ParameterBinder for the given parameter and source type.
     *
     * @param parameter the parameter to bind a value to
     * @param source    the source of values to bind to the parameter
     * @param <T>       the parameter type
     *
     * @return True iff a ParameterBinder exists for the given parameter
     * @return the ParameterBinder for the given parameter
     */
    <T> conditional ParameterBinder<T, S> findParameterBinder(Parameter<T> parameter, S source);
    }
