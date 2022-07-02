module vm.machine;

import std.conv;
import std.stdio;
import std.range;
import std.variant;
import std.algorithm;
import std.array;

import vm.instruction;
import vm.error;
import vm.program;
import vm.common;

class Machine
{
    Instruction[] mInstructions;
    const MAX_CAPACITY = 100;
    Stack mStack;
    Instruction mCurrInstruction;
    Variable[] mVariables;
    Label[] mLabels;
    int mIp;
    int mFp;
    int mSp;
    int mDepth;
    bool mHalt;
    bool mDebug;

    this (Program program) {
        mInstructions = program.getInstructions();
        mStack = [];
        mIp = 0;
        mSp = -1;
        mFp = 0;
        mDepth = 0;
        mHalt = false;
        mDebug = true;
    }

    bool isAtEnd() {
        if (!mHalt && mIp < mInstructions.length) {
            return false;
        }

        return true;
    }

    Variant pop() {
        if (mSp < 0) {
            throw new VmError("Not enough operands on the stack for instruction '"
                ~ to!string(mCurrInstruction.getOpcode()) ~ "'");
        }

        Variant elm = mStack[mSp--];
        mStack.popBack();

        return elm;
    }

    T pop(T)() {
        if (mSp < 0) {
            throw new VmError("Not enough operands on the stack for instruction '"
                ~ to!string(mCurrInstruction.getOpcode()) ~ "'");
        }

        Variant elm = mStack[mSp--];
        mStack.popBack();

        if (elm.peek!T) return elm.get!T; 
        
        throw new VmError("For opcode '" ~ to!string(mCurrInstruction.mOpcode)
            ~ "' expected type '" ~ to!string(typeid(T)) ~ "' instead got '" ~ to!string(elm.type) ~ "'");
    }

    void push(Variant value) {
        mSp++;
        if (mSp > MAX_CAPACITY) throw new VmError("Stack overflow");
        mStack ~= value;
    }

    void push(T)(string value) {
        mSp++;
        if (mSp > MAX_CAPACITY) throw new VmError("Stack overflow");

        try {
            mStack ~= Variant(to!T(value));
        } catch (Exception err) {
             throw new VmError("Opcode '" ~ to!string(mCurrInstruction.mOpcode) ~  ", Invalid operand: " ~ err.msg);
        }
    }

    void push(T)(T value) {
        mSp++;
        if (mSp > MAX_CAPACITY) throw new VmError("Stack overflow");

        try {
            mStack ~= Variant(to!T(value));
        } catch (Exception err) {
            throw new VmError("Opcode '" ~ to!string(mCurrInstruction.mOpcode) ~  ", Invalid operand: " ~ err.msg);
        }
    }

    Instruction advance() {
        mCurrInstruction = mInstructions[mIp++];
        return mCurrInstruction;
    }

    // random stack access
    Variant stackGetAt(int index) {
        Variant elm = mStack[index];
        return elm;
    }
    
    T stackGetAt(T) (int index) {
        Variant elm = mStack[index];

        if (elm.peek!T) return elm.get!T;

        throw new VmError("For opcode '" ~ to!string(mCurrInstruction.mOpcode)
            ~ "' expected type '" ~ to!string(typeid(T)) ~ "' instead got '" ~ to!string(elm.type) ~ "'");
    }

    void stackSetAt(int index, Variant newVal) {
        mStack[index] = newVal;
    }

    void stackSetAt(T) (int index, T newVal) {
        try {
            mStack[index] = Variant(to!T(newVal));
        }  catch (Exception err) {
            throw new VmError("Opcode '" ~ to!string(mCurrInstruction.mOpcode) ~  ", Invalid operand: " ~ err.msg);
        }
    }

    // query variables
    bool variablesContains(string query, int depth) {
        foreach_reverse (Variable var; mVariables) {
            if (var.getName() == query && var.getDepth() <= depth) return true;
        }
        return false;
    }

    void variablesAppend(T)(string name, T value, int depth) {
        mVariables ~= new Variable(name, value, depth);
    }

