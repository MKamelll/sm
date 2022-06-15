module vm.instruction;

import std.typecons;
import std.conv;

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
    Opcode mOpcode;
    Nullable!byte mP1;
    Nullable!short mP2;
    Nullable!int mP3;

    this (Opcode opcode) {
        mOpcode = opcode;
    }

    this (Opcode opcode, byte operand) {
        mOpcode = opcode;
        mP1 = operand;
    }
    
    this (Opcode opcode, short operand) {
        mOpcode = opcode;
        mP2 = operand;
    }

    this (Opcode opcode, int operand) {
        mOpcode = opcode;
        mP3 = operand;
    }

    Opcode getOpcode() {
        return mOpcode;
    }

    override string toString() {
        auto operands = [mP1, mP2, mP3].filter!(p => !p.isNull)
                                       .array
                                       .map!(p => p.get)
                                       .array;
        if (operands.length > 0) {
            return "Instruction(opcode: " ~ to!string(mOpcode) ~ ", operand: [" ~ to!string(operands) ~ "]" ~ ")";
        }
        
        return "Instruction(opcode: " ~ to!string(mOpcode) ~ ")";
    }
}