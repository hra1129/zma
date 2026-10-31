# ----------------------------------------------------------------------------
#	zma Linux Makefile
#
#	Incremental / parallel build:
#	  - object files are placed under obj/ (mirroring the source layout)
#	  - header dependencies are tracked automatically (-MMD -MP)
#	  - parallel builds are supported (make -j)
# ----------------------------------------------------------------------------

CXX      = g++
CXXFLAGS = -std=c++17 -W -Wno-unused-parameter
CPPFLAGS = -I.. -I../sub
DEPFLAGS = -MMD -MP

SRCS = $(wildcard ../*.cpp) $(wildcard ../sub/*.cpp)
OBJS = $(patsubst ../%.cpp,obj/%.o,$(SRCS))
DEPS = $(OBJS:.o=.d)

TARGET = zma

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CXX) $(OBJS) -o $@

obj/sub/%.o: ../sub/%.cpp
	@mkdir -p $(@D)
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) $(DEPFLAGS) -c $< -o $@

obj/%.o: ../%.cpp
	@mkdir -p $(@D)
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) $(DEPFLAGS) -c $< -o $@

clean:
	rm -rf obj $(TARGET)
	rm -f *.o

-include $(DEPS)

.PHONY: all clean
