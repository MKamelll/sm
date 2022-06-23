module vm.common;

import std.typecons;
import std.conv;
import std.variant;

import vm.error;

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