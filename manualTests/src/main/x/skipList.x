module TestSkipList
    {
    import ecstasy.collections.SkipList;

    @Inject
    Console console;

    @Inject
    Random random;

    void run()
        {
        console.println("Testing SkipListMap");

        testAdd();
        }

    void testAdd()
        {
        SkipList<Int, String> list = new SkipList();
        Int                   key  = 0;

        for (Int i = 0; i < 20; i++)
            {
            key = random.int(50);
            console.println("Putting " + key);
            list.put(key, "V" + key);
            console.println(list.print());
            }

        for (Int i : [key, -1])
            {
            console.println("Getting key " + i);
            if (String value := list.get(i))
                {
                console.println("Value for key " + i + " is " + value);
                }
            else
                {
                console.println("Value for key is Null");
                }
            }

        console.println("Removing " + key.toString());
        list.remove(key);
        console.println(list.print());
        }

    }