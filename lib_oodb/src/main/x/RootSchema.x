/**
 * A `DBSchema` is a `DBObject` that is used to hierarchically organize database contents.
 *
 * Every Database automatically contains a `DBSchema` named "db"; it is the database system's own
 * schema. (The top-level schema "db" is a reserved name; it is an error to attempt to override,
 * replace, or augment the database system's schema.) A database implementation may expose as much
 * information as it desires via its schema, but there will always exist the following contents,
 * regardless of the database implementation:
 */
interface RootSchema
        extends DBSchema
    {
    @RO SystemSchema db;
    }