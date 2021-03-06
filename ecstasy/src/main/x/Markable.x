/**
 * Represents the ability to mark and later restore a position.
 *
 * @see Iterator.ensureMarkable()
 * @see MarkedIterator
 */
interface Markable
    {
    /**
     * Obtain a mark that can later be used to restore the current position of this object.
     */
    Object mark();

    /**
     * Restore the location at which a mark was previously obtained. This does not invalidate the
     * mark, so the mark can be re-used again later (until it is unmarked using [unmark()]).
     *
     * @param mark    the result from a previous call to [mark()]
     * @param unmark  pass True to also release the mark as part of this operation
     */
    void restore(Object mark, Boolean unmark = False);

    /**
     * Release a previously obtained mark. Some implementations may be able to reduce their resource
     * utilization when their previously created marks are released.
     *
     * @param mark  the result from a previous call to [mark()]
     */
    void unmark(Object mark)
        {
        }
    }
