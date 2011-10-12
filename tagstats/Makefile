#------------------------------------------------------------------------------
#
#  Tagstats Makefile
#
#------------------------------------------------------------------------------

CXX = g++

#CXXFLAGS = -g
CXXFLAGS = -O3

CXXFLAGS += -std=c++0x -Wall -Wextra -Wredundant-decls -Wdisabled-optimization -pedantic
#CXXFLAGS += -Wpadded -Winline

CXXFLAGS += -DTAGSTATS_COUNT_USERS
CXXFLAGS += -DTAGSTATS_COUNT_KEY_COMBINATIONS

CXXFLAGS += -DTAGSTATS_GEODISTRIBUTION_INT=uint16_t
CXXFLAGS += -DTAGSTATS_GEODISTRIBUTION_FOR_WAYS=SparseTable
#CXXFLAGS += -DTAGSTATS_GEODISTRIBUTION_FOR_WAYS=Mmap

CXXFLAGS += -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64

CXXFLAGS += -I../../../osmium/osmium/include

LDFLAGS = -L/usr/local/lib -lexpat -lpthread

LIB_SQLITE   = -lsqlite3
LIB_GD       = -lgd -lz -lm
LIB_PROTOBUF = -lz -lprotobuf-lite -losmpbf

.PHONY: all clean install

all: tagstats

tagstats: tagstats.cpp tagstats_handler.hpp string_store.hpp geodistribution.hpp
	$(CXX) $(CXXFLAGS) -o $@ $< $(LDFLAGS) $(LIB_PROTOBUF) $(LIB_GD) $(LIB_SQLITE)

check:
	cppcheck --enable=all tagstats.cpp

indent:
	astyle --style=java --indent-namespaces --indent-switches --pad-header --suffix=none \*.hpp \*.cpp

install:
	install -m 755 tagstats ../sources/db/tagstats

clean:
	rm -f *.o core tagstats

