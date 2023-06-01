
const DefaultMethodExecutor
        implements MethodExecutor
    {
    @Override
    Tuple invoke(Function<Tuple, Tuple> fn, ExecutionContext context)
        {
        if (fn.params.size == 0)
            {
            return fn();
            }

        Map<Parameter, Object> params   = ParameterResolver.ensureResolved(context, fn.params);
@Inject Console console;
console.print($"Invoke function: {fn} with parameters {params}");

        Function               fnInvoke = fn.bind(params);
        return fnInvoke();
        }
    }