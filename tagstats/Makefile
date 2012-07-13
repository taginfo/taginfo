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
CXXFLAGS += -DTAGSTATS_COUNT_TAG_COMBINATIONS

CXXFLAGS += -DTAGSTATS_GEODISTRIBUTION_INT=uint16_t

BYID := $(shell ../bin/taginfo-config.rb tagstats.geodistribution)
#BYID := SparseTable
#BYID := MmapFile
#BYID := MmapAnon

BYID_LC   := $(shell echo $(BYID) | sed -e 's/\([A-Z]\)/_\0/g' | cut -c2- | tr 'A-Z' 'a-z')
BYID_INCL := "<osmium/storage/byid/$(BYID_LC).hpp>"

CXXFLAGS += -DTAGSTATS_GEODISTRIBUTION_FOR_WAYS=$(BYID)
CXXFLAGS += -DTAGSTATS_GEODISTRIBUTION_INCLUDE=$(BYID_INCL)

CXXFLAGS += -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64

CXXFLAGS += `../bin/taginfo-config.rb tagstats.cxxflags`

LDFLAGS = -L/usr/local/lib -lexpat -lpthread

LIB_SQLITE   = -lsqlite3
LIB_GD       = -lgd -lz -lm
LIB_PROTOBUF = -lz -lprotobuf-lite -losmpbf

.PHONY: all clean install

all: tagstats

tagstats: tagstats.cpp tagstats_handler.hpp statistics_handler.hpp string_store.hpp geodistribution.hpp
	$(CXX) $(CXXFLAGS) -o $@ $< $(LDFLAGS) $(LIB_PROTOBUF) $(LIB_GD) $(LIB_SQLITE)

check:
	cppcheck --enable=all tagstats.cpp

indent:
	astyle --style=java --indent-namespaces --indent-switches --pad-header --suffix=none \*.hpp \*.cpp

install:
	install -m 755 tagstats ../sources/db/tagstats

clean:
	rm -f *.o core tagstats

