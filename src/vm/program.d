module vm.program;

import std.array;
import std.algorithm;
import std.string;
import std.conv;
import std.stdio;
import std.typecons;
import std.variant;

import vm.instruction;
import vm.error;
import vm.lexer;
import vm.common;

class Program
{
    Instruction[] mInstructions;

    this (Instruction[] insts) {
        mInstructions = insts;
    }

    Instruction[] getInstructions() {
        return mInstructions;
    }
    
    override string toString() {
        return "Program(" ~ to!string(mInstructions) ~ ")";
    }
}

class Generator
{
    private Instruction[] mInstructions;
    private int mCurrDataIndex;
    private Lexer mLexer;
    private Token mCurrToken;
    private Token mPrevToken;

    this (Lexer lexer) {
        mLexer = lexer;
        mInstructions = [];
        mCurrDataIndex = 0;
        mCurrToken = lexer.next();
    }

    bool isAtEnd() {
        if (mCurrToken.getType() != TokenType.EOF) {
            return false;
        }

        return true;
    }

    void advance() {
        mPrevToken = mCurrToken;
        mCurrToken = mLexer.next();
    }

    bool match(TokenType[] types...) {
        foreach (type; types) {
            if (mCurrToken.getType() == type) {
                advance();
                return true;
            }
        }

        return false;
    }

    bool check(TokenType type) {
        if (mCurrToken.getType() == type) return true;
        return false;
    }

    VmError expected(TokenType type, string hint = "") {
        if (hint.length > 0) {
            return new VmError("Expected '" ~ type
                ~ "' instead got '" ~ mCurrToken.getType() ~ "'" ~ "\n=> Hint: " ~ hint);    
        }
        return new VmError("After '" ~ previous().getType() ~ "' expected '"
            ~ type ~ "' instead got '" ~ mCurrToken.getType() ~ "'");
    }

    Token previous() {
        return mPrevToken;
    }

    bool checkPrevious(TokenType type) {
        if (previous().getType() == type) return true;
        return false;
    }

    Token curr() {
        return mCurrToken;
    }

    Program generate() {
        mInstructions ~= generatePushInt();
        
        if (!match(TokenType.SEMICOLON) && previous().getType() != TokenType.COLON)
            throw expected(TokenType.SEMICOLON);
        
        if (isAtEnd()) return new Program(mInstructions);
        return generate();
    }

    // Generate Int
    Instruction generatePushInt() {
        if (match(TokenType.PUSHI)) {
            if (!match(TokenType.INT)) throw expected(TokenType.INT);

            int operand = previous().getLexeme!int;
            return new Instruction(Opcode.PUSHI, operand);
        }

        return generateAddInt();
    }

    Instruction generateAddInt() {
        if (match(TokenType.ADDI)) {
            return new Instruction(Opcode.ADDI);
        }

        return generateMultiplyInt();   
    }

    Instruction generateMultiplyInt() {
        if (match(TokenType.MULI)) {
            return new Instruction(Opcode.MULI);
        }

        return generateSubInt();         
    }

    Instruction generateSubInt() {
        if (match(TokenType.SUBI)) {
            return new Instruction(Opcode.SUBI);
        }

        return generateDivInt();
    }

    Instruction generateDivInt() {
        if (match(TokenType.DEVI)) {
            return new Instruction(Opcode.DIVI);
        }
       
       return generatePushLong();
    }

    // Generate Long
    Instruction generatePushLong() {
        if (match(TokenType.PUSHL)) {
            if (!match(TokenType.LONG)) throw expected(TokenType.LONG);
            
            long operand = previous().getLexeme!long;
            return new Instruction(Opcode.PUSHL, operand);
        }

        return generateAddLong();
    }

    Instruction generateAddLong() {
        if (match(TokenType.ADDL)) {
            return new Instruction(Opcode.ADDL);
        }

        return generateMultiplyLong();   
    }

    Instruction generateMultiplyLong() {
        if (match(TokenType.MULL)) {
            return new Instruction(Opcode.MULL);
        }

        return generateSubLong();         
    }

    Instruction generateSubLong() {
        if (match(TokenType.SUBL)) {
            return new Instruction(Opcode.SUBL);
        }

        return generateDivLong();
    }

