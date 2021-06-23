module TestSimple.test.org
    {
    @Inject Console console;

    void run()
        {
        TestService svc = new TestService();

//        console.println(testThenDo(svc));
//        console.println(testPassTo(svc));
//        console.println(testTransform(svc));
        console.println(testTransformOrHandle(svc));
//        console.println(testHandle(svc));
//        console.println(testWhen(svc));
//        console.println(testOr(svc));
        console.println(testAnd(svc));
        }

    Int testThenDo(TestService svc)
        {
        @Future Int i1 = svc.spin(1000);
        @Future Int i2 = &i1.thenDo(() -> report(2)); // negative value should stop the chain
        @Future Int i3 = &i2.thenDo(() -> report(3));

        Int result = i3;
        &i3.thenDo(() -> report(4)); // synchronous

        return result;
        }

    Int testPassTo(TestService svc)
        {
        @Future Int i1 = svc.spin(1000);
        @Future Int i2 = &i1.passTo((r) -> report(r + 1)); // negative value should stop the chain
        @Future Int i3 = &i2.passTo((r) -> report(r + 2));

        Int result = i3;
        &i3.passTo((r) -> report(r + 3)); // synchronous

        return result;
        }

    Int testTransform(TestService svc)
        {
        @Future Int    i1 = svc.spin(1000);
        @Future String s2 = &i1.transform((r) -> $"transform {r}");

        console.println(s2);
        return i1;
        }

    Int testTransformOrHandle(TestService svc)
        {
        @Future Int    i1 = svc.spin(1000);
        @Future Int    i2 = &i1.passTo((r) -> report(-r));
        @Future String s2 = &i2.transformOrHandle((r, e) ->
                                e == Null ? $"transform {r}" : $"handle {e.text}");

        console.println(s2);
        return i1;
        }

    Int testHandle(TestService svc)
        {
        @Future Int i1 = svc.spin(1000);
        @Future Int i2 = &i1.thenDo(() -> report(-1));
        @Future Int i3 = &i2.handle((ex) -> 42);

        return i3;
        }

    Int testWhen(TestService svc)
        {
        @Future Int i1 = svc.spin(1000);
        @Future Int i2 = &i1.whenComplete((r, x) -> report(1 + r ?: -1));
        @Future Int i3 = &i2.whenComplete((r, x) -> report(2 + r ?: -1));

        Int result = i3;
        &i3.whenComplete((r, x) -> report(3 + r ?: -1)); // synchronous

        return result;
        }

    Int testOr(TestService svc)
        {
        @Future Int i1 = svc.calcSomethingBig(Duration.ofMillis(200));
        @Future Int i2 = svc.calcSomethingBig(Duration.ofMillis(100));

        @Future Int i3 = &i1.or(&i2);
        @Future Int i4 = &i3.passTo((r) -> report(r));

        return i4;
        }

    Int testAnd(TestService svc)
        {
        @Future Int i1 = svc.spin(1000);
        @Future Int i2 = svc.calcSomethingBig(Duration.ofMillis(100));

        function Int (Int, Int) combine = (r1, r2) -> (r1 + r2);
        @Future Int i3 = &i1.and(&i2, combine);
        @Future Int i4 = &i3.passTo((r) -> report(r));

        return i4;
        }

    void report(Int n)
        {
        if (n < 0)
            {
            throw new Exception($"report {n}");
            }
        console.println($"report {n}");
        }

    service TestService
        {
        Int calcSomethingBig(Duration delay)
            {
            @Inject Console console;

            @Inject Timer timer;
            @Future Int   result;
            timer.schedule(delay, () ->
                {
                result=delay.milliseconds;
                });

            return result;
            }

        Int spin(Int iters)
            {
            Int sum = 0;
            for (Int i : iters..1)
                {
                sum += i;
                }

            return sum;
            }
        }
    }