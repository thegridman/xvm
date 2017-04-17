package org.xvm.compiler.ast;


import org.xvm.asm.ErrorList;
import org.xvm.asm.StructureContainer;

import org.xvm.compiler.Token;

import org.xvm.util.ListMap;

import java.util.List;
import java.util.Map;

import static org.xvm.util.Handy.appendString;
import static org.xvm.util.Handy.indentLines;


/**
 * A property declaration.
 *
 * @author cp 2017.04.04
 */
public class PropertyDeclarationStatement
        extends StructureContainerStatement
    {
    // ----- constructors --------------------------------------------------------------------------

    public PropertyDeclarationStatement(List<Token>      modifiers,
                                        List<Annotation> annotations,
                                        TypeExpression   type,
                                        Token            name,
                                        Expression       value,
                                        StatementBlock body,
                                        Token            doc)
        {
        this.modifiers   = modifiers;
        this.annotations = annotations;
        this.type        = type;
        this.name        = name;
        this.value       = value;
        this.body        = body;
        this.doc         = doc;
        }


    // ----- accessors -----------------------------------------------------------------------------


    // ----- compile phases ------------------------------------------------------------------------

    @Override
    protected AstNode registerNames(AstNode parent, ErrorList errs)
        {
        setParent(parent);

        // create the structure for this property
        if (getStructure() == null)
            {
            // create a structure for this type
            StructureContainer container = parent.getStructure();
            // TODO is it a constant or a property? does it matter at this point?
            if (container instanceof StructureContainer.ClassContainer)
                {
                setStructure(((StructureContainer.ClassContainer) container).ensureProperty((String) name.getValue()));
                }
            else
                {
                // TODO log error
                throw new UnsupportedOperationException("not a property container: " + container);
                }
            }

        // recurse to children
        // TODO what if one of them changes?
        if (annotations != null)
            {
            for (Annotation annotation : annotations)
                {
                annotation.registerNames(this, errs);
                }
            }
        type.registerNames(this, errs);
        value.registerNames(this, errs);
        if (body != null)
            {
            body.registerNames(this, errs);
            }

        return this;
        }


    // ----- debugging assistance ------------------------------------------------------------------

    public String toSignatureString()
        {
        StringBuilder sb = new StringBuilder();

        if (modifiers != null)
            {
            for (Token token : modifiers)
                {
                sb.append(token.getId().TEXT)
                  .append(' ');
                }
            }

        if (annotations != null)
            {
            for (Annotation annotation : annotations)
                {
                sb.append(annotation)
                  .append(' ');
                }
            }

        sb.append(type)
          .append(' ')
          .append(name.getValue());

        return sb.toString();
        }

    @Override
    public String toString()
        {
        StringBuilder sb = new StringBuilder();

        if (doc != null)
            {
            String sDoc = String.valueOf(doc.getValue());
            if (sDoc.length() > 100)
                {
                sDoc = sDoc.substring(0, 97) + "...";
                }
            appendString(sb.append("/*"), sDoc).append("*/\n");
            }

        sb.append(toSignatureString());

        if (value != null)
            {
            sb.append(" = ")
              .append(value)
              .append(";");
            }
        else if (body != null)
            {
            String sBody = body.toString();
            if (sBody.indexOf('\n') >= 0)
                {
                sb.append('\n')
                  .append(indentLines(sBody, "    "));
                }
            else
                {
                sb.append(' ')
                  .append(sBody);
                }
            }
        else
            {
            sb.append(';');
            }

        return sb.toString();
        }

    @Override
    public String getDumpDesc()
        {
        return toSignatureString();
        }

    @Override
    public Map<String, Object> getDumpChildren()
        {
        ListMap<String, Object> map = new ListMap();
        map.put("annotations", annotations);
        map.put("type", type);
        map.put("value", value);
        map.put("body", body);
        return map;
        }


    // ----- fields --------------------------------------------------------------------------------

    protected List<Token>        modifiers;
    protected List<Annotation>   annotations;
    protected TypeExpression     type;
    protected Token              name;
    protected Expression         value;
    protected StatementBlock     body;
    protected Token              doc;
    }
