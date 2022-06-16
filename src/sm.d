module sm;

import vm.error;
import vm.program;
import vm.machine;
import vm.lexer;

import std.stdio;
import std.algorithm;
import std.string : strip;

void run(string src) {
    auto lexer = new Lexer(src);
    auto program = new Generator(lexer).generate();
    auto machine = new Machine(program);
    writeln(machine.run());
}

int main() {

    writeln("Welcome to Sm..");
    while (true) {
        write(">> ");
        string line;
        if ((line = readln()) !is null) {
           if (line.startsWith("\n")) continue;
           
           if (line.startsWith(":q") || line.startsWith("quit") ||
                line.startsWith("exit") || line.startsWith(":Q")) {
                writeln("Goodbye.");
                break;
            }

            line = line.strip();

            try {
                run(line);

            } catch (VmError err) {
                writeln(err);
                continue;
            }
        }
    }

    return 0;
}