/**
 * A database transaction, as viewed from within the database.
 */
interface DBTransaction<Schema extends RootSchema>
        extends immutable Const {
    /**
     * The root database schema. The difference between `DBObject`s obtained from this `Schema` and
     * `DBObject`s obtained from the [connection] property is that the DBObjects obtained from this
     * `Schema` are implicitly (and potentially explicitly) tied to this transaction, and should not
     * be used outside of the context of this transaction.
     */
    @RO Schema schema;

    enum Status {Active, Committing, Committed, RolledBack}

    /**
     * The transaction status.
     */
    @RO Status status;

    /**
     * When the transaction began.
     */
    @RO Time created;

    /**
     * When the transaction closed with a commit or roll-back.
     */
    @RO Time? retired;

    /**
     * The time consumed by the transaction, from creation to the beginning of the commit.
     */
    @RO Duration transactionTime;

    /**
     * The timeout specified for the transaction, if it has not been retired. (The value of this
     * property is undefined for retired transactions.)
     */
    @RO Duration? timeout;

    /**
     * The time consumed by the commit processing for the transaction.
     */
    @RO Duration commitTime;

    /**
     * Allows the transaction to be marked as not-commit-able. This property can be set to `True`,
     * but cannot be set to `False` once it has been set to `True`.
     */
    Boolean rollbackOnly;

    /**
     * The identifier specified or generated when the transaction was created.
     */
    @RO UInt id;

    /**
     * An optional descriptive name provided when the transaction was created.
     */
    @RO String? name;

    /**
     * Transaction priority, potentially used to determine resource allocations for active
     * transactions, and to order commits among a backlog of transactions.
     *
     * * `Idle` - Bottom-most priority, only guaranteed to execute if nothing else is executing.
     *
     * * `Low` - Lower than normal priority.
     *
     * * `Normal` - The default priority.
     *
     * * `High` - Higher than normal priority.
     *
     * * `System` - Highest priority; the `System` priority cannot be assigned to a transaction, but
     *   is instead automatically associated with transactions initiated by the database system
     *   itself
     */
    enum Priority {Idle, Low, Normal, High, System}

    /**
     * The priority of the transaction.
     */
    @RO Priority priority;

    /**
     * The number of times that the execution of the work represented by this transaction was
     * attempted previously without success, as indicated by the creator of this transaction.
     */
    @RO Int retryCount;

    /**
     * True indicates that the transaction is not permitted to modify the database. This is useful
     * information for a database when a process is executing long running queries, such as for
     * reports, and may need to hold database resources far longer than the database would normally
     * permit. It further allows a database to optimize its resource management specifically for
     * the read-only usage.
     */
    @RO Boolean readOnly;

    /**
     * If this transaction was created as a side-effect of another transaction, then this property
     * provides that transaction.
     */
    @RO DBTransaction? origin;

    /**
     * The user that initiated this transaction, or `Null` if the transaction was initiated by the
     * database.
     */
    @RO DBUser? dbUser;

    /**
     * The contents of the transaction, which define the total net change represented by the
     * transaction. The key of the map is the path of the database object, and the corresponding
     * value is the
     */
    @RO Map<String, DBObject.TxChange> contents;
}
