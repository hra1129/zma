SRCS = $(wildcard ../*.cpp) $(wildcard ../sub/*.cpp)
OBJS = $(patsubst ../%.cpp,%.o,$(patsubst ../sub/%.cpp,%.o,$(SRCS)))

zma: $(OBJS)
	g++ *.o -o zma

%.o: ../%.cpp
	g++ -std=c++17 -W -Wno-unused-parameter -c -I.. -I../sub $^
%.o: ../sub/%.cpp
	g++ -std=c++17 -W -Wno-unused-parameter -c -I.. -I../sub $^
clean:
	rm -f *.o zma
