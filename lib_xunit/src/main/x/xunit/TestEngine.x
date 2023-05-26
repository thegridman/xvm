import ecstasy.collections.Queue;

import collections.ArrayDeque;

import xunit.models.*;
import xunit.executor.*;


/**
 * An engine that discovers and executes tests.
 */
const TestEngine(TestConfiguration config)
    {
    immutable Model discover(UniqueId uniqueId)
        {
        DiscoveryConfiguration discoveryConfig = config.discoveryConfiguration;
        Model                  root            = new XUnitModel(uniqueId);
        Queue<Selector>        selectorQueue   = new ArrayDeque(discoveryConfig.selectors.size);

        selectorQueue.addAll(discoveryConfig.selectors);

        while (Selector selector := selectorQueue.next())
            {
            (Selector[] selectors, Model[] models) = selector.select(discoveryConfig, uniqueId);
            selectorQueue.addAll(selectors);
            root.addChildren(models);
            }

        return root.freeze(True);
        }

    void execute(Model root)
        {
        ExecutionConfiguration executionConfig = config.executionConfiguration;
        TestRecorder           recorder        = new TestRecorder();
        TestExecution          execution       = new TestExecution(root, executionConfig);
        TestExecutorService    executor        = new TestExecutorService(executionConfig);
        ExecutionListener[]    listeners       = new Array();

        listeners.add(recorder);
        listeners.addAll(executionConfig.listeners);

        DelegatingExecutionListener listener = new DelegatingExecutionListener(listeners.freeze());

        executor.submit(execution.freeze(True), root, listener);
        }
    }