    Instruction generateDivLong() {
        if (match(TokenType.DEVL)) {
            return new Instruction(Opcode.DIVL);
        }
       
       return generatePushFloat();
    }

    // Generate Float
    Instruction generatePushFloat() {
        if (match(TokenType.PUSHF)) {
            if (!match(TokenType.FLOAT)) throw expected(TokenType.FLOAT);
            
            float operand = previous().getLexeme!float;
            return new Instruction(Opcode.PUSHF, operand);
        }

        return generateAddFloat();
    }

    Instruction generateAddFloat() {
        if (match(TokenType.ADDF)) {
            return new Instruction(Opcode.ADDF);
        }

        return generateMultiplyFloat();   
    }

    Instruction generateMultiplyFloat() {
        if (match(TokenType.MULF)) {
            return new Instruction(Opcode.MULF);
        }

        return generateSubFloat();         
    }

    Instruction generateSubFloat() {
        if (match(TokenType.SUBF)) {
            return new Instruction(Opcode.SUBF);
        }

        return generateDivFloat();
    }

    Instruction generateDivFloat() {
        if (match(TokenType.DEVF)) {
            return new Instruction(Opcode.DIVF);
        }

        return generatePushBool();
    }

    // bool
    Instruction generatePushBool() {
        if (match(TokenType.PUSHB)) {
            if (!match(TokenType.BOOL)) throw expected(TokenType.BOOL);
            
            int operand = previous().getLexeme!bool;
            return new Instruction(Opcode.PUSHB, operand);
        }
        
        return generateJmp();
    }

    // jmp
    Instruction generateJmp() {
        if (match(TokenType.JMP)) {
            if (!match(TokenType.INT)) {
                if (match(TokenType.IDENTIFIER)) {
                    string operand = previous().getLexeme!string;
                    return new Instruction(Opcode.JMP, operand);
                } else {
                    throw expected(TokenType.INT, "You have to provide a destination (int or label name) to jump to");
                }
            }
            
            int operand = previous().getLexeme!int;
            return new Instruction(Opcode.JMP, operand);
        }
        
        return generateJe();
    }

    Instruction generateJe() {
        if (match(TokenType.JE)) {
            if (!match(TokenType.INT)) {
                if (match(TokenType.IDENTIFIER)) {
                    string operand = previous().getLexeme!string;
                    return new Instruction(Opcode.JE, operand);
                } else {
                    throw expected(TokenType.INT, "You have to provide a destination (int or label name) to jump to");
                }
            }
            
            int operand = previous().getLexeme!int;
            return new Instruction(Opcode.JE, operand);
        }
        
        return generateJg();
    }

    
    Instruction generateJg() {
        if (match(TokenType.JG)) {
            if (!match(TokenType.INT)) {
                if (match(TokenType.IDENTIFIER)) {
                    string operand = previous().getLexeme!string;
                    return new Instruction(Opcode.JG, operand);
                } else {
                    throw expected(TokenType.INT, "You have to provide a destination (int or label name) to jump to");
                }
            }
            
            int operand = previous().getLexeme!int;
            return new Instruction(Opcode.JG, operand);
        }
        
        return generateJl();
    }

    
    Instruction generateJl() {
        if (match(TokenType.JL)) {
            if (!match(TokenType.INT)) {
                if (match(TokenType.IDENTIFIER)) {
                    string operand = previous().getLexeme!string;
                    return new Instruction(Opcode.JL, operand);
                } else {
                    throw expected(TokenType.INT, "You have to provide a destination (int or label name) to jump to");
                }
            }
            
            int operand = previous().getLexeme!int;
            return new Instruction(Opcode.JL, operand);
        }
        
        return generateJge();
    }

    
    Instruction generateJge() {
        if (match(TokenType.JGE)) {
            if (!match(TokenType.INT)) {
                if (match(TokenType.IDENTIFIER)) {
                    string operand = previous().getLexeme!string;
                    return new Instruction(Opcode.JGE, operand);
                } else {
                    throw expected(TokenType.INT, "You have to provide a destination (int or label name) to jump to");
                }
            }
            
            int operand = previous().getLexeme!int;
            return new Instruction(Opcode.JGE, operand);
        }
        
        return generateJle();
    }

    
    Instruction generateJle() {
        if (match(TokenType.JLE)) {
            if (!match(TokenType.INT)) {
                if (match(TokenType.IDENTIFIER)) {
                    string operand = previous().getLexeme!string;
                    return new Instruction(Opcode.JLE, operand);
                } else {
                    throw expected(TokenType.INT, "You have to provide a destination (int or label name) to jump to");
                }
            }
            
            int operand = previous().getLexeme!int;
            return new Instruction(Opcode.JLE, operand);
        }
        
        return generateCmpInt();
    }

