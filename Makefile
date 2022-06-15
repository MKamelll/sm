SRC=./src
VM=./src/vm

sm: $(SRC)/*.d $(VM)/*.d
	mkdir -p build
	dmd $^ -of=build/$@