    void variablesAppend(string name, Variant value, int depth) {
        mVariables ~= new Variable(name, value, depth);
    }

    T variablesGet(T)(string query, int depth) {
        if (variablesContains(query, depth)) {
            foreach_reverse (Variable var; mVariables)
            {
                if (var.getName() == query && var.getDepth() <= depth) {
                    return var.getValue!T;
                }
            }
        }

        throw new VmError("Undefined variable '" ~ query ~ "'");
    }

    Variant variablesGet(string query, int depth) {
        if (variablesContains(query, depth)) {
            foreach_reverse (Variable var; mVariables)
            {
                if (var.getName() == query && var.getDepth() <= depth) return var.getValue();
            }
        }

        throw new VmError("Undefined global variable '" ~ query ~ "'");
    }

    // query labels
    bool labelsContains(string query) {
        foreach_reverse (Label label; mLabels)
        {
            if (label.getName() == query) return true;
        }

        foreach (Instruction instruction; mInstructions)
        {
            // in case calling a label not yet defined
            if (instruction.getOpcode() == Opcode.LABEL && instruction.getOperand!string == query) return true;
        }

        return false;
    }

    void labelsAppend(string name, int destination) {
        mLabels ~= new Label(name, destination);
    }

    int labelsGet(string query) {
        if (labelsContains(query)) {
            foreach_reverse (Label label; mLabels)
            {
                if (label.getName() == query) return label.getDestination();
            }

            for (int i = 0; i < mInstructions.length; i++)
            {
                if (mInstructions[i].getOpcode() == Opcode.LABEL && mInstructions[i].getOperand!string == query)
                    return i;
            }
        }

        throw new VmError("Undefined global variable '" ~ query ~ "'");
    }

    int getEntryPoint() {
        for (int i = 0;  i < mInstructions.length; i++) {
            Instruction instruction = mInstructions[i];
            if (instruction.getOpcode() == Opcode.LABEL
                && instruction.peekOperand!string && instruction.getOperand!string == "main" ) return i;
        }

        throw new VmError("Expected a 'main' entry label");
    }

    /* ___________________________________________________________________________________________________________ */
    
    Variant[] run() {
        
        mIp = getEntryPoint();

        while (!isAtEnd()) {
            Instruction curr = advance();
            switch (curr.getOpcode()) {

                // int
                case Opcode.PUSHI: pushInt(); break;
                case Opcode.ADDI: addInt(); break;
                case Opcode.MULI: mulInt(); break;
                case Opcode.DIVI: divInt(); break;
                case Opcode.SUBI: subInt(); break;
                
                // long
                case Opcode.PUSHL: pushLong(); break;
                case Opcode.ADDL: addLong(); break;
                case Opcode.MULL: mulLong(); break;
                case Opcode.DIVL: divLong(); break;
                case Opcode.SUBL: subLong(); break;

                // float
                case Opcode.PUSHF: pushFloat(); break;
                case Opcode.ADDF: addFloat(); break;
                case Opcode.MULF: mulFloat(); break;
                case Opcode.DIVF: divFloat(); break;
                case Opcode.SUBF: subFloat(); break;

                // bool
                case Opcode.PUSHB: pushBool(); break;
                
                // jmp
                case Opcode.JMP: jump(); break;
                case Opcode.JE: jumpIfEqual(); break;
                case Opcode.JG: jumpIfGreater(); break;
                case Opcode.JL: jumpIfLess(); break;
                case Opcode.JGE: jumpIfGreaterOrEqual(); break;
                case Opcode.JLE: jumpIfLessOrEqual(); break;

                // cmp
                case Opcode.CMPI: compareInt(); break;
                case Opcode.CMPF: compareFloat(); break;
                case Opcode.CMPL: compareLong(); break;

                // dec
                case Opcode.DECI: decrementInt(); break;
                case Opcode.DECF: decrementFloat(); break;
                case Opcode.DECL: decrementLong(); break;

                // inc
                case Opcode.INCI: incrementInt(); break;
                case Opcode.INCF: incrementFloat(); break;
                case Opcode.INCL: incrementLong(); break;

                // load
                case Opcode.LOADI: loadInt(); break;
                case Opcode.LOADF: loadFloat(); break;
                case Opcode.LOADL: loadLong(); break;
                
                // store
                case Opcode.STOREI: storeInt(); break;
                case Opcode.STOREF: storeFloat(); break;
                case Opcode.STOREL: storeLong(); break;
                
                // label
                case Opcode.LABEL: label(); break;

                // call, return
                case Opcode.CALL: call(); break;
                case Opcode.TAIL: tailCall(); break;
                case Opcode.RET: ret(); break;
                
                // halt
                case Opcode.HALT: halt(); break;
                default: throw new VmError("Unkown Machine Instruction: '" ~ to!string(curr.getOpcode()) ~ "'");
            }
            
            if (mDebug) debugPrint();
        }
        
        return mStack;
    }

