module vm.lexer;

import std.variant;
import std.ascii;
import std.typecons;
import std.conv;
import std.stdio;

import vm.error;

enum TokenType : string
{
    PUSHI = "pushi", PUSHF = "pushf", PUSHL = "pushl",
    ADDI = "addi", ADDF = "addf", ADDL = "addl",
    SUBI = "subi", SUBF = "subf", SUBL = "subl",
    DEVI = "devi", DEVF = "devf", DEVL = "devl",
    MULI = "muli", MULF = "mulf", MULL = "mull",
    CMPI = "cmpi", CMPF = "cmpf", CMPL = "cmpl",
    DECI = "deci", DECF = "decf", DECL = "decl",
    
    PUSHB = "pushb",
    
    JMP = "jmp", JE = "je", JG = "jg", JL = "jl", JGE = "jge", JLE = "jle",
    LOADG = "loadg", STOREG = "storeg", CALL = "call", RETURN = "ret",

    INT = "int", FLOAT = "float", LONG = "long", BOOL = "bool", STRING = "string",
    
    IDENTIFIER = "identifier", COLON = ":", SEMICOLON = ";", LEFT_BRACKET = "{", RIGHT_BRACKET = "}",
    
    HALT = "halt", EOF = "EOF"
}

class Token
{
    TokenType mType;
    Variant mLexeme;
    this (TokenType type, Variant lexeme) {
        mType = type;
        mLexeme = lexeme;
    }

    this (TokenType type, string lexeme) {
        mType = type;
        mLexeme = Variant(lexeme);
    }
   
    this (TokenType type, char lexeme) {
        mType = type;
        mLexeme = Variant(lexeme);
    }

    this (TokenType type, int lexeme) {
        mType = type;
        mLexeme = Variant(lexeme);
    }

    this (TokenType type, float lexeme) {
        mType = type;
        mLexeme = Variant(lexeme);
    }

    this (TokenType type, long lexeme) {
        mType = type;
        mLexeme = Variant(lexeme);
    }

    this (TokenType type, bool lexeme) {
        mType = type;
        mLexeme = Variant(lexeme);
    }

    TokenType getType() {
        return mType;
    }

    T getLexeme(T)(bool allowConversion = false) {
        if (mLexeme.peek!T) return mLexeme.get!T;

        if (allowConversion) {
            if (mLexeme.convertsTo!T) return mLexeme.get!T;
        }

        throw new VmError("Tried getting a lexeme of type '" ~ to!string(typeid(T))
            ~ "'" ~ " but available type is " ~ mLexeme.type.toString());
    }

    
    Variant getLexeme() {
        return mLexeme;
    }

    override string toString() {
        if (mLexeme.peek!string || mLexeme.peek!char) {
            return "Token(type: " ~ to!string(mType) ~ ", lexeme: '" ~ mLexeme.toString() ~ "')";
        }
        return "Token(type: " ~ to!string(mType) ~ ", lexeme: " ~ mLexeme.toString() ~ ")";
    }
}

class Lexer
{
    private string mSrc;
    private int mCurrIndex;
    private char mCurrChar;
    
    this (string source) {
        mSrc = source;
        mCurrIndex = 0;
        mCurrChar = mSrc[mCurrIndex];
    }

    private void advance() {
        mCurrIndex++;
        if (!isAtEnd()) {
            mCurrChar = mSrc[mCurrIndex];
        }
    }

    private bool isAtEnd() {
        if (mCurrIndex < mSrc.length) {
            return false;
        }

        return true;
    }

