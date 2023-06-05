import model.DboInfo;
import model.Lock;
import model.SysInfo;

import json.Mapping;

import oodb.DBCounter;
import oodb.DBInfo;
import oodb.DBList;
import oodb.DBLog;
import oodb.DBMap;
import oodb.DBObject;
import oodb.DBProcessor;
import oodb.DBProcessor.Pending;
import oodb.DBQueue;
import oodb.DBSchema;
import oodb.DBTransaction;
import oodb.DBUser;
import oodb.DBValue;
import oodb.Permission;
import oodb.RootSchema;

import oodb.model.User;
import oodb.DBObjectInfo as OOObjectInfo;

import storage.JsonCounterStore;
import storage.JsonMapStore;
import storage.JsonNtxCounterStore;
import storage.JsonNtxLogStore;
import storage.JsonLogStore;
import storage.JsonProcessorStore;
import storage.JsonValueStore;
import storage.ObjectStore;
import storage.SchemaStore;


/**
 * Metadata catalog for a database. A `Catalog` acts as the "gateway" to a JSON database, allowing a
 * database to be created, opened, examined, recovered, upgraded, and/or deleted.
 *
 * A `Catalog` is instantiated as a combination of a database module which provides the model (the
 * Ecstasy representation) for the database, and a filing system directory providing the storage for
 * the database's data. The `Catalog` does not require the module to be provided; it can be omitted
 * so that a database on disk can be examined and (to a limited extent) manipulated/repaired without
 * explicit knowledge of its Ecstasy representation.
 *
 * The `Catalog` has a weak notion of mutual exclusion, designed to avoid database corruption that
 * could occur if two instances attempted to open the same database in a read/write mode:
 *
 * * A file [statusFile] contains a status that indicates whether a Catalog instance may already be
 *   [Configuring](Status.Configuring), [Running](Status.Running), or
 *   [Recovering](Status.Recovering)
 * * The absence of a status file, or a status file with the [Closed](Status.Closed) status
 *   indicates that the Catalog is not in use.
 * * If a crash occurs while the Catalog is in use, the status file may still indicate that the
 *   Catalog is in use after the crash; this requires the Catalog to be recovered using the
 *   [recover] method.
 * * Transitions of the status file itself are guarded by using a second lock file (relying on the
 *   atomicity of file creation), whose temporary existence indicates that a status file transition
 *   is in progress.
 *
 * TODO version - should only be able to open the catalog with the correct TypeSystem version
 */
