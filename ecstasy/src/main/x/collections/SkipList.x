import maps.EntryKeys;
import maps.EntryValues;
import maps.ReifiedEntry;

/**
 * SkipList is an implementation of a sorted Map based on a SkipList data structure.
 */
class SkipList<Key, Value>
        implements Map<Key, Value>
    {
    // ----- constructors --------------------------------------------------------------------------

    construct(Orderer? order = Null, Int maxLevel = DEFAULT_MAX_LEVEL, Int span = DEFAULT_SPAN)
        {
        assert:arg span >= 1;
        assert:arg maxLevel >= 1 && maxLevel <= 64;

        this.maxLevel      = maxLevel;
        this.probabilities = calculateProbabilities(span, this.maxLevel);
        this.orderer       = order;
        this.top           = new IndexNode(0);
        }

    // ----- internal state ------------------------------------------------------------------------

    /**
     * The maximum number of levels in this skip list.
     */
    private Int maxLevel;

    /**
     * The current top node of the list.
     */
    private IndexNode top;

    /**
     * An optional Orderer used to determine the sort order of keys.
     */
    private Orderer? orderer;

    /**
     * The array of level probabilities used to assign random Float values to a level in the list.
     */
    private Float[] probabilities;

    /**
     * A random number generator to use to generate levels for new entries.
     */
    @Inject
    Random random;

    /**
     * The size of this SkipList.
     */
    @Override
    public/private Int size;

    // ----- Map interface -------------------------------------------------------------------------

    @Override
    SkipList clear()
        {
        top = new IndexNode(0);
        return this;
        }

    @Override
    Boolean contains(Key key)
        {
        if (find(key))
            {
            return True;
            }
        return False;
        }

    @Override
    conditional Value get(Key key)
        {
        if (EntryNode node := find(key))
            {
            return True, node.value;
            }
        return False;
        }

    @Override
    SkipList put(Key key, Value value)
        {
        Queue<BaseNode> previous = findPrevious(key);
        BaseNode        prev     = previous.take();

        // there will always be at least one previous (i.e. at least the top node)
        if (prev.is(EntryNode) && prev.key == key)
            {
            // put to an existing entry so just update the value
            prev.value = value;
            }
        else
            {
            // put to a new entry after the current previous entry
            Int      level = calculateRandomLevel();
            BaseNode node  = new EntryNode(key, value, prev.next);
            prev.next = node;

            if (level > 0)
                {
                for (Int i : 1..level)
                    {
                    if (BaseNode n := previous.next())
                        {
                        prev = n;
                        }
                    else
                        {
                        // we're adding a new level
                        prev = new IndexNode(i, top);
                        top = prev;
                        }
                    node = new KeyNode(key, node, prev.next);
                    prev.next = node;
                    }
                }
            }

        return this;
        }

    @Override
    SkipList putAll(Map<Key, Value> that)
        {
        for (Map<Key, Value>.Entry entry : that.entries)
            {
            put(entry.key, entry.value);
            }
        return this;
        }

    @Override
    SkipList remove(Key key)
        {
        Queue<BaseNode> previous = findPrevious(key, False);
        Boolean         found    = False;

        while (BaseNode prev := previous.next())
            {
            BaseNode? next = prev.next;
            if (next.is(KeyNode) && next.as(KeyNode).key == key)
                {
                prev.next = next.next;
                found = True;
                }
            }

        if (found)
            {
            this.size--;
            }

        return this;
        }

    @Override
    @Lazy public/private Set<Key> keys.calc()
        {
        return new EntryKeys<Key, Value>(this);
        }

    @Override
    @Lazy public/private Collection<Value> values.calc()
        {
        return new EntryValues<Key, Value>(this);
        }

    @Override
    @Lazy public/private EntrySet entries.calc()
        {
        return new EntrySet();
        }

    // ----- helpers -------------------------------------------------------------------------------

    /**
     * Calculate the probabilities used to determine what level an entry should be indexed to.
     * 
     * Probability values are in the range [0, 1).  A randomly chosen value _v_
     * in that range corresponds to a level _l_ iff the following condition
     * holds:
     * _threshold[l-1]_ <= _v_ < _threshold[l-1]_
     *
     * @param span      the span of this skip list
     * @param maxLevel  the maximum number of levels to compute thresholds for
     *
     * @return an array containing the distribution probabilities
     */
    protected static Float[] calculateProbabilities(Int span, Int maxLevel)
        {
        Float   floatSpan     = span.toFloat64();
        Float[] probabilities = new Array<Float>(maxLevel + 1);
        Float   probability   = 1.0;
        Float   cumulative;

        // The probability of selecting a particular level is given by:
        //   p(l) = (1/span)^(l + 1)
        //   p(0) = 1 - (sum of p(l) over l=1..MAX_LEVEL)
        //
        // For these geometric series, p(0) can be expressed as:
        //   p(0) = 1/span + (span-2)/(span-1)
        //
        if (span == 2)
            {
            // A special case when span==2
            //
            // testing shows that 1/2 is just too many indices to create.
            // Instead, span=2 will generate a distribution like:
            //   p(0) - 3/4   (no index)
            //   p(1) - 1/8
            //   p(2) - 1/16
            //
            cumulative  = 0.5;
            probability = 0.5;
            }
        else
            {
            cumulative = (floatSpan - 2.0) / (floatSpan - 1.0);
            }

        for (UInt8 i : 0..maxLevel)
            {
            probability      /= floatSpan;
            cumulative       += probability;
            probabilities[i] = cumulative;
            }
        return probabilities;
        }

    /**
     * Randomly generate a level value 0 <= L <= maxLevel, in
     * such a way that the probability p(l) of generating level l
     * is equal to p(l)=(1/span)^(l+1) and
     * p(0)=1-(sum of p(l) over l=1..MAX_LEVEL).
     * 
     * For example, the probabilities (with span=2, and weight of 2) of returning
     * the following levels are:
     * 0 (no-index) - 3/4
     * 1            - 1/8
     * 2            - 1/16
     * 3            - 1/32
     * ...
     *
     * @return a random level number between 0 and maxLevel
     */
    Int calculateRandomLevel()
        {
        Int   level = 0;
        Float rnd   = random.float();

        while (level < this.maxLevel)
            {
            if (rnd < probabilities[level])
                {
                break;
                }
            ++level;
            }

        return level;
        }

    Queue<BaseNode> findPrevious(Key key, Boolean allowEqual = True)
        {
        ArrayDeque<BaseNode> previous = new ArrayDeque<BaseNode>(maxLevel, maxLevel);
        BaseNode             node     = top;

        while(true)
            {
            BaseNode? next  = node.next;
            BaseNode? below = node.below;
            if (next.is(KeyNode))
                {
                Orderer? orderer = this.orderer;
                Ordered  order;

                if (orderer == Null)
                    {
                    assert Key.is(Type<Orderable>);
                    order = next.key <=> key;
                    }
                else
                    {
                    order = orderer(key, next.key);
                    }

                if (order == Lesser || (allowEqual && order == Equal))
                    {
                    // next node is less than or equal to key, go right
                    node = next;
                    }
                else
                    {
                    // next node is higher, go down
                    previous.add(node);
                    if (below == Null)
                        {
                        break;
                        }
                    node = below;
                    }
                }
            else if (below == Null)
                {
                // no next node and cannot go lower so we're done
                previous.add(node);
                break;
                }
            else
                {
                // no next node, go down
                previous.add(node);
                node = below;
                }
            }

        return previous.lifoQueue;
        }

    /**
     * Find the EntryNode in the SkipList mapped to the specified key.
     *
     * @param key  the key to look up in the SkipList
     *
     * @return a True iff the EntryNode associated with the specified key exists in the map
     * @return the EntryNode associated with the specified key (conditional)
     */
    conditional EntryNode find(Key key)
        {
        BaseNode node = top;

        while(true)
            {
            BaseNode? next  = node.next;
            BaseNode? below = node.below;
            if (next.is(KeyNode))
                {
                Orderer? orderer = this.orderer;
                Ordered  order;

                if (orderer == Null)
                    {
                    assert Key.is(Type<Orderable>);
                    order = next.key <=> key;
                    }
                else
                    {
                    order = orderer(key, next.key);
                    }

                if (order == Lesser)
                    {
                    // next node is less than key, go right
                    node = next;
                    }
                else if (order == Equal)
                    {
                    // next node is equal to key so we've found either the entry we want or the
                    // top of the KeyNodes for the entry we want so just go down to the bottom
                    if (next.is(EntryNode))
                        {
                        // Next node is an EntryNode so we've found what we're looking for
                        return True, next;
                        }

                    next = next.below;
                    while (next.is(KeyNode))
                        {
                        if (next.is(EntryNode))
                            {
                            // Found the EntryNode we're looking for
                            return True, next;
                            }
                        // not at the EntryNode, keep going down
                        next = next.below;
                        }
                    // There was no EntryNode at the bottom of the pile of KeyNodes
                    // The key is not in the list but we shouldn't actually ever get here
                    return False;
                    }
                else
                    {
                    // next node is higher, go down
                    if (below == Null)
                        {
                        // There is now down, so we're done - the key is not found.
                        break;
                        }
                    node = below;
                    }
                }
            else if (below == Null)
                {
                // no next node and cannot go lower so we're done
                break;
                }
            else
                {
                // no next node, go down
                node = below;
                }
            }

        // The key was not found
        return False;
        }

    /**
     * Get the first EntryNode in this SkipList.
     *
     * @return the first EntryNode in this SkipList or Null if the SkipList is empty
     */
    EntryNode? firstEntry()
        {
        IndexNode node = top;
        while(node.level > 0)
            {
            node = node.below;
            }
        BaseNode? next = node.next;
        return next.is(EntryNode) ? next : Null;
        }

    String print()
        {
        StringBuffer buf = new StringBuffer();
        BaseNode? node = top;
        while (node != Null)
            {
            buf.append(node.toString());
            buf.append('\n');
            node = node.below;
            }
        return buf.toString();
        }

    // ----- Orderer -------------------------------------------------------------------------------

    /**
     * An Orderer is a function that compares two Keys for order to use to maintain ordering
     * of entries in the SkipList.
     */
    typedef function Ordered (Key, Key) Orderer;

    // ----- BaseNode ------------------------------------------------------------------------------

    /**
     * BaseNode is the base class for nodes in the list.
     */
    static class BaseNode(BaseNode? below, BaseNode? next);

    // ----- IndexNode -----------------------------------------------------------------------------

    /**
     * IndexNode are the starting nodes of each level.
     */
    static class IndexNode
            extends BaseNode
        {
        construct(Int level, BaseNode? below = Null, BaseNode? next = Null)
            {
            construct BaseNode(below, next);
            this.level = level;
            }

        Int level;

        @Override
        String toString()
            {
            val buf = new StringBuffer(10);
            buf.append("I(");
            buf.append(level.toString());
            buf.append(") ");
            if (next.is(BaseNode))
                {
                buf.append(next.toString());
                }
            return buf.toString();
            }
        }

    // ----- KeyNode -------------------------------------------------------------------------------

    /**
     * KeyNode is a node in the list that holds key and allows skipping at
     * the higher levels of the list.
     */
    static class KeyNode
            extends BaseNode
        {
        construct(Key key, BaseNode? below, BaseNode? next = Null)
            {
            construct BaseNode(below, next);
            this.key = key;
            }

        public Key key;

        @Override
        String toString()
            {
            val buf = new StringBuffer(10);
            buf.append("K(");
            buf.append(key.toString());
            if (below.is(KeyNode))
                {
                buf.append(",");
                buf.append(below.as(KeyNode).key.toString());
                }
            buf.append(") ");
            if (next.is(BaseNode))
                {
                buf.append(next.toString());
                }
            return buf.toString();
            }
        }

    // ----- EntryNode -----------------------------------------------------------------------------

    /**
     * EntryNode is a node in the list that holds key/value entries.
     */
    static class EntryNode
            extends KeyNode
        {
        construct (Key key, Value value, BaseNode? next = Null)
            {
            construct KeyNode(key, Null, next);
            this.value = value;
            }

        public Value value;

        @Override
        String toString()
            {
            val buf = new StringBuffer(10);
            buf.append("E(");
            buf.append(key.toString());
            buf.append("=");
            buf.append(value.toString());
            buf.append(") ");
            if (next.is(BaseNode))
                {
                buf.append(next.toString());
                }
            return buf.toString();
            }
        }

    // ----- CursorEntry implementation ------------------------------------------------------------

    /**
     * An implementation of Entry that can be used as a cursor over any number of keys, and
     * delegates back to the map for its functionality.
     */
    class CursorEntry
            implements Entry
        {
        @Unassigned
        private EntryNode node;

        protected CursorEntry advance(EntryNode node)
            {
            this.node   = node;
            this.exists = true;
            return this;
            }

        @Override
        Key key.get()
            {
            return node.key;
            }

        @Override
        public/protected Boolean exists;

        @Override
        Value value
            {
            @Override
            Value get()
                {
                if (exists)
                    {
                    return node.value;
                    }
                else
                    {
                    throw new OutOfBounds("entry does not exist for key=" + key);
                    }
                }

            @Override
            void set(Value value)
                {
                verifyNotPersistent();
                if (exists)
                    {
                    node.value = value;
                    }
                else
                    {
                    this.SkipList.put(key, value);
                    assert node := this.SkipList.find(key);
                    exists = true;
                    }
                }
            }

        @Override
        void remove()
            {
            if (verifyNotPersistent() & exists)
                {
                assert this.SkipList.keys.removeIfPresent(key);
                exists = false;
                }
            }

        @Override
        Map<Key, Value>.Entry reify()
            {
            return new ReifiedEntry<Key, Value>(this.SkipList, key);
            }
        }

    // ----- EntrySet implementation ---------------------------------------------------------------

    /**
     * A representation of all of the HashEntry objects in the Map.
     */
    class EntrySet
            implements Set<Entry>
        {
//        @Override
//        Mutability mutability.get()
//            {
//            return Mutable;
//            }

        @Override
        Iterator<Entry> iterator()
            {
            return new Iterator()
                {
                EntryNode?  current = null;
                EntryNode?  next    = this.SkipList.firstEntry();
                CursorEntry entry   = new CursorEntry();

                @Override
                conditional Entry next()
                    {
                    if (next != null)
                        {
                        next = current.next;
                        return True, entry.advance(node);
                        }

                    return False;
                    }
                };
            }

        @Override
        EntrySet remove(Entry entry)
            {
            verifyMutable();
            this.SkipList.remove(entry.key, entry.value);
            return this;
            }

        @Override
        (EntrySet, Int) removeIf(function Boolean (Entry) shouldRemove)
            {
//            Int          removed     = 0;
//            HashEntry?[] buckets     = this.HashMap.buckets;
//            Int          bucketCount = buckets.size;
//            CursorEntry  entry       = new CursorEntry();
//            for (Int i = 0; i < bucketCount; ++i)
//                {
//                HashEntry? currEntry = buckets[i];
//                HashEntry? prevEntry = null;
//                while (currEntry != null)
//                    {
//                    if (shouldRemove(entry.advance(currEntry)))
//                        {
//                        // move to the next entry (the current one is getting unlinked)
//                        currEntry = currEntry.next;
//
//                        // unlink the entry that is being removed
//                        if (prevEntry != null)
//                            {
//                            prevEntry.next = currEntry;
//                            }
//                        else
//                            {
//                            buckets[i] = currEntry;
//                            }
//                        ++removed;
//                        ++this.HashMap.removeCount;
//                        }
//                    else
//                        {
//                        prevEntry = currEntry;
//                        currEntry = currEntry.next;
//                        }
//                    }
//                }

            return this, removed;
            }
        }

    // ----- constants -----------------------------------------------------------------------------

    /**
     * The default span value.
     */
    static Int DEFAULT_SPAN = 3;

    /**
     * The default limit on the index-level.
     */
    static Int DEFAULT_MAX_LEVEL = 16;
    }
    