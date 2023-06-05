import reflect.InvalidType;

import src.Lexer.Token;


/**
 * Represents a union type expressions, such as:
 *
 *     Nullable | String
 */
const UnionTypeExpression(TypeExpression left, Token operator, TypeExpression right)
        extends RelationalTypeExpression(left, operator, right) {

    @Override
    conditional Type resolveType(TypeSystem typeSystem, Boolean hideExceptions = False) {
        if (Type leftType := left.resolveType(typeSystem, hideExceptions)) {
            if (Type rightType := right.resolveType(typeSystem, hideExceptions)) {
                try {
                    return True, leftType | rightType;
                } catch (InvalidType e) {
                    if (!hideExceptions) {
                        throw e;
                    }
                }
            }
        }

        return False;
    }
}