    Token next() {
        if (isAtEnd()) return new Token(TokenType.EOF, "EOF");

        switch (mCurrChar) {
            case ':': {
                advance();
                return new Token(TokenType.COLON, ':');
            }

            case '{': {
                advance();
                return new Token(TokenType.LEFT_BRACKET, '{');
            }

            case '}': {
                advance();
                return new Token(TokenType.RIGHT_BRACKET, '}');
            }

            case ';': {
                advance();
                return new Token(TokenType.SEMICOLON, ';');
            }

            case '"': {
                string str  = aString();
                return new Token(TokenType.STRING, str);
            }

            case ' ': case '\t': advance(); return next();

            default: {
               if (isAlpha(mCurrChar)) {
                    string ident = anIdentifier();
                    switch (ident) {
                        case "pushi": return new Token(TokenType.PUSHI, ident);
                        case "pushf": return new Token(TokenType.PUSHF, ident);
                        case "pushl": return new Token(TokenType.PUSHL, ident);
                        case "pushb": return new Token(TokenType.PUSHB, ident);
                        
                        case "addi": return new Token(TokenType.ADDI, ident);
                        case "addf": return new Token(TokenType.ADDF, ident);
                        case "addl": return new Token(TokenType.ADDL, ident);
                        
                        case "subi": return new Token(TokenType.SUBI, ident);
                        case "subf": return new Token(TokenType.SUBF, ident);
                        case "subl": return new Token(TokenType.SUBL, ident);

                        case "muli": return new Token(TokenType.MULI, ident);
                        case "mulf": return new Token(TokenType.MULF, ident);
                        case "mull": return new Token(TokenType.MULL, ident);

                        case "devi": return new Token(TokenType.DEVI, ident);
                        case "devf": return new Token(TokenType.DEVF, ident);
                        case "devl": return new Token(TokenType.DEVL, ident);

                        case "cmpi": return new Token(TokenType.CMPI, ident);
                        case "cmpf": return new Token(TokenType.CMPF, ident);
                        case "cmpl": return new Token(TokenType.CMPL, ident);

                        case "jmp": return new Token(TokenType.JMP, ident);
                        case "je":  return new Token(TokenType.JE, ident);
                        case "jg":  return new Token(TokenType.JG, ident);
                        case "jl":  return new Token(TokenType.JL, ident);
                        case "jge": return new Token(TokenType.JGE, ident);
                        case "jle": return new Token(TokenType.JLE, ident);

                        case "deci": return new Token(TokenType.DECI, ident);
                        case "decf": return new Token(TokenType.DECF, ident);
                        case "decl": return new Token(TokenType.DECL, ident);
                        case "true": return new Token(TokenType.BOOL, true);
                        case "false": return new Token(TokenType.BOOL, false);

                        case "loadg": return new Token(TokenType.LOADG, ident);
                        case "storeg": return new Token(TokenType.STOREG, ident);
                        
                        case "call": return new Token(TokenType.CALL, ident);
                        case "ret": return new Token(TokenType.RETURN, ident);
                        
                        case "halt": return new Token(TokenType.HALT, ident);
                        
                        default: {
                            return new Token(TokenType.IDENTIFIER, ident);
                        }
                    }
                } else if (isDigit(mCurrChar)) {
                    auto numInfo = aNumber();
                    string num = numInfo[0];
                    bool isFloat = numInfo[1];

                    if (isFloat) {
                        return new Token(TokenType.FLOAT, to!float(num));
                    } else if (num.length > 10) {
                        try {
                            return new Token(TokenType.LONG, to!long(num));
                        } catch (ConvOverflowException err) {
                            throw new VmError("Provided operand is larger than long");
                        }
                    } else {
                        return new Token(TokenType.INT, to!int(num));
                    }
                }
            }

        }

        throw new VmError("Unknown token: '" ~ mCurrChar ~ "'");
    }

    private string anIdentifier() {
        string result;
        while (!isAtEnd()) {
            if (!isAlphaNum(mCurrChar)) break;
            result ~= mCurrChar;
            advance();
        }

        return result;
    }

    private Tuple!(string, bool) aNumber() {
        string result;
        bool isFloat = false;
        while (!isAtEnd()) {
            if (mCurrChar == '.') {
                isFloat = true;
                result ~= '.';
                advance();
                continue;
            }
            if (!isDigit(mCurrChar)) break;

            result ~= mCurrChar;
            advance();               
        }
        
        return tuple(result, isFloat);
    }

    private string aString() {
        string result;
        
        // pass "
        advance();
        
        while (!isAtEnd()) {
            if (mCurrChar == '\\') {
                advance();
                result ~= mCurrChar;
                advance();
            }
            if (mCurrChar == '"') break;
            
            result ~= mCurrChar;
            advance();
        }

        // pass "
        advance();

        return result;
    }    
}