    // Int
    void pushInt() {
        push!int(mCurrInstruction.getOperand!int);
    }

    void addInt() {
        int firstOperand = pop!int;
        int secondOperand = pop!int;
        push!int(firstOperand + secondOperand);
    }

    void mulInt() {
        int firstOperand = pop!int;
        int secondOperand = pop!int;
        push!int(firstOperand * secondOperand);
    }

    void divInt() {
        int firstOperand = pop!int;
        int secondOperand = pop!int;
        push!int(secondOperand / firstOperand);
    }

    void subInt() {
        int firstOperand = pop!int;
        int secondOperand = pop!int;
        push!int(secondOperand - firstOperand);
    }
    
    // Long
    void pushLong() {
        push!long(mCurrInstruction.getOperand!long);
    }

    void addLong() {
        long firstOperand = pop!long;
        long secondOperand = pop!long;
        push!long(firstOperand + secondOperand);
    }

    void mulLong() {
        long firstOperand = pop!long;
        long secondOperand = pop!long;
        push!long(firstOperand * secondOperand);
    }

    void divLong() {
        long firstOperand = pop!long;
        long secondOperand = pop!long;
        push!long(secondOperand / firstOperand);
    }

    void subLong() {
        long firstOperand = pop!long;
        long secondOperand = pop!long;
        push!long(secondOperand - firstOperand);
    }

    // Float
    void pushFloat() {
        push!float(mCurrInstruction.getOperand!float);
    }

    void addFloat() {
        float firstOperand = pop!float;
        float secondOperand = pop!float;
        push!float(firstOperand + secondOperand);
    }

    void mulFloat() {
        float firstOperand = pop!float;
        float secondOperand = pop!float;
        push!float(firstOperand * secondOperand);
    }

    void divFloat() {
        float firstOperand = pop!float;
        float secondOperand = pop!float;
        push!float(secondOperand / firstOperand);
    }

    void subFloat() {
        float firstOperand = pop!float;
        float secondOperand = pop!float;
        push!float(secondOperand - firstOperand);
    }

    // bool
    void pushBool() {
        push!bool(mCurrInstruction.getOperand!bool);
    }

    // jmp

    int getADestination() {
        int destination;
        if (mCurrInstruction.peekOperand!string) {
            string labelName = mCurrInstruction.getOperand!string;
            destination = labelsGet(labelName);
        } else {
            destination = mCurrInstruction.getOperand!int;
        }
        return destination;
    }
    
    void jump() {
        mIp = getADestination();
    }

    void jumpIfEqual() {
        int operand = pop!int;

        if (operand == 0) {
            mIp = getADestination();
        }
    }

    void jumpIfGreater() {
        int operand = pop!int;

        if (operand > 0) {
            mIp = getADestination();
        }
    }

    void jumpIfLess() {
        int operand = pop!int;

        if (operand < 0) {
            mIp = getADestination();
        }
    }

    void jumpIfGreaterOrEqual() {
        int operand = pop!int;

        if (operand == 0 || operand > 0) {
            mIp = getADestination();
        }
    }

