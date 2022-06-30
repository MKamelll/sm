module vm.instruction;

import std.typecons;
import std.variant;
import std.algorithm;
import std.conv;
import std.array;

import vm.error;
import vm.common;

enum Opcode : ubyte
{
    PUSHI, PUSHF, PUSHL,
    PUSHB,
    
    ADDI, ADDF, ADDL,
    SUBI, SUBF, SUBL,
    MULI, MULF, MULL,
    DIVI, DIVF, DIVL,
    
    DECI, DECF, DECL,
    
    LOADI, LOADF, LOADL,
    STOREI, STOREF, STOREL,

    CMPI, CMPF, CMPL,

    JMP, JE, JG, JL, JGE, JLE,
    HALT, LABEL, CALL, RET
}

class Instruction
{
    Opcode mOpcode;
    Nullable!Variant mOperand;
 
    this (Opcode opcode) {
        mOpcode = opcode;
    }

    this (Opcode opcode, Variant operand) {
        mOpcode = opcode;
        mOperand = operand;
    }

    this (Opcode opcode, CallPair operand) {
        mOpcode = opcode;
        mOperand = Variant(operand);
    }

    this (Opcode opcode, int operand) {
        mOpcode = opcode;
        mOperand = Variant(operand);
    }

    this (Opcode opcode, long operand) {
        mOpcode = opcode;
        mOperand = Variant(operand);
    }

    this (Opcode opcode, float operand) {
        mOpcode = opcode;
        mOperand = Variant(operand);
    }

    this (Opcode opcode, double operand) {
        mOpcode = opcode;
        mOperand = Variant(operand);
    }

    this (Opcode opcode, bool operand) {
        mOpcode = opcode;
        mOperand = Variant(operand);
    }

    this (Opcode opcode, string operand) {
        mOpcode = opcode;
        mOperand = Variant(operand);
    }

    Opcode getOpcode() {
        return mOpcode;
    }

    T getOperand(T)() {
        if (mOperand.isNull) throw new VmError("The instruction '" ~ mOpcode ~ "' doesn't have an operand");
        if (mOperand.get.peek!T) return mOperand.get.get!T;

        throw new VmError("Operand type '" ~ to!string(mOperand.get.type)
            ~ "' doesn't match asked type '" ~ to!string(typeid(T)) ~ "'");
    }

    bool peekOperand(T)() {
        if (mOperand.get.peek!T) return true;
        return false;
    }

    override string toString() {
        if (!mOperand.isNull) return "(opcode: " ~ to!string(mOpcode) ~ ", operand: " ~ to!string(mOperand.get) ~ ")";
        
        return "(opcode: " ~ to!string(mOpcode) ~ ")";
    }
}