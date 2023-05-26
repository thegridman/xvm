/**
 * The root `Model` for a test hierarchy.
 */
class XUnitModel
        extends BaseModel
    {
    /**
     * Create a root model.
     *
     * @param id  the model's `UniqueId`
     */
    construct(UniqueId id)
        {
        construct BaseModel(id, Container, "XUnit", Null, []);
        }

	// ----- Freezable -----------------------------------------------------------------------------

    @Override
    immutable XUnitModel! freeze(Boolean inPlace = False)
        {
        if (&this.isImmutable)
            {
            return this.as(immutable XUnitModel);
            }

        if (inPlace)
            {
            children = children.freeze(inPlace);
            return this.makeImmutable();
            }

        XUnitModel model = new XUnitModel(uniqueId);
        model.parentId = parentId;
        model.children = children.freeze(inPlace);
        return model.makeImmutable();
        }
    }