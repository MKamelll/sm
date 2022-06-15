module vm.lexer;

enum TokenType
{
    PUSHI, PUSHF, PUSHL,

    ADDI, ADDF, ADDL,
    SUBI, SUBF, SUBL,
    DEVI, DEVF, DEVL,
    MULI, MULF, MULL,

    INT, FLOAT, LONG,
    
    IDENTIFIER, COLON, ENDLINE, SPACE,
    
    HALT, EOF
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

    void advance() {
        mCurrChar = mSrc[mCurrIndex++];
    }

    bool isAtEnd() {
        if (mCurrIndex < mSrc.length) {
            return false;
        }

        return true;
    }

/*    Token next() {

    }*/
}