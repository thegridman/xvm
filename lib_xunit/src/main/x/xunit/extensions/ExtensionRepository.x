import ecstasy.iterators.CompoundIterator;

class ExtensionRepository(ExtensionRepository? parent = Null)
    {
    Int size.get()
        {
        ExtensionRepository? parent = this.parent;
        if (parent.is(ExtensionRepository))
            {
            return extensions.size + parent.size;
            }
        return extensions.size;
        }

    private List<ExtensionHolder> extensions = new Array();

    private Set<Type<Extension>> extensionTypes = new HashSet();

    <ExtensionType extends Extension> ExtensionType[] get(Type<ExtensionType> type)
        {
        return getByType(type)
            .sorted()
            .map(holder -> holder.extension.as(ExtensionType))
            .toArray();
        }

    <ExtensionType extends Extension> ExtensionType[] reversed(Type<ExtensionType> type)
        {
        return getByType(type)
            .sorted((holder1, holder2) -> holder2 <=> holder1)
            .map(holder -> holder.extension.as(ExtensionType))
            .toArray();
        }

    <ExtensionType extends Extension> void add(Type<ExtensionType> type)
        {
        if (!isRegistered(type))
            {
            extensionTypes.add(type);
            assert function ExtensionType() constructor := type.defaultConstructor();
            add(constructor(), type);
            }
        }

    <ExtensionType extends Extension> void add(ExtensionType extension, Object? source= Null)
        {
        ExtensionHolder holder = new ExtensionHolder(extension, source);
        extensions.add(holder);
        }

    private <ExtensionType extends Extension> Boolean isRegistered(Type<ExtensionType> type)
        {
        if (extensionTypes.contains(type))
            {
            return True;
            }
        ExtensionRepository? parent = this.parent;
        if (parent.is(ExtensionRepository))
            {
            return parent.isRegistered(type);
            }
        return False;
        }

    private <ExtensionType extends Extension> Iterator<ExtensionHolder> getByType(Type<ExtensionType> type)
        {
        ExtensionRepository? parent = this.parent;
        Iterator<ExtensionHolder> it;
        if (parent.is(ExtensionRepository))
            {
            it = new CompoundIterator(parent.extensions.iterator(), this.extensions.iterator());
            }
        else
            {
            it = this.extensions.iterator();
            }

        return it.filter(holder -> holder.isType(type));
        }

    static class ExtensionHolder<ExtensionType extends Extension>(ExtensionType extension, Object? source)
            implements Orderable
        {
        @Lazy Int priority.calc()
            {
            Object? source = this.source;
            if (source.is(Test))
                {
                if (source.priority != 0)
                    {
                    return source.priority;
                    }
                }
            return this.extension.priority;
            }

        Boolean isType(Type type)
            {
            return type.isInstance(extension);
            }

        static <CompileType extends ExtensionHolder> Ordered compare(CompileType value1, CompileType value2)
            {
            // Highest priority comes first (i.e. reverse natural Int order)
            return value2.priority <=> value1.priority;
            }
        }
    }