service Catalog<Schema extends RootSchema>
        implements Closeable {

    typedef (Client.Connection + Schema) as Connection;

    // ----- constructors --------------------------------------------------------------------------

    /**
     * Open the catalog for the specified directory.
     *
     * @param dir       the directory that contains (or may contain) the catalog
     * @param metadata  (optional) the `CatalogMetadata` for this `Catalog`; if the metadata is not
     *                  provided, then the `Catalog` can only operate on the database as a raw JSON
     *                  data store
     * @param readOnly  (optional) pass `True` to access the catalog in a read-only manner
     */
    construct(Directory dir, CatalogMetadata<Schema>? metadata = Null, Boolean readOnly = False) {
        assert:arg dir.exists && dir.readable && (readOnly || dir.writable);
        assert metadata != Null || Schema == RootSchema;

        this.timestamp   = clock.now;
        this.dir         = dir;
        this.metadata    = metadata;
        this.version     = metadata?.version : Null;
        this.readOnly    = readOnly;
        this.status      = Closed;
    }


    // ----- built-in system schema ----------------------------------------------------------------

    /**
     * An enumeration of built-in (system) database objects.
     */
    enum BuiltIn<ObjectType> {
        Root<DBSchema>,
        Sys<DBSchema>,
        Info<DBValue<DBInfo>>,
        Users<DBMap<String, DBUser>>,
        Types<DBMap<String, Type>>,
        Objects<DBMap<String, DBObject>>,
        Schemas<DBMap<String, DBSchema>>,
        Counters<DBMap<String, DBCounter>>,
        Values<DBMap<String, DBValue>>,
        Maps<DBMap<String, DBMap>>,
        Queues<DBMap<String, DBQueue>>,
        Lists<DBMap<String, DBList>>,
        Processors<DBMap<String, DBProcessor>>,
        Logs<DBMap<String, DBLog>>,
        Pending<DBList<Pending>>,
        Transactions<DBLog<DBTransaction>>,
        Errors<DBLog<String>>,
        TxCounter<DBCounter>,
        PidCounter<DBCounter>,
        ;

        /**
         * The internal id of the built-in database object. The root schema is 0, while the rest of
         * the built-in database objects use negative ids.
         */
        Int id.get() {
            return -ordinal;
        }

        /**
         * The DboInfo for the built-in database object.
         */
        DboInfo info.get() {
            return SystemInfos[ordinal];
        }

        /**
         * Obtain the BuiltIn enum value for the specified built-in database object id.
         *
         * @param the built-in id
         *
         * @return the BuiltIn value representing the built-in database object
         */
        static BuiltIn byId(Int id) {
            assert id <= 0 && id + BuiltIn.count > 0;
            return BuiltIn.values[-id];
        }
    }

    static DboInfo[] SystemInfos =
        [
        new DboInfo(ROOT, DBSchema, BuiltIn.Root.id, BuiltIn.Root.id,
            [BuiltIn.Sys.id], [BuiltIn.Sys.name], transactional = False),

        new DboInfo(Path:/sys, DBSchema, BuiltIn.Sys.id,  BuiltIn.Root.id,
            [
            BuiltIn.Info.id,
            BuiltIn.Users.id,
            BuiltIn.Types.id,
            BuiltIn.Objects.id,
            BuiltIn.Schemas.id,
            BuiltIn.Counters.id,
            BuiltIn.Values.id,
            BuiltIn.Maps.id,
            BuiltIn.Lists.id,
            BuiltIn.Queues.id,
            BuiltIn.Processors.id,
            BuiltIn.Logs.id,
            BuiltIn.Pending.id,
            BuiltIn.Transactions.id,
            BuiltIn.Errors.id,
            BuiltIn.TxCounter.id,
            BuiltIn.PidCounter.id,
            ],
            [
            BuiltIn.Info.name,
            BuiltIn.Users.name,
            BuiltIn.Types.name,
            BuiltIn.Objects.name,
            BuiltIn.Schemas.name,
            BuiltIn.Counters.name,
            BuiltIn.Values.name,
            BuiltIn.Maps.name,
            BuiltIn.Lists.name,
            BuiltIn.Queues.name,
            BuiltIn.Processors.name,
            BuiltIn.Logs.name,
            BuiltIn.Pending.name,
            BuiltIn.Transactions.name,
            BuiltIn.Errors.name,
            BuiltIn.TxCounter.name,
            BuiltIn.PidCounter.name,
            ],
            transactional = False),

        new DboInfo(Path:/sys/info,         DBValue,   BuiltIn.Info.id,         BuiltIn.Sys.id, typeParamsTypes=["Value"=DBInfo]),
        new DboInfo(Path:/sys/users,        DBMap,     BuiltIn.Users.id,        BuiltIn.Sys.id, typeParamsTypes=["Key"=String, "Value"=DBUser]),
        new DboInfo(Path:/sys/types,        DBMap,     BuiltIn.Types.id,        BuiltIn.Sys.id, typeParamsTypes=["Key"=String, "Value"=Type]),
        new DboInfo(Path:/sys/objects,      DBMap,     BuiltIn.Objects.id,      BuiltIn.Sys.id, typeParamsTypes=["Key"=String, "Value"=DBObject]),
        new DboInfo(Path:/sys/schemas,      DBMap,     BuiltIn.Schemas.id,      BuiltIn.Sys.id, typeParamsTypes=["Key"=String, "Value"=DBSchema]),
        new DboInfo(Path:/sys/counters,     DBMap,     BuiltIn.Counters.id,     BuiltIn.Sys.id, typeParamsTypes=["Key"=String, "Value"=DBCounter]),
        new DboInfo(Path:/sys/values,       DBMap,     BuiltIn.Values.id,       BuiltIn.Sys.id, typeParamsTypes=["Key"=String, "Value"=DBValue]),
        new DboInfo(Path:/sys/maps,         DBMap,     BuiltIn.Maps.id,         BuiltIn.Sys.id, typeParamsTypes=["Key"=String, "Value"=DBMap]),
        new DboInfo(Path:/sys/lists,        DBMap,     BuiltIn.Lists.id,        BuiltIn.Sys.id, typeParamsTypes=["Key"=String, "Value"=DBList]),
        new DboInfo(Path:/sys/queues,       DBMap,     BuiltIn.Queues.id,       BuiltIn.Sys.id, typeParamsTypes=["Key"=String, "Value"=DBQueue]),
        new DboInfo(Path:/sys/processors,   DBMap,     BuiltIn.Processors.id,   BuiltIn.Sys.id, typeParamsTypes=["Key"=String, "Value"=DBProcessor]),
        new DboInfo(Path:/sys/logs,         DBMap,     BuiltIn.Logs.id,         BuiltIn.Sys.id, typeParamsTypes=["Key"=String, "Value"=DBLog]),
        new DboInfo(Path:/sys/pending,      DBList,    BuiltIn.Pending.id,      BuiltIn.Sys.id, typeParamsTypes=["Element"=Pending]),
        new DboInfo(Path:/sys/transactions, DBLog,     BuiltIn.Transactions.id, BuiltIn.Sys.id, typeParamsTypes=["Element"=DBTransaction]),
        new DboInfo(Path:/sys/errors,       DBLog,     BuiltIn.Errors.id,       BuiltIn.Sys.id, typeParamsTypes=["Element"=String]),
        new DboInfo(Path:/sys/txCounter,    DBCounter, BuiltIn.TxCounter.id,    BuiltIn.Sys.id, transactional=False),
        new DboInfo(Path:/sys/pidCounter,   DBCounter, BuiltIn.PidCounter.id,   BuiltIn.Sys.id, transactional=False),
        ];

    /**
     * Default "system" user.
     */
    static protected User DefaultUser = new User(0, "sys",
            permissions = [new Permission(AllTargets, AllActions)]);


    // ----- properties ----------------------------------------------------------------------------

    @Concurrent
    @Inject Clock clock;

    /**
     * The timestamp from when this Catalog was created; used as an assumed-unique identifier.
     */
    @Concurrent
    public/private Time timestamp;

    /**
     * The directory used to store the contents of the database
     */
    @Concurrent
    public/private Directory dir;

    /**
     * The optional catalog metadata for this catalog. This information is typically created by a
     * code generation process that takes as its input an application's "@Database" module, and
     * emits as output a new module that provides a custom binding of the application's "@Database"
     * module to the `jsondb` implementation of the `oodb` database API.
     */
    @Concurrent
    public/private CatalogMetadata<Schema>? metadata;

    /**
     * The JSON Schema to use.
     */
    @Concurrent
    @Lazy json.Schema jsonSchema.calc() {
        return metadata?.jsonSchema : json.Schema.DEFAULT;
    }

    /**
     * The JSON Schema to use for the various classes in the database implementation itself.
     */
    @Concurrent
    @Lazy json.Schema internalJsonSchema.calc() {
        return new json.Schema(
            enableReflection = True,
            enableMetadata   = True,
            randomAccess     = True,     // TODO test without this (fails)
            );
    }

    /**
     * A JSON Mapping to use to serialize instances of SysInfo.
     */
    @Concurrent
    @Lazy Mapping<SysInfo> sysInfoMapping.calc() {
        return internalJsonSchema.ensureMapping(SysInfo);
    }

    /**
     * True iff the database was opened in read-only mode.
     */
    @Concurrent
    public/private Boolean readOnly;

    /**
     * The version of the database represented by this `Catalog` object. The version may not be
     * available before the database is opened.
     */
    @Concurrent
    public/private Version? version;

    /**
     * The status of this `Catalog` service. Note that the database status itself may differ from
     * this Catalog's status, since the database may be in use elsewhere (by another instance of
     * the Catalog service), or it may have previously crashed. In the first case (of the database
     * being in use elsewhere), this Catalog will have a `Closed` status, but the database status is
     * probably "Running". In the second case (of a previous db crash), this Catalog will have a
     * `Closed` status, the database status (as it claims on disk) would probably be "Running", and
     * the "real" database status would be "Closed" (since it crashed and isn't running).
     *
     * * `Closed` - This `Catalog` object has not yet been opened, or it has been shut down.
     * * `Configuring` - This `Catalog` object has the database open for schema definition and
     *   modification, or other maintenance work.
     * * `Running` - This `Catalog` object has the database open for data access.
     * * `Recovering` - This `Catalog` object has been instructed to recover the database.
     */
    enum Status {Closed, Recovering, Configuring, Running}

    /**
     * The status of this `Catalog` object.
     */
    @Atomic public/private Status status;

    /**
     * The ObjectStore for each DBObject in the `Catalog`. These provide the I/O for the database.
     *
     * This data is available from the catalog through various methods; the array itself is not
     * exposed in order to avoid any concerns related to transmitting it through service boundaries.
     */
    protected/private ObjectStore?[] appStores = new ObjectStore?[];

    /**
     * The ObjectStore for each DBObject in the system schema. These are read-only stores that
     * provide a live view of the database metadata and status.
     */
    protected/private ObjectStore?[] sysStores = new ObjectStore?[];

    /**
     * The transaction manager for this `Catalog` object. The transaction manager provides a
     * sequential ordered (non-concurrent) application of potentially concurrent transactions.
     */
    @Concurrent
    @Lazy public/private TxManager txManager.calc() {
        return new TxManager(this);
    }

    /**
     * The process scheduler for this `Catalog` object. The scheduler supports the asynchronous
     * processing by the database.
     */
    @Concurrent
    @Lazy public/private Scheduler scheduler.calc() {
        return new Scheduler(this);
    }

    /**
     * The existing client representations for this `Catalog` object. Each client may have a single
     * Connection representation, and each Connection may have a single Transaction representation.
     */
    protected/private Map<Int, Client> clients = new HashMap();

    /**
     * The number of clients created by this Catalog. Used as the generator for client IDs.
     */
    protected Int clientCounter = 0;

    /**
     * The number of internal (system) clients created by this Catalog. Used as the generator for
     * internal client IDs.
     */
    protected Int systemCounter = 0;

    /**
     * The time that the database appears to have been idle since; otherwise, `Null`.
     */
    protected Time? idleSince;


    // ----- visibility ----------------------------------------------------------------------------

    @Override
    @Concurrent
    String toString() {
        return $|{this:class.name}:\{dir={dir}, version={version}, status={status},\
                | readOnly={readOnly}, unique-id={timestamp}}
                ;
    }


    // ----- support ----------------------------------------------------------------------------

    /**
     * A helper method for opening the database, recovering or creating the database if necessary.
     *
     * @param dbModuleName  the database module name used for logging
     */
    void ensureOpenDB(String dbModuleName) {
        Boolean success = False;
        try {
            success = open();
        } catch (IllegalState e) {
            log($"Failed to open the catalog for \"{dbModuleName}\"; reason={e.text}");
        }

        if (!success) {
            // failed to open; try to recover
            try {
                recover();
                success = True;
            } catch (IllegalState e) {
                log($"Failed to recover the catalog for \"{dbModuleName}\"; reason={e.text}");
            }
        }

        if (!success) {
            // failed to recover; try to create
            create(dbModuleName);
            assert open() as $"Failed to create the catalog for \"{dbModuleName}\"";
        }
    }

    /**
     * An error and message log for the database.
     */
    @Concurrent
    void log(String msg) {
        // TODO
        @Inject Console console;
        console.print($"*** {msg}");
    }

    /**
     * Obtain the DboInfo for the specified id.
     *
     * @param id  the internal object id
     *
     * @return the DboInfo for the specified id
     */
    @Concurrent
    DboInfo infoFor(Int id) {
        if (id < 0) {
            return BuiltIn.byId(id).info;
        }

        if (CatalogMetadata metadata ?= this.metadata) {
            if (id == 0) {
                private DboInfo? root = Null;
                return root?;

                DboInfo raw = metadata.dbObjectInfos[0];
                Int          sys = BuiltIn.Sys.id;
                if (!raw.childIds.contains(sys)) {
                    raw = raw.withChild(BuiltIn.Sys.info);
                }
                root = raw;
                return raw;
            }

            return metadata.dbObjectInfos[id];
        }

        TODO("create DboInfo"); // TODO
    }

    /**
     * Obtain the DboInfo for the specified name or path.
     *
     * @param path  the path from the root to the DBObject; "/" indicates the root
     *
     * @return the DboInfo for the specified path
     */
    @Concurrent
    DboInfo infoFor(String path) {
        DboInfo current = infoFor(0); // ROOT

        NextPathSegment: for (String name : path.split('/')) {
            if (name == "" && NextPathSegment.first) {
                continue NextPathSegment;
            }

            for (Int childId : current.childIds) {
                DboInfo child = infoFor(childId);
                if (child.name == name) {
                    current = child;
                    continue NextPathSegment;
                }
            }

            assert:arg as $"Missing DboInfo for {name.quoted()} in path {path.quoted()}";
        }

        return current;
    }

    /**
     * Obtain the ObjectStore for the specified id.
     *
     * @param id  the internal object id
     *
     * @return the ObjectStore for the specified id
     */
    @Concurrent
    ObjectStore storeFor(Int id) {
        ObjectStore?[] stores = appStores;
        Int            index  = id;
        if (id < 0) {
            stores = sysStores;
            index  = BuiltIn.byId(id).ordinal;
        }

        Int size = stores.size;
        if (index < size) {
            return stores[index]?;
        }

        using (new SynchronizedSection()) {
            if (index < stores.size) {
                return stores[index]?;
            }

            // create the ObjectStore
            ObjectStore store = createStore(id);

            // whatever state the Catalog is in, the ObjectStore has to be "caught up" to that state
            switch (status) {
            case Closed:
                break;

            case Recovering:
                if (!store.recover()) {
                    throw new IllegalState($"Failed to recover \"{store.info.name}\" store at {store.path}");
                }
                break;

            case Configuring:
                TODO

            case Running:
                if (!store.open()) {
                    throw new IllegalState($"Failed to open \"{store.info.name}\" store at {store.path}");
                }
                break;
            }

            // save off the ObjectStore (lazy cache)
            stores[index] = store;

            return store;
        }
    }

    /**
     * Create an ObjectStore for the specified internal database object id.
     *
     * @param id  the internal object id
     *
     * @return the new ObjectStore
     */
    @Concurrent
    protected ObjectStore createStore(Int id) {
        DboInfo info = infoFor(id);
        if (id <= 0) {
            return switch (BuiltIn.byId(id)) {
                case Root:
                case Sys:          new SchemaStore(this, info);

//                case Info:         TODO
// TODO the following 3 maps might end up being custom, hard-wired, read-only implementations
//                case Users:        new JsonMapStore<String, DBUser>(this, info, log);
//                case Types:        new JsonMapStore<String, Type>(this, info, log);

                case Objects:
                case Schemas:
                case Counters:
                case Values:
                case Maps:
                case Lists:
                case Queues:
                case Processors:
                case Logs:
                    assert;

//                case Pending:      TODO new ListStore<Pending>();
//                case Transactions: TODO new LogStore<DBTransaction>();
//                case Errors:       TODO new LogStore<String>();

                case TxCounter:    new JsonNtxCounterStore(this, info);
                case PidCounter:   new JsonNtxCounterStore(this, info);
                default:           assert as $"unsupported id={id}, BuiltIn={BuiltIn.byId(id)}, info={info}";
            };
        } else {
            switch (info.category) {
            case DBSchema:
                assert;

            case DBCounter:
                return createCounterStore(info);

            case DBValue:
                return createValueStore(info);

            case DBMap:
                return createMapStore(info);

            case DBList:
                TODO

            case DBQueue:
                TODO

            case DBProcessor:
                return createProcessorStore(info);

            case DBLog:
                return createLogStore(info);
            }
        }
    }

    @Concurrent
    private ObjectStore createMapStore(DboInfo info) {
        Type keyType = info.typeParams[0].type;
        Type valType = info.typeParams[1].type;

        assert keyType.is(Type<immutable Const>);
        assert valType.is(Type<immutable Const>);

        return new JsonMapStore<keyType.DataType, valType.DataType>(this, info,
                jsonSchema.ensureMapping(keyType).as(Mapping<keyType.DataType>),
                jsonSchema.ensureMapping(valType).as(Mapping<valType.DataType>));
    }

    @Concurrent
    private ObjectStore createCounterStore(DboInfo info) {
        return info.transactional
                ? new JsonCounterStore(this, info)
                : new JsonNtxCounterStore(this, info);
    }

    @Concurrent
    private ObjectStore createValueStore(DboInfo info) {
        Type valueType = info.typeParams[0].type;
        assert valueType.is(Type<immutable Const>);

        assert Object initial := info.options.get("initial");

        return new JsonValueStore<valueType.DataType>(this, info,
                jsonSchema.ensureMapping(valueType).as(Mapping<valueType.DataType>),
                initial.as(valueType.DataType));
    }

    @Concurrent
    private ObjectStore createLogStore(DboInfo info) {
        Type elementType = info.typeParams[0].type;
        assert elementType.is(Type<immutable Const>);

        Mapping<elementType.DataType> elementMapping =
                jsonSchema.ensureMapping(elementType).as(Mapping<elementType.DataType>);

        Map<String, immutable Object> options = info.options;

        Duration expiry     = options.getOrDefault("expiry", Duration.NONE).as(Duration);
        Int      truncate   = options.getOrDefault("truncate", Int:-1).as(Int);
        Int      maxLogSize = txManager.maxLogSize;

        return info.transactional
                ? new JsonLogStore<elementType.DataType>
                    (this, info, elementMapping, expiry, truncate, maxLogSize)
                : new JsonNtxLogStore<elementType.DataType>
                    (this, info, elementMapping, expiry, truncate, maxLogSize);
    }

    @Concurrent
    private ObjectStore createProcessorStore(DboInfo info) {
        Type messageType = info.typeParams[0].type;
        assert messageType.is(Type<immutable Const>);

        return new JsonProcessorStore<messageType.DataType>(this, info,
                jsonSchema.ensureMapping(messageType).as(Mapping<messageType.DataType>));
    }

    /**
     * Called to indicate that the database appears to be idle.
     */
    void indicateIdle() {
        if (idleSince == Null) {
            // we were busy but now we're idle
            idleSince = clock.now;
            scheduler.databaseIdle = True;
        }
    }

    /**
     * Called to indicate that the database appears to be busy.
     */
    void indicateBusy() {
        if (idleSince != Null) {
            // we were idle but now we're busy
            idleSince = Null;
            scheduler.databaseIdle = False;
        }
    }


    // ----- status management ---------------------------------------------------------------------

    /**
     * The file used to store the "in-use" status for the database.
     */
    @Concurrent
    @Lazy File statusFile.calc() {
        return dir.fileFor("sys.json");
    }

    /**
     * For an empty `Catalog` that is `Closed`, initialize the directory and file structures so that
     * a catalog exists in the previously specified directory. After creation, the `Catalog` will be
     * in the `Configuring` status, allowing the caller to populate the database schema.
     *
     * @param name  the name of the database to create
     *
     * @throws IllegalState  if the Catalog is not `Empty`, or is read-only
     */
    @Synchronized
    void create(String name) {
        transition(Closed, Configuring, snapshot -> snapshot.empty);
    }

    /**
     * For an existent database, if this `Catalog` is `Closed`, `Recovering`, or `Running`, then
     * transition to the `Configuring` state, allowing modifications to be made to the database
     * structure.
     *
     * @throws IllegalState  if the Catalog is not `Closed` or `Running`, or is read-only
     */
    @Synchronized
    void edit() {
        transition([Closed, Recovering, Running], Configuring, snapshot -> !snapshot.empty && !snapshot.lockedOut);
    }

    /**
     * For an existent database, if this `Catalog` is locked-out, then assume that the previous
     * owner terminated, take ownership of the database and verify its integrity.
     *
     * @throws IllegalState  if the Catalog is not locked-out or `Closed`
     */
    @Synchronized
    void recover() {
        transition(Closed, Recovering, snapshot -> !snapshot.empty || sysDir.exists, ignoreLock = True);

        Boolean success = False;
        Recovery: try {
            success = txManager.enable(recover=True);
        } finally {
            if (!success) {
                close();
                throw Recovery.exception ?: assert as "Recovery failed";
            }
        }

        transition(Recovering, Running, snapshot -> snapshot.owned);

        StartScheduling: try {
            success = scheduler.enable();
        } finally {
            if (!success) {
                close();
                throw StartScheduling.exception ?: assert as "Scheduler failed to start after recovery";
            }
        }
    }

    /**
     * For an existent database, if this `Catalog` is `Closed`, `Recovering`, or `Configuring`, then
     * transition to the `Running` state, allowing access and modification of the database contents.
     *
     * @return True iff the catalog is `Open`
     *
     * @throws IllegalState  if the Catalog is not `Closed`, `Recovering`, or `Configuring`
     */
    @Synchronized
    Boolean open() {
        transition([Closed, Recovering, Configuring], Running,
                snapshot -> snapshot.owned || snapshot.unowned,
                allowReadOnly = True);

        if (!txManager.enable()) {
            close();
            return False;
        }

        if (!scheduler.enable()) {
            close();
            return False;
        }
        return True;
    }

    /**
     * Close this `Catalog`.
     */
    @Override
    @Synchronized
    void close(Exception? cause = Null) {
        switch (status) {
        case Configuring:
        case Recovering:
            transition(status, Closed, snapshot -> snapshot.owned);
            break;

        case Running:
            scheduler.disable();
            txManager.disable();
            continue;
        case Closed:
            transition(status, Closed, snapshot -> snapshot.owned, allowReadOnly = True);
            break;

        default:
            assert;
        }
    }

    /**
     * For a `Catalog` that is `Configuring` or `Closed`, remove the entirety of the database. When
     * complete, the status will be `Closed`.
     *
     * @throws IllegalState  if the Catalog is not `Configuring` or `Closed`, or is read-only
     */
    @Synchronized
    void delete() {
        transition([Closed, Configuring], Configuring, snapshot -> snapshot.owned || snapshot.unowned);

        for (Directory subdir : dir.dirs()) {
            subdir.deleteRecursively();
        }

        for (File file : dir.files()) {
            file.delete();
        }

        transition(status, Closed, snapshot -> snapshot.empty);
    }

    /**
     * Validate that the current status matches the required status, optionally verify that the
     * Catalog is not read-only, and then with a lock in place, verify that the disk image also
     * matches that assumption. While holding that lock, optionally perform an operation, and then
     * update the status to the specified ,  (and the cor
     *
     * @param requiredStatus  one or more valid starting `Status` values
     * @param requiresWrite   `True` iff the Catalog is not allowed to be read-only
     * @param targetStatus    the ending `Status` to transition to
     * @param performAction   a function to execute while the lock is held
     *
     * @return True if the status has been changed
     */
    @Synchronized
    protected void transition(Status | Status[]         requiredStatus,
                              Status                    targetStatus,
                              function Boolean(Glance)? canTransition = Null,
                              Boolean                   allowReadOnly = False,
                              Boolean                   ignoreLock    = False) {
        Status oldStatus = status;
        if (requiredStatus.is(Status)) {
            assert oldStatus == requiredStatus;
        } else {
            assert requiredStatus.contains(oldStatus);
        }

        if (readOnly) {
            assert allowReadOnly;
            status = targetStatus;
        } else {
            using (val lock = lock(ignoreLock)) {
                // get a glance at the current status on disk, and verify that the requested
                // transition is legal
                Glance glance = glance();
                if (!canTransition?(glance)) {
                    throw new IllegalState($"Unable to transition {dir.path} from {oldStatus} to {targetStatus}");
                }

                // store the updated status
                status = targetStatus;

                // store the updated status (unless we're closing an empty database, in which case,
                // nothing gets stored)
                if (!(targetStatus == Closed && glance.empty)) {
                    statusFile.contents = toBytes(new SysInfo(this));
                }

                // TODO is this the correct place to transition all of the already-existent ObjectStore instances?
            }
        }
    }


    // ----- directory Glance ----------------------------------------------------------------------

    /**
     * A `Glance` is a snapshot view of the database status on disk, from the point of view of the
     * `Catalog` that makes the "glancing" observation of the directory containing the database.
     */
    const Glance(SysInfo? info, Lock? lock, Exception? error) {
        /*
         * True iff at the moment of the snapshot, the observing `Catalog` detected that the
         * directory did not appear to contain a configured database.
         */
        Boolean empty.get() {
            return error == Null && info == Null;
        }

        /**
         * True iff at the moment of the snapshot, the observing `Catalog` detected that the
         * directory was not owned.
         */
        Boolean unowned.get() {
            return error == Null && (info?.status == Closed : True);
        }

        /**
         * True iff at the moment of the snapshot, the observing `Catalog` detected that it (and
         * not some other `Catalog` instance) was the owner of the directory.
         */
        Boolean owned.get() {
            return error == Null && info?.status != Closed && info?.stampedBy == this.Catalog.timestamp : False;
        }

        /**
         * True iff at the moment of the snapshot, that the observing `Catalog` detected the
         * _possibility_ that the directory has already been opened by another `Catalog` instance,
         * and is currently in use. (It is also possible that the directory was open previously,
         * and a clean shut-down did not occur.)
         */
        Boolean lockedOut.get() {
            return error != Null || (info?.status != Closed && info?.stampedBy != this.Catalog.timestamp : False);
        }
    }

    /**
     * Create a snapshot `Glance` of the status of the database on disk.
     *
     * @return a point-in-time snap-shot of the status of the database on disk
     */
    @Synchronized
    Glance glance() {
        SysInfo?   info  = Null;
        Lock?      lock  = Null;
        Exception? error = Null;

        import ecstasy.fs.FileNotFound;

        Byte[]? bytes = Null;
        try {
            if (lockFile.exists) {
                // this is not an atomic operation, so a FileNotFound may still occur
                bytes = lockFile.contents;
            }
        } catch (FileNotFound e) {
            // it's ok for the lock file to not exist
        } catch (Exception e) {
            error = e;
        }

        try {
            lock = fromBytes(Lock, bytes?);
        } catch (Exception e) {
            error ?:= e;
        }

        bytes = Null;
        try {
            if (statusFile.exists) {
                // this is not an atomic operation, so a FileNotFound may still occur
                bytes = statusFile.contents;
            }
        } catch (FileNotFound e) {
            // it's ok for the status file to not exist
        } catch (Exception e) {
            error ?:= e;
        }

        try {
            info = fromBytes(SysInfo, bytes?);
        } catch (Exception e) {
            error ?:= e;
        }

        return new Glance(info, lock, error);
    }


    // ----- catalog lock and status file management -----------------------------------------------

    /**
     * The file used to indicate a short-term lock.
     */
    @Concurrent
    @Lazy File lockFile.calc() {
        return dir.fileFor("sys.lock");
    }

    /**
     * The directory containing the system schema data and other internal files.
     */
    @Concurrent
    @Lazy Directory sysDir.calc() {
        return dir.dirFor("sys");
    }

    /**
     * Obtain the lock on the catalog.
     *
     * @return a lock, which should be closed to release it
     */
    @Synchronized
    protected Closeable lock(Boolean ignorePreviousLock) {
        String           path  = lockFile.path.toString();
        Lock             lock  = new Lock(this);
        immutable Byte[] bytes = toBytes(lock);

        if (lockFile.exists && !ignorePreviousLock) {
            String msg = $"Lock file ({path}) already exists";
            try {
                Byte[] oldBytes = lockFile.contents;
                String text     = oldBytes.unpackUtf8();
                msg = $"{msg}; Catalog timestamp={timestamp}; lock file contains: {text}";
            } catch (Exception e) {
                throw new IllegalState(msg, e);
            }

            throw new IllegalState(msg);
        }

        if (!lockFile.create() && !ignorePreviousLock) {
            throw new IllegalState($"Failed to create lock file: {path}");
        }

        try {
            lockFile.contents = bytes;
        } catch (Exception e) {
            throw new IllegalState($"Failed to write lock file: {path}", e);
        }

        return new Closeable() {
            @Override void close(Exception? cause = Null) {
                lockFile.delete();
            }
        };
    }


    // ----- Client (Connection) management --------------------------------------------------------

    /**
     * Create a new database connection.
     *
     * @param dbUser  (optional) the database user that the connection will be created on behalf of;
     *                defaults to the database super-user
     */
    @Concurrent
    Connection createConnection(DBUser? dbUser = Null) {
        return createClient(dbUser).conn ?: assert;
    }

    /**
     * Create a `Client` that will access the database represented by this `Catalog`  on behalf of
     * the specified user. This method allows a custom (e.g. code-gen) `Client` implementation to
     * be substituted for the default, which allows custom schemas and other custom functionality to
     * be provided in a type-safe manner.
     *
     * @param dbUser        (optional) the user that the `Client` will represent
     * @param readOnly      (optional) pass True to indicate that client is not permitted to modify
     *                      any data
     * @param system        (optional) pass True to indicate that the client is an internal (or
     *                      "system") client, that does client work on behalf of the system itself
     * @param autoShutdown  (optional) pass True to indicate that the database should be closed
     *                      when the connection is closed
     *
     * @return a new `Client` instance
     */
    @Concurrent
    Client<Schema> createClient(DBUser? dbUser=Null, Boolean readOnly=False, Boolean system=False,
                                Boolean autoShutdown=False) {
        dbUser ?:= DefaultUser;

        Int clientId = system ? genInternalClientId() : genClientId();
        val metadata = this.metadata;

        function void(Client) notifyOnClose = unregisterClient(_, autoShutdown);

        Client<Schema> client = metadata == Null
                ? new Client<Schema>(this, clientId, dbUser, readOnly, notifyOnClose)
                : metadata.createClient(this, clientId, dbUser, readOnly, notifyOnClose);

        registerClient(client);
        return client;
    }

    /**
     * Generate a unique client id. (Unique for the lifetime of this Catalog.)
     *
     * @return a new client id
     */
    protected Int genClientId() {
        return ++clientCounter;
    }

    /**
     * Generate a unique client id for an internal (system) client. These clients are pooled, so the
     * same internal id may appear more than once, although only one client object will use that id.
     *
     * @return a new client id
     */
    protected Int genInternalClientId() {
        return -(++systemCounter);
    }

    /**
     * @param id  a client id
     *
     * @return True iff the id specifies an "internal" (or "system") client id
     */
    static Boolean isInternalClientId(Int id) {
        return id < 0;
    }

    /**
     * Register a Client instance.
     *
     * @param client  the Client object to register
     */
    @Concurrent
    protected void registerClient(Client client) {
        assert clients.putIfAbsent(client.id, client);
    }

    /**
     * Unregister a Client instance.
     *
     * @param client    the Client object to unregister
     * @param shutdown  pass True to indicate that the database should be closed
     */
    @Concurrent
    protected void unregisterClient(Client client, Boolean shutdown) {
        assert client.catalog == this;
        clients.remove(client.id, client);

        if (shutdown) {
            close();
        }
    }
}