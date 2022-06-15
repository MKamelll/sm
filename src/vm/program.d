module vm.program;

import std.array;
import std.algorithm;
import std.string;
import std.conv;
import std.stdio;
import std.typecons;

import vm.instruction;
import vm.error;
import vm.lexer;

class Program
{
    private Instruction[] mProgram;
    private Lexer mLexer;
    private Token mCurrToken;
    private Token mPrevToken;

    this (Lexer lexer) {
        mLexer = lexer;
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

    VmError expected(TokenType type, string hint = "") {
        if (hint.length > 0) {
            return new VmError("Expected '" ~ type
                ~ "' instead got '" ~ mCurrToken.getType() ~ "'" ~ "\n=> Hint: " ~ hint);    
        }
        return new VmError("For '" ~ previous().getType() ~ "' expected '"
            ~ type ~ "' instead got '" ~ mCurrToken.getType() ~ "'");
    }

    Token previous() {
        return mPrevToken;
    }

    Token curr() {
        return mCurrToken;
    }

    Instruction[] generate() {
        mProgram ~= generatePushInt();
        if (!match(TokenType.SEMICOLON)) throw expected(TokenType.SEMICOLON);
        if (isAtEnd()) return mProgram;
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

            bool operand = previous().getLexeme!bool;
            return new Instruction(Opcode.PUSHB, operand);
        }
        
        return generateJmp();
    }

    // jmp
    Instruction generateJmp() {
        if (match(TokenType.JMP)) {
            if (!match(TokenType.INT)) throw expected(TokenType.INT, "You have to provide a destination to jump to");
            
            int operand = previous().getLexeme!int;
            
            return new Instruction(Opcode.JMP, operand);
        }
        
        return generateJe();
    }

    Instruction generateJe() {
        if (match(TokenType.JE)) {
            if (!match(TokenType.INT)) throw expected(TokenType.INT, "You have to provide a destination to jump to");
            
            int operand = previous().getLexeme!int;
            return new Instruction(Opcode.JE, operand);
        }
        
        return generateJg();
    }

    
    Instruction generateJg() {
        if (match(TokenType.JG)) {
            if (!match(TokenType.INT)) throw expected(TokenType.INT, "You have to provide a destination to jump to");
            
            int operand = previous().getLexeme!int;
            return new Instruction(Opcode.JG, operand);
        }
        
        return generateJl();
    }

    
    Instruction generateJl() {
        if (match(TokenType.JL)) {
            if (!match(TokenType.INT)) throw expected(TokenType.INT, "You have to provide a destination to jump to");
            
            int operand = previous().getLexeme!int;
            return new Instruction(Opcode.JL, operand);
        }
        
        return generateJge();
    }

    
    Instruction generateJge() {
        if (match(TokenType.JGE)) {
            if (!match(TokenType.INT)) throw expected(TokenType.INT, "You have to provide a destination to jump to");
            
            int operand = previous().getLexeme!int;
            return new Instruction(Opcode.JGE, operand);
        }
        
        return generateJle();
    }

    
    Instruction generateJle() {
        if (match(TokenType.JLE)) {
            if (!match(TokenType.INT)) throw expected(TokenType.INT, "You have to provide a destination to jump to");
            
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
            if (!match(TokenType.INT)) throw expected(TokenType.INT, "You have to provide a destination to decrement");
            
            int operand = previous().getLexeme!int;
            return new Instruction(Opcode.DECI, operand);
        }

        return generateDecFloat();
    }

    Instruction generateDecFloat() {
        if (match(TokenType.DECF)) {
            if (!match(TokenType.INT)) throw expected(TokenType.INT, "You have to provide a destination to decrement");
            
            int operand = previous().getLexeme!int;
            return new Instruction(Opcode.DECF, operand);
        }

        return generateDecLong();
    }

    Instruction generateDecLong() {
        if (match(TokenType.DECL)) {
            if (!match(TokenType.INT)) throw expected(TokenType.INT, "You have to provide a destination to decrement");
            
            int operand = previous().getLexeme!int;
            return new Instruction(Opcode.DECL, operand);            
        }

        return generateHalt();
    }

    // halt
    Instruction generateHalt() {
        if (match(TokenType.HALT)) {
            return new Instruction(Opcode.HALT);
        }
       
       throw new VmError("Unknown opcode '" ~ curr().getLexeme!string(true) ~ "'");
    }
}