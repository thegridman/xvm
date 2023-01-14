module TestSimple
    {
    @Inject Console console;

    void run()
        {
        IntN prime1=0x00e7c48745a89a1c6217b418a828afa064f7ed5873c4fa9be7086890d6c765f53315ca24d4aa948b15964d5e12ddf2c78a27d8fb81b8c5fdb051713792d8515f432dc515ba3a0afdef3ba026503a794f92e65f12a4a29eeabfe732c0ecfd5071d056736f3b4ffe79216e813d0603410e971b2a7ee3a6e83b532f2c27988da56e6f;
        IntN prime2=0x00c9266748c7b88c9f513777f6ad6d966882e63badfee22d0c78c7296c225af9be83f35f8ee395b1d0715380149850d8cb5d1abed4dc3586669a822638f51a4ddc56f978ec67bb8d24e4a318acd60b76aadfb05fa875835700d643bea723368089eacd4bb5e6cbdb3f8508c9b8637816f446ad1645878aaa8484c4dc19ff1c5faf;
        IntN factor=prime1*prime2;
        console.println(factor);
        assert factor/prime1 == prime2;
        assert factor/prime2 == prime1;
        }
    }