    void jumpIfLessOrEqual() {
        int operand = pop!int;

        if (operand == 0 || operand < 0) {
            mIp = getADestination();
        }
    }

    // cmp
    void compareInt() {
        int firstOperand = pop!int;
        int secondOperand = pop!int;

        if (secondOperand == firstOperand) {
            push!int(0);
        } else if (secondOperand > firstOperand) {
            push!int(1);
        } else if (secondOperand < firstOperand) {
            push!int(-1);
        }
    }

    void compareFloat() {
        float firstOperand = pop!float;
        float secondOperand = pop!float;

        if (secondOperand == firstOperand) {
            push!int(0);
        } else if (secondOperand > firstOperand) {
            push!int(1);
        } else if (secondOperand < firstOperand) {
            push!int(-1);
        }
    }

    void compareLong() {
        long firstOperand = pop!long;
        long secondOperand = pop!long;

        if (secondOperand == firstOperand) {
            push!int(0);
        } else if (secondOperand > firstOperand) {
            push!int(1);
        } else if (secondOperand < firstOperand) {
            push!int(-1);
        }
    }

    // dec
    void decrementInt() {
        int value = pop!int;
        --value;
        push!int(value);
    }

    void decrementFloat() {
        float value = pop!float;
        --value;
        push!float(value);
    }
    
    void decrementLong() {
        long value = pop!long;
        --value;
        push!long(value);
    }

    // inc
    void incrementInt() {
        int value = pop!int;
        if (value >= int.max) {
            throw new VmError("Inc 'int' overflow");
        }

        value++;
        push!int(value);
    }

    void incrementFloat() {
        float value = pop!float;
        if (value >= float.max) {
            throw new VmError("Inc 'float' overflow");
        }

        value++;
        push!float(value);
    }

    void incrementLong() {
        long value = pop!long;
        if (value >= long.max) {
            throw new VmError("Inc 'long' overflow");
        }

        value++;
        push!long(value);
    }

    // label
    void label() {
        string labelName = mCurrInstruction.getOperand!string;
        
        if (!labelsContains(labelName)) {
            labelsAppend(labelName, mIp);
        }

    }

    // call
    void call() {

        mDepth++;

        CallPair callParameters = mCurrInstruction.getOperand!CallPair;
        
        int destination;
        if (callParameters.peekDestination!string) {
            string label = callParameters.getDestination!string;
            destination = labelsGet(label);
        } else if (callParameters.peekDestination!int) {
            destination = callParameters.getDestination!int;
        }

        int argsNum = callParameters.numOfArgs();

        // save number of args
        push!int(argsNum);

        // save current frame pointer
        push!int(mFp);

        // save the return address
        push!int(mIp);

        // set the frame pointer to the current stack pointer
        mFp = mSp;
        
        // set the instruction pointer to inside function
        mIp = destination;
    }

    // tail
    void tailCall() {
        CallPair callParameters = mCurrInstruction.getOperand!CallPair;

        int destination;
        if (callParameters.peekDestination!string) {
            string label = callParameters.getDestination!string;
            destination = labelsGet(label);
        } else if (callParameters.peekDestination!int) {
            destination = callParameters.getDestination!int;
        }

        int argsNum = callParameters.numOfArgs();

        int startOfArgs = mFp - 3;
        
        for (int i = 0; i < argsNum; i++) {
            Variant arg = pop();
            stackSetAt(startOfArgs - i, arg);
        }

        mSp = mFp;

        mIp = destination;
    }

    // ret
    void ret() {
        bool isReturnValue = false;
        Variant returnValue;

        if (mFp != mSp) {
            isReturnValue = true;
            returnValue = pop();
        }

        if (mDepth == 0) {
            push(returnValue);
            return;
        }

        // set the stack pointer to the previous frame pointer
        mSp = mFp;

        // pop the return address
        int destination = pop!int;
        mIp = destination;

        int prevFp = pop!int;
        mFp = prevFp;

        int numOfArgs = pop!int;

        for (int i = 0; i < numOfArgs; i++) pop();

        foreach_reverse (Variable var; mVariables) {
            if (var.getDepth() == mDepth) mVariables.popBack();
        }

        if (isReturnValue) {
            push(returnValue);
        }

        mDepth--;
    }

