#------------------------------------------------------------------------------
#
#  Tagstats Makefile
#
#------------------------------------------------------------------------------

CXX = g++

CXXFLAGS = -g
#CXXFLAGS = -O3

CXXFLAGS += -std=c++0x -Wall -W -Wredundant-decls -Wdisabled-optimization -pedantic
#CXXFLAGS += -Wpadded -Winline

CXXFLAGS += -DTAGSTATS_COUNT_USERS
CXXFLAGS += -DTAGSTATS_COUNT_KEY_COMBINATIONS

CXXFLAGS += -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64

CXXFLAGS += -I../include -I../../../osmium/osmium/include

LDFLAGS = -L/usr/local/lib -lexpat -lpthread

LIB_SQLITE   = -lsqlite3
LIB_GD       = -lgd -lz -lm
LIB_PROTOBUF = -lz -lprotobuf-lite -losmpbf

.PHONY: all clean install

all: tagstats

tagstats: tagstats.cpp tagstats_handler.hpp string_store.hpp
	$(CXX) $(CXXFLAGS) -o $@ $< $(LDFLAGS) $(LIB_PROTOBUF) $(LIB_GD) $(LIB_SQLITE)

install:
	install -m 755 -g root -o root -d $(DESTDIR)/usr/bin
	install -m 755 -g root -o root tagstats $(DESTDIR)/usr/bin/tagstats
    
clean:
	rm -f *.o core tagstats

