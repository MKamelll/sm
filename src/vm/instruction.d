module vm.instruction;

import std.typecons;
import std.algorithm;
import std.conv;
import std.array;

enum Opcode : ubyte
{
    PUSHI, PUSHF, PUSHL,
    PUSHB,
    
    ADDI, ADDF, ADDL,
    SUBI, SUBF, SUBL,
    MULI, MULF, MULL,
    DIVI, DIVF, DIVL,
    DECI, DECF, DECL,

    CMPI, CMPF, CMPL,

    JMP, JE, JG, JL, JGE, JLE,
    HALT
}

class Instruction
{
    //TODO: constrain instruction to 4 bytes
    Opcode mOpcode;
    Nullable!byte mByteP;
    Nullable!short mShortP;
    Nullable!int mIntP;
 
    this (Opcode opcode) {
        mOpcode = opcode;
    }

    this (Opcode opcode, byte operand) {
        mOpcode = opcode;
        mByteP = operand;
    }
    
    this (Opcode opcode, short operand) {
        mOpcode = opcode;
        mShortP = operand;
    }

    this (Opcode opcode, int operand) {
        mOpcode = opcode;
        mIntP = operand;
    }

    Opcode getOpcode() {
        return mOpcode;
    }

    override string toString() {
        if (!mByteP.isNull) {
            return "Instruction(opcode: " ~ to!string(mOpcode) ~ ", byte: " ~ to!string(mByteP.get) ~ ")";    
        } else if (!mShortP.isNull) {
            return "Instruction(opcode: " ~ to!string(mOpcode) ~ ", short: " ~ to!string(mShortP.get) ~ ")";
        } else if (!mIntP.isNull) {
            return "Instruction(opcode: " ~ to!string(mOpcode) ~ ", int: " ~ to!string(mIntP.get) ~ ")";
        }
        
        return "Instruction(opcode: " ~ to!string(mOpcode) ~ ")";
    }
}