    // load
    void loadInt() {

        int numOfArgs;
        int startOfFrame;
        int endOfFrame;

        if (mDepth == 0) {
            numOfArgs = 0;
            startOfFrame = 0;
            endOfFrame = mSp;
        } else {
            numOfArgs = stackGetAt!int(mFp - 2);
            startOfFrame = mFp - 2 - numOfArgs;
            endOfFrame = mSp;
        }

        if (mCurrInstruction.peekOperand!string) {
            string var = mCurrInstruction.getOperand!string;
            push!int(variablesGet!int(var, mDepth));
        } else {
            int varIndexOnFrame = mCurrInstruction.getOperand!int + startOfFrame;
            if (varIndexOnFrame > endOfFrame) {
                throw new VmError("Tried accessing a local variable index '"
                    ~ to!string(varIndexOnFrame) ~ "' outside a frame that ends at '" ~ to!string(endOfFrame) ~ "'");
            }
            push!int(stackGetAt!int(varIndexOnFrame));
        }
    }

    void loadFloat() {

        int numOfArgs;
        int startOfFrame;
        int endOfFrame;

        if (mDepth == 0) {
            numOfArgs = 0;
            startOfFrame = 0;
            endOfFrame = mSp;
        } else {
            numOfArgs = stackGetAt!int(mFp - 2);
            startOfFrame = mFp - 2 - numOfArgs;
            endOfFrame = mSp;
        }

        if (mCurrInstruction.peekOperand!string) {
            string var = mCurrInstruction.getOperand!string;
            push!float(variablesGet!float(var, mDepth));
        } else {
            int varIndexOnFrame = mCurrInstruction.getOperand!int + startOfFrame;
            if (varIndexOnFrame > endOfFrame) {
                throw new VmError("Tried accessing a local variable index '"
                    ~ to!string(varIndexOnFrame) ~ "' outside a frame that ends at '" ~ to!string(endOfFrame) ~ "'");
            }
            push!float(stackGetAt!float(varIndexOnFrame));
        }
    }

    void loadLong() {

        int numOfArgs;
        int startOfFrame;
        int endOfFrame;

        if (mDepth == 0) {
            numOfArgs = 0;
            startOfFrame = 0;
            endOfFrame = mSp;
        } else {
            numOfArgs = stackGetAt!int(mFp - 2);
            startOfFrame = mFp - 2 - numOfArgs;
            endOfFrame = mSp;
        }

        if (mCurrInstruction.peekOperand!string) {
            string var = mCurrInstruction.getOperand!string;
            push!long(variablesGet!long(var, mDepth));
        } else {
            int varIndexOnFrame = mCurrInstruction.getOperand!int + startOfFrame;
            if (varIndexOnFrame > endOfFrame) {
                throw new VmError("Tried accessing a local variable index '"
                    ~ to!string(varIndexOnFrame) ~ "' outside a frame that ends at '" ~ to!string(endOfFrame) ~ "'");
            }
            push!long(stackGetAt!long(varIndexOnFrame));
        }
    }

    // store
    void storeInt() {
        int value = pop!int;
        string var = mCurrInstruction.getOperand!string;
        variablesAppend!int(var, value, mDepth);
    }

    void storeFloat() {
        float value = pop!float;
        string var = mCurrInstruction.getOperand!string;
        variablesAppend!float(var, value, mDepth);
    }
    
    void storeLong() {
        long value = pop!long;
        string var = mCurrInstruction.getOperand!string;
        variablesAppend!long(var, value, mDepth);
    }

    // halt
    void halt() {
        mHalt = true;
    }

    void debugPrint() {
        writeln("Stack => " ~ to!string(mStack) ~ ", currInst: " ~ mCurrInstruction.toString());
    }
}
