#------------------------------------------------------------------------------
#
#  Tagstats Makefile
#
#------------------------------------------------------------------------------
#
#  You can set several environment variables before running make if you don't
#  like the defaults:
#
#  CXX                - Your C++ compiler.
#  CPLUS_INCLUDE_PATH - Include file search path. This should include the
#                       directory where Osmium is.
#  CXXFLAGS           - Extra compiler flags.
#  LDFLAGS            - Extra linker flags.
#  
#------------------------------------------------------------------------------

CXXFLAGS += -O3
#CXXFLAGS += -g
CXXFLAGS += -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64
CXXFLAGS += `../bin/taginfo-config.rb tagstats.cxxflags`

GEODISTRIBUTION_TYPE := $(shell ../bin/taginfo-config.rb tagstats.geodistribution_int uint16_t)
BYID := $(shell ../bin/taginfo-config.rb tagstats.geodistribution)
#BYID := SparseTable
#BYID := MmapFile
#BYID := MmapAnon
BYID_LC   := $(shell echo $(BYID) | sed -e 's/\([A-Z]\)/_\1/g' | cut -c2- | tr 'A-Z' 'a-z')
BYID_INCL := "<osmium/storage/byid/$(BYID_LC).hpp>"

CXXFLAGS_FEATURES += -DTAGSTATS_COUNT_USERS
CXXFLAGS_FEATURES += -DTAGSTATS_COUNT_KEY_COMBINATIONS
CXXFLAGS_FEATURES += -DTAGSTATS_COUNT_TAG_COMBINATIONS
CXXFLAGS_FEATURES += -DTAGSTATS_GEODISTRIBUTION_INT=$(GEODISTRIBUTION_TYPE)
CXXFLAGS_FEATURES += -DTAGSTATS_GEODISTRIBUTION_FOR_WAYS=$(BYID)
CXXFLAGS_FEATURES += -DTAGSTATS_GEODISTRIBUTION_INCLUDE=$(BYID_INCL)

CXXFLAGS_WARNINGS := -Wall -Wextra -Wredundant-decls -Wdisabled-optimization -pedantic

LIB_EXPAT  := -lexpat
LIB_PBF    := -lz -lpthread -lprotobuf-lite -losmpbf
LIB_GD     := -lgd -lz -lm
LIB_SQLITE := -lsqlite3

.PHONY: all check indent install clean

all: tagstats osmstats

osmstats: osmstats.cpp statistics_handler.hpp
	$(CXX) $(CXXFLAGS) $(CXXFLAGS_WARNINGS) -o $@ $< $(LDFLAGS) $(LIB_EXPAT) $(LIB_PBF) $(LIB_SQLITE)

tagstats: tagstats.cpp tagstats_handler.hpp statistics_handler.hpp string_store.hpp geodistribution.hpp sqlite.hpp
	$(CXX) $(CXXFLAGS) $(CXXFLAGS_WARNINGS) $(CXXFLAGS_FEATURES) -o $@ $< $(LDFLAGS) $(LIB_EXPAT) $(LIB_PBF) $(LIB_SQLITE) $(LIB_GD)

check:
	cppcheck --enable=all tagstats.cpp osmstats.cpp

indent:
	astyle --style=java --indent-namespaces --indent-switches --pad-header --suffix=none \*.hpp \*.cpp

install:
	install -m 755 tagstats ../sources/db/tagstats

clean:
	rm -f *.o core tagstats osmstats

