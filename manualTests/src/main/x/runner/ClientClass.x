class Client%appSchema%
        extends imdb.ClientRootSchema
        implements %appName%.%appSchema%
        implements db.Connection<%appName%.%appSchema%>
    {
    // custom property type declarations
    // example:
    //     @Override
    //     @Unassigned AddressBookDB.Contacts contacts;
    %ClientPropertyDeclarations%

    construct()
        {
        construct imdb.ClientRootSchema(Server%appSchema%);
        }
    finally
        {
        // custom schema property construction
        // example:
        //    contacts = new ClientContacts(ServerAddressBookSchema.contacts);
        %ClientPropertyConstruction%
        }

    @Override
    @Unassigned db.DBUser dbUser;

    @Override
    public/protected ClientTransaction? transaction;

    @Override
    ClientTransaction createTransaction(
                Duration? timeout = Null, String? name = Null,
                UInt? id = Null, db.DBTransaction.Priority priority = Normal,
                Int retryCount = 0)
        {
        ClientTransaction tx = new ClientTransaction();
        transaction = tx;
        return tx;
        }


    // custom ClientDB* classes
    // example:
    // class ClientContacts
    //      extends imdb.ClientDBMap<String, Contact>
    //      incorporates Contacts
    %ClientChildrenClasses%

    class ClientTransaction
            extends imdb.ClientTransaction<%appName%.%appSchema%>
            implements %appName%.%appSchema%
        {
        construct()
            {
            construct imdb.ClientTransaction(
                Server%appSchema%, Server%appSchema%.createDBTransaction());
            }

        @Override
        db.SystemSchema sys.get()
            {
            TODO
            }

        @Override
        (db.Connection<%appName%.%appSchema%> + %appName%.%appSchema%) connection.get()
            {
            return this.Client%appSchema%;
            }

        %ClientTxPropertyGetters%

        @Override
        Boolean pending.get()
            {
            return this.Client%appSchema%.transaction == this;
            }

        @Override
        Boolean commit()
            {
            try
                {
                return super();
                }
            finally
                {
                this.Client%appSchema%.transaction = Null;
                }
            }

        @Override
        void rollback()
            {
            try
                {
                super();
                }
            finally
                {
                this.Client%appSchema%.transaction = Null;
                }
            }
        }
    }