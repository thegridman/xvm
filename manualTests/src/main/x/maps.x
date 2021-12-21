module TestMaps
    {
    package collections import collections.xtclang.org;

    import collections.ConcurrentHashMap;

    @Inject Console console;
    @Inject Timer   timer;
    Log log = new ecstasy.io.ConsoleLog(console);

    void run()
        {
        testBasic(new ListMap());
        testBasic(new HashMap());
        testBasic(new SkiplistMap());
        testBasic(new ConcurrentHashMap());

        testEquals(new ListMap());
        testEquals(new HashMap());
        testEquals(new SkiplistMap());
        testEquals(new ConcurrentHashMap());

        function void () run = &testFill100();
        profile(run, 10);

        testListMap();

        testMapIteration(new ListMap());
        testMapIteration(new HashMap());
        testMapIteration(new SkiplistMap());
        testMapIteration(new ConcurrentHashMap());

        testMapStableIteration(new HashMap());
        testMapStableIteration(new ConcurrentHashMap());
        testMapStableIteration(new SkiplistMap());

        testFreezable();

        testBasicOps(new ListMap());
        testBasicOps(new HashMap());
        testBasicOps(new SkiplistMap());
        testBasicOps(new ConcurrentHashMap());

        testProcess(new ListMap());
        testProcess(new HashMap());
        testProcess(new SkiplistMap());
        testProcess(new ConcurrentHashMap());

        testConcurrentProcess(new SafeHashMap());
        testConcurrentProcess(new ConcurrentHashMap());

        // concurrency performance comparison of maps
//        Int concurrency = 4;
//        Int keys = 1_000;
//        Int iterations = 1000_000;
//        for (Int i : 0..3)
//            {
//            console.println("Concurrent load test of HashMap...");
//            testConcurrentLoad(new SafeHashMap(), concurrency, iterations, keys);
//            console.println("Concurrent load test of ConcurrentHashMap...");
//            testConcurrentLoad(new ConcurrentHashMap(), concurrency, iterations, keys);
//            }

//        for (UInt seed : 1..500)
//            {
//            log.add($"iteration #{seed}");
//            testRandomOps(new ConcurrentHashMap(), seed);
//            }
        }

    void testBasic(Map<Int, String> map)
        {
        console.println("\n** testBasic()");

        String one = "Hello from Map";
        String two = "Goodbye from Map";
        map.put(1, one);
        map.put(2, two);

        assert String s1 := map.get(1), s1 == one;
        assert String s2 := map.get(2), s2 == two;
        }

    void testEquals(Map<Int, String> map1)
        {
        map1.put(1, "v1");

        Map<Int, String> map2 = Map:[1="v1"];

        assert map1 == map2;
        }

    static void testFill100()
        {
        Map<Int, Int> map = new HashMap();
        for (Int i = 0; i < 100; i++)
            {
            map.put(i, i);
            }
        }

    void profile(function void () run, Int iterations)
        {
        timer.reset();
        for (Int i = 0; i < iterations; i++)
            {
            run();
            }
        Duration time = timer.elapsed;
        console.println($"Elapsed {time.milliseconds} ms");
        console.println($"Latency {(time / iterations).milliseconds} ms");
        }

    void testListMap()
        {
        console.println("\n** testListMap()");

        Map<String, String> map = new ListMap();
        console.println($"empty map={map}");

        console.println("adding entries...");
        map["k1"] = "v1";
        map["k2"] = "v2";

        console.println($"map.size={map.size}, map.empty={map.empty}");
        console.println($"keys.size={map.keys.size}");
        console.println($"entries.size={map.entries.size}");
        console.println($"values.size={map.values.size}");
        console.println($"map={map}");

        console.println("keys/values:");
        loop: for (String key : map.keys)
            {
            console.println($"[{loop.count}]:{key}={map[key]}");
            }

        // same thing, but using "$" syntax
        console.println($"keys:{{L: for (val v : map.keys) {$.addAll($"\n[{L.count}]={v}");}}}");

        console.println("values:");
        loop: for (String value : map.values)
            {
            console.println($"[{loop.count}]:{value}");
            }

        console.println("entries:");
        loop: for (Map<String,String>.Entry entry : map.entries)
            {
            console.println($"[{loop.count}]:{entry.key}={entry.value}");
            }

        // test very bad hashing
        const Point(Int x)
            {
            static <CompileType extends Point> Int hashCode(CompileType value)
                {
                return 100 + value.x % 3;
                }
            }

        ListMap<Point, Int> map2 = new ListMap();
        for (Int i : [0..12))
            {
            map2.put(new Point(i), i);
            }

        for (Int i : [0..12))
            {
            assert Int v := map2.get(new Point(i));
            assert v == i;
            }

        for (Int i : [0..12))
            {
            map2.remove(new Point(i));
            map2.put(new Point(12 + i), 12 + i);
            }

        for (Int i : [12..24))
            {
            assert Int v := map2.get(new Point(i));
            assert v == i;
            }
        }

    void testMapIteration(Map<String, Int> map)
        {
        console.println($"\n** testMapIteration({&map.actualType.underlyingTypes[0]})");

        map.put("hello", 1);
        map.put("goodbye", 2);

        console.println("keys:");
        for (String key : map)
            {
            console.println($"{key}");
            }

        console.println("keys and values:");
        for ((String s, Int i) : map)
            {
            console.println($"{s} = {i}");
            }

        console.println("values:");
        for (Int i : map.values)
            {
            console.println($"? = {i}");
            }
        }

    void testMapStableIteration(Map<Int, Int> map)
        {
        for (Int i : 0..10)
            {
            map[i] = i + 1;
            }

        Iterator<Map<Int, Int>.Entry> iter = map.entries.iterator();
        Map<Int, Int> control = new HashMap();
        if (Map<Int, Int>.Entry next := iter.next())
            {
            assert(!control.contains(next.key));
            control.put(next.key, next.value);
            }

        for (Int i : 11..100)
            {
            map[i] = i + 1;
            }

        for (Int i : 0..20)
            {
            if (Map<Int, Int>.Entry next := iter.next())
                {
                assert(!control.contains(next.key));
                control.put(next.key, next.value);
                }
            }

        for (Int i : 100..500)
            {
            map[i] = i;
            }

        while (Map<Int, Int>.Entry next := iter.next())
            {
            assert(!control.contains(next.key));
            control.put(next.key, next.value);
            }

        // verify that we at least saw all the original items from the time the
        // iterator was created
        for (Int i : 0..10)
            {
            assert(control.contains(i));
            }
        }

    void testFreezable()
        {
        console.println("\n** testFreezable()");

        Container c = new Container();
        Map<String, String> map = c.mapL;
        try
            {
            map.put("2", "b");
            assert;
            }
        catch (Exception e)
            {
            console.println($"Expected modify attempt: {e.text}");
            }
        console.println($"{c.mapL} {c.mapL.keys} {c.mapL.values}");
        console.println($"{c.mapH} {c.mapH.keys} {c.mapH.values}");
        console.println($"{c.mapS} {c.mapS.keys} {c.mapS.values}");

        try
            {
            NotFreezable nf = c.nf;
            }
        catch (Exception e)
            {
            console.println($"Expected not freezable: {e.text}");
            }

        const Container()
            {
            @Lazy
            Map<String, String> mapL.calc()
                {
                Map<String, String> map = new ListMap();
                map.put("1", "L");
                return map;
                }

            @Lazy
            Map<String, String> mapH.calc()
                {
                Map<String, String> map = new HashMap();
                map.put("1", "H");
                return map;
                }

            @Lazy
            Map<String, String> mapS.calc()
                {
                Map<String, String> map = new SkiplistMap();
                map.put("1", "S");
                return map;
                }

            @Lazy NotFreezable nf.calc()
                {
                return new NotFreezable(0);
                }
            }

        class NotFreezable(Int x);
        }

    static void testBasicOps(Map<String, String> map)
        {
        for (Int i : 0..14)
            {
            map.put($"key_{i}", $"val_{i}");
            }

        Int count = 0;
        for (String s : map)
            {
            ++count;
            }
        assert count == 15;

        for (Int i = 1; i < 14; i += 2)
            {
            map.remove($"key_{i}");
            }

        Int count2 = 0;
        for ((_, _) : map)
            {
            ++count2;
            }
        assert count2 == 8;
        }

    static void testRandomOps(Map<Int, Int> map, UInt seed)
        {
        Random rnd = new ecstasy.numbers.PseudoRandom(seed);

        Map<Int, Int> check = new HashMap();

        Int steps = rnd.int(1000) + 1;
        for (Int step : 0..steps)
            {
            switch (rnd.int(100)+1)
                {
                case 1..49:
                    for (Int i : 0..rnd.int(rnd.int(10)+1)+1)
                        {
                        Int k = rnd.int(1000);
                        Int v = rnd.int(1000);
                        map.put(k, v);
                        check.put(k, v);
                        }
                    break;

                case 50..59:
                    if (!check.empty)
                        {
                        Int[] keys = check.keys.toArray();
                        for (Int i : 0..rnd.int(rnd.int(20)+1)+1)
                            {
                            Int k = keys[rnd.int(keys.size)];
                            Int v = map.getOrDefault(k, -1);
                            assert v == check.getOrDefault(k, -1);
                            ++v;
                            map.put(k, v);
                            check.put(k, v);
                            }
                        }
                    break;

                case 60..69:
                    for (Int i : 0..rnd.int(rnd.int(100)+1)+1)
                        {
                        Int k = rnd.int(1000);
                        assert map.contains(k) == check.contains(k);
                        }
                    break;

                case 70..79:
                    if (!check.empty)
                        {
                        Int[] keys = check.keys.toArray();
                        for (Int i : 0..rnd.int(rnd.int(100)+1)+1)
                            {
                            Int k = keys[rnd.int(keys.size)];
                            assert map.getOrNull(k) == check.getOrNull(k);
                            }
                        }
                    break;

                case 80..89:
                    if (!check.empty)
                        {
                        Int[] keys = check.keys.toArray();
                        for (Int i : 0..rnd.int(rnd.int(40)+1)+1)
                            {
                            Int k = keys[rnd.int(keys.size)];
                            map.remove(k);
                            check.remove(k);
                            }
                        }
                    break;

                case 90..99:
                    for (Int i : 0..rnd.int(25)+1)
                        {
                        Int k = rnd.int(1000);
                        map.remove(k);
                        check.remove(k);
                        }
                    break;

                case 100:
                    map.clear();
                    check.clear();
                    break;

                default:
                    assert;
                }

            assert map == check;
            }
        }

    void testProcess(Map<Int, Int> map)
        {
        assert(map.processIfPresent(1, e -> e.value++) == False);

        map.put(1, 1);
        assert(map.processIfPresent(1, e -> ++e.value));
        assert(map.getOrNull(1) == 2);

        map.process(1, e -> {e.delete();});
        assert(map.contains(1) == False);

        try
            {
            map.process(1, e ->
                {
                TODO;
                });
            }
        catch (UnsupportedOperation e)
            {
            // expected
            }
        }

    void testConcurrentProcess(Map<Int, Int> map)
        {
        console.println($"\n** testConcurrentProcess({&map.actualClass.name})");
        map.put(0, 0);

        Int count = 0;

        // run a long running blocking processor in the background
        map.process^(0, e ->
            {
            @Inject Timer timer;
            @Future Int   result;
            timer.schedule(Duration:0.2s, () ->
                {
                result = 42;
                });

            Int r = result; // blocking
            console.println($"{++count}) process(0) {r}");
            e.value++;
            return result;
            });

        // write to an alternate key; should not block with CHM even on the same partition
        map.put(17, 1);
        console.println($"{++count}) put(17)");

        // read of the same key as long write; CHM should not block
        map.get(0);
        console.println($"{++count}) get(0)");

        try
            {
            Int ex = map.process(0, e ->
                {
                console.println($"{++count}) deferred process(0) throw");
                if (e.exists)
                    {
                    TODO;
                    }

                return 123;
                });

            assert;
            }
        catch (UnsupportedOperation e)
            {
            // expected
            }

        // write to the same key; CHM should block until original write completes
        map.put(0, 1);
        console.println($"{++count}) put(0)");

        // processor based write to the same key; CHM should also block
        Int n = map.process(0, e ->
            {
            console.println($"{++count}) process(0)");
            return ++e.value;
            });

        // verify that our second process didn't finish until after our
        // delayed first one on the same key
        assert n == 2;
        }

    void testConcurrentLoad(Map<Int, Int> map, Int concurrency, Int iterations, Int range)
        {

        timer.reset();

        Future[] futures = new Array(concurrency,
            i -> {
            Int n = new LoadGenerator().run^(map, iterations, i, range);
            return &n;
            });

        for (Future future : futures)
            {
            future.get();
            }

        Duration time = timer.elapsed;
        console.println($"Elapsed {time.milliseconds} ms");
        //console.println(map);
        }

    service LoadGenerator
        {
        @Inject Random rnd;

        public Int run(Map<Int, Int> map, Int iterations, Int seed, Int range)
            {
            for (Int i : 0..iterations)
                {
//                map.process(rnd.int(range), e ->
//                    {
//                    e.value = e.exists ? e.value + 1 : 1;
//                    });
//                map.put(rnd.int(range), 42);
                map.get(rnd.int(range));
                }

            serviceControl.shutdown();
            return 0;
            }
        }

    service SafeHashMap<Key, Value>
        extends HashMap<Key, Value>
        {
        }

    static DateTime now()
        {
        @Inject Clock clock;
        return clock.now;
        }
    }