module vm.common;

import std.typecons;
import std.conv;
import std.variant;

import vm.error;

alias Stack = Variant[];

class CallPair
{
    Variant mDestination;
    int mNumOfArgs;

    this (Variant dest, int num) {
        mDestination = dest;
        mNumOfArgs = num;
    }

    this (string dest, int num) {
        mDestination = Variant(dest);
        mNumOfArgs = num;
    }

    this (int dest, int num) {
        mDestination = Variant(dest);
        mNumOfArgs = num;
    }

    int numOfArgs() {
        return mNumOfArgs;
    }

    bool peekDestination(T)() {
        if (mDestination.peek!T) return true;
        return false;
    }

    Variant getDestination() {
        return mDestination;
    }

    T getDestination(T)() {
        if (peekDestination!T) {
            return mDestination.get!T;
        }

        throw new VmError("Call pair contains type '" 
            ~ to!string(typeid(typeof(mDestination))) ~ "' not '" ~ to!string(typeid(T)) ~ "'");
    }

    override string toString() {
        return "(" ~ to!string(mDestination) ~ ", " ~ to!string(mNumOfArgs) ~ ")";
    }
}

class Variable
{
    string mName;
    Variant mValue;
    int mDepth;

    this (string name, Variant value, int depth) {
        mName = name;
        mValue = value;
        mDepth = depth;
    }
    
    this (string name, string value, int depth) {
        mName = name;
        mValue = Variant(value);
        mDepth = depth;
    }

    this (string name, int value, int depth) {
        mName = name;
        mValue = Variant(value);
        mDepth = depth;
    }

    this (string name, float value, int depth) {
        mName = name;
        mValue = Variant(value);
        mDepth = depth;
    }
    
    this (string name, double value, int depth) {
        mName = name;
        mValue = Variant(value);
        mDepth = depth;
    }

    this (string name, long value, int depth) {
        mName = name;
        mValue = Variant(value);
        mDepth = depth;
    }

    string getName() {
        return mName;
    }

    Variant getValue() {
        return mValue;
    }

    T getValue(T)() {
        if (mValue.peek!T) return mValue.get!T;

        throw new VmError("Variable '" ~ mName ~ "' is of type '"
            ~ to!string(mValue.type) ~ "', asked for type '" ~ to!string(typeid(T)) ~ "'");
    }

    int getDepth() {
        return mDepth;
    }

    override string toString() {
        return "(" ~ mName ~ ", " ~ to!string(mValue) ~ ", " ~ to!string(mDepth) ~ ")";
    }
}

class Label
{
    string mName;
    int mDestination;

    this (string name, int destination) {
        mName = name;
        mDestination = destination;
    }

    string getName() {
        return mName;
    }

    int getDestination() {
        return mDestination;
    }

    override string toString() {
        return "(" ~ mName ~ ", " ~ to!string(mDestination) ~")";
    }
}