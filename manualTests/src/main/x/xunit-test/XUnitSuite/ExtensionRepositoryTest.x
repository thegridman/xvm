import xunit.Extension;
import xunit.RegisterExtension;
import xunit.extensions.ExtensionRepository;

class ExtensionRepositoryTest
    {
    @Test
    void shouldRegisterExtensions()
        {
        ExtensionRepository repository = new ExtensionRepository();
        register(repository);
        assert:test repository.size == 5;
        }

    @Test
    void shouldSortExtensions()
        {
        ExtensionRepository repository = new ExtensionRepository();
        register(repository);
        ExtensionStub[]        allExtensions = repository.get(ExtensionStub);
        ConcreteExtensionOne[] extensionOne  = repository.get(ConcreteExtensionOne);
        ConcreteExtensionTwo[] extensionTwo  = repository.get(ConcreteExtensionTwo);

        assert:test allExtensions.size == 5;

        assert:test extensionOne.size == 3;
        assert:test extensionOne[0] == five;
        assert:test extensionOne[1] == three;
        assert:test extensionOne[2] == one;

        assert:test extensionTwo.size == 2;
        assert:test extensionTwo[0] == four;
        assert:test extensionTwo[1] == two;
        }

    @Test
    void shouldSortExtensionsReversed()
        {
        ExtensionRepository repository = new ExtensionRepository();
        register(repository);
        ExtensionStub[]        allExtensions = repository.reversed(ExtensionStub);
        ConcreteExtensionOne[] extensionOne  = repository.reversed(ConcreteExtensionOne);
        ConcreteExtensionTwo[] extensionTwo  = repository.reversed(ConcreteExtensionTwo);

        assert:test allExtensions.size == 5;

        assert:test extensionOne.size == 3;
        assert:test extensionOne[0] == one;
        assert:test extensionOne[1] == three;
        assert:test extensionOne[2] == five;

        assert:test extensionTwo.size == 2;
        assert:test extensionTwo[0] == two;
        assert:test extensionTwo[1] == four;
        }


    private void register(ExtensionRepository repository)
        {
        for (Property property : &this.actualType.properties)
            {
            if (property.is(RegisterExtension))
                {
                repository.add(property.get(this).as(Extension), property);
                }
            }
        }

    @RegisterExtension
    ConcreteExtensionOne one   = new ConcreteExtensionOne("one", 1);

    @RegisterExtension
    ConcreteExtensionTwo two   = new ConcreteExtensionTwo("two", 2);

    @RegisterExtension
    ConcreteExtensionOne three = new ConcreteExtensionOne("three", 3);

    @RegisterExtension
    ConcreteExtensionTwo four  = new ConcreteExtensionTwo("four", 4);

    @RegisterExtension
    ConcreteExtensionOne five = new ConcreteExtensionOne("five", 5);

    static interface ExtensionStub
            extends Extension
        {
        @RO String id;
        }

    static class ConcreteExtensionOne(String id, Int priority)
            implements ExtensionStub
        {
        }

    static class ConcreteExtensionTwo(String id, Int priority)
            implements ExtensionStub
        {
        }
    }