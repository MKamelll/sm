SRC=./src
VM=./src/vm

parse: $(VM)/lexer.d $(SRC)/*.d $(VM)/error.d
	mkdir -p build
	dmd $^ -of=build/$@

sm: $(SRC)/*.d $(VM)/*.d
	mkdir -p build
	dmd $^ -of=build/$@