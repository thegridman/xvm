import ecstasy.fs.Directory;
import ecstasy.fs.File;

import xunit.discovery.*;

const Runner(TestConfiguration config)
    {
    void run()
        {
        TestEngine     engine   = new TestEngine(config);
        ModuleSelector selector = new ModuleSelector(config.testModule);
        UniqueId       uniqueId = UniqueId.forEngine("xunit");
        Model          root     = engine.discover(uniqueId);
        engine.execute(root);
        }
    }