    // cmp
    Instruction generateCmpInt() {
        if (match(TokenType.CMPI)) {
            return new Instruction(Opcode.CMPI);
        }

        return generateCmpFloat();
    }

    Instruction generateCmpFloat() {
        if (match(TokenType.CMPF)) {
            return new Instruction(Opcode.CMPF);
        }

        return generateCmpLong();
    }

    Instruction generateCmpLong() {
        if (match(TokenType.CMPL)) {
            return new Instruction(Opcode.CMPL);
        }

        return generateDecInt();
    }

    // dec
    Instruction generateDecInt() {
        if (match(TokenType.DECI)) {
            return new Instruction(Opcode.DECI);
        }

        return generateDecFloat();
    }

    Instruction generateDecFloat() {
        if (match(TokenType.DECF)) {
            return new Instruction(Opcode.DECF);
        }

        return generateDecLong();
    }

    Instruction generateDecLong() {
        if (match(TokenType.DECL)) {
            return new Instruction(Opcode.DECL);            
        }

        return generateLoadGlobal();
    }

    // load, store from globals
    Instruction generateLoadGlobal() {
        if (match(TokenType.LOADG)) {
            if (!match(TokenType.IDENTIFIER))
                throw expected(TokenType.IDENTIFIER, "You need to provide a variable to load");

            string operand = previous().getLexeme!string;
            return new Instruction(Opcode.LOADG, operand);
        }

        return generateStoreGlobal();
    }

    Instruction generateStoreGlobal() {
        if (match(TokenType.STOREG)) {
            if (!match(TokenType.IDENTIFIER))
                throw expected(TokenType.IDENTIFIER, "You need to provide a variable to store");
            
            string operand = previous().getLexeme!string;
            return new Instruction(Opcode.STOREG, operand);
        }

        return generateLabel();
    }

    // block
    Instruction generateLabel() {
        if (match(TokenType.IDENTIFIER)) {
            string operand = previous().getLexeme!string;
            
            if (match(TokenType.COLON)) {
                return new Instruction(Opcode.LABEL, operand);
            }

            throw new VmError("Unknown opcode '" ~ to!string(previous().getLexeme()) ~ "'");
        }

        return generateCall();
    }

    // call
    Instruction generateCall() {
        if (match(TokenType.CALL)) {
             if (!match(TokenType.INT)) {
                
                if (match(TokenType.IDENTIFIER)) {
                    string destination = previous().getLexeme!string;
                    
                    if (!match(TokenType.INT)) throw expected(TokenType.INT, "You have to provide the number of arguments");
                    
                    int numOfArgs = previous().getLexeme!int;
                    
                    return new Instruction(Opcode.CALL, new CallPair(destination, numOfArgs));
                
                } else {
                    throw expected(TokenType.IDENTIFIER, "You have to provide a destination (int or label name) to jump to");
                }
            }
            
            int destination = previous().getLexeme!int;

            if (!match(TokenType.INT)) throw expected(TokenType.INT, "You have to provide the number of arguments");
                    
            int numOfArgs = previous().getLexeme!int;
                    
            return new Instruction(Opcode.CALL, new CallPair(destination, numOfArgs));
        }

        return generateRet();
    }

    // ret
    Instruction generateRet() {
        if (match(TokenType.RETURN)) {
            return new Instruction(Opcode.RET);
        }

        return generateHalt();
    }

    // halt
    Instruction generateHalt() {
        if (match(TokenType.HALT)) {
            return new Instruction(Opcode.HALT);
        }
       
       throw new VmError("Unknown opcode '" ~ to!string(curr().getLexeme()) ~ "'");
    }
}