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
#                       directory where the Libosmium includes are.
#  CXXFLAGS           - Extra compiler flags.
#  LDFLAGS            - Extra linker flags.
#
#------------------------------------------------------------------------------

CXXFLAGS += -O3
#CXXFLAGS += -g
#CXXFLAGS += -g -pg
#CXXFLAGS += -g -fprofile-arcs -ftest-coverage
CXXFLAGS += -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 -std=c++11
CXXFLAGS += $(shell ../bin/taginfo-config.rb tagstats.cxxflags)

GEODISTRIBUTION_TYPE := $(shell ../bin/taginfo-config.rb tagstats.geodistribution_int uint16_t)
BYID := $(shell ../bin/taginfo-config.rb tagstats.geodistribution)
#BYID := SparseMemArray
#BYID := DenseMemArray
#BYID := DenseMmapArray
BYID_LC   := $(shell echo $(BYID) | sed -e 's/\([A-Z]\)/_\1/g' | cut -c2- | tr 'A-Z' 'a-z')
BYID_INCL := "<osmium/index/map/$(BYID_LC).hpp>"

CXXFLAGS_FEATURES += -DTAGSTATS_GEODISTRIBUTION_INT=$(GEODISTRIBUTION_TYPE)
CXXFLAGS_FEATURES += -DTAGSTATS_GEODISTRIBUTION_FOR_WAYS=$(BYID)
CXXFLAGS_FEATURES += -DTAGSTATS_GEODISTRIBUTION_INCLUDE=$(BYID_INCL)

CXXFLAGS_WARNINGS := -Wall -Wextra -pedantic -Wredundant-decls -Wdisabled-optimization -Wctor-dtor-privacy -Wnon-virtual-dtor -Woverloaded-virtual -Wsign-promo -Wold-style-cast

LIB_IO     := -pthread -lexpat -lbz2 -lz
LIB_GD     := -lgd -lz -lm
LIB_SQLITE := -lsqlite3
LIB_ICU    := $(shell pkg-config --libs icu-uc icu-io)

CXXFLAGS_ICU := $(shell pkg-config --cflags icu-uc icu-io)

.PHONY: all check indent install clean

all: tagstats osmstats similarity taginfo_unicode

osmstats: osmstats.cpp statistics_handler.hpp
	$(CXX) $(CXXFLAGS) $(CXXFLAGS_WARNINGS) -o $@ $< $(LDFLAGS) $(LIB_IO) $(LIB_SQLITE)

tagstats: tagstats.cpp tagstats_handler.hpp statistics_handler.hpp string_store.hpp geodistribution.hpp sqlite.hpp
	$(CXX) $(CXXFLAGS) $(CXXFLAGS_WARNINGS) $(CXXFLAGS_FEATURES) -o $@ $< $(LDFLAGS) $(LIB_IO) $(LIB_SQLITE) $(LIB_GD)

similarity: similarity.cpp sqlite.hpp
	$(CXX) $(CXXFLAGS) $(CXXFLAGS_WARNINGS) -o $@ $< $(LDFLAGS) $(LIB_SQLITE)

taginfo_unicode: taginfo_unicode.cpp sqlite.hpp
	$(CXX) $(CXXFLAGS) $(CXXFLAGS_WARNINGS) $(CXXFLAGS_ICU) -o $@ $< $(LDFLAGS) $(LIB_SQLITE) $(LIB_ICU)

check:
	cppcheck --enable=all tagstats.cpp osmstats.cpp similarity.cpp taginfo_unicode.cpp

indent:
	astyle --style=java --indent-namespaces --indent-switches --pad-header --suffix=none \*.hpp \*.cpp

install:
	install -m 755 tagstats ../sources/db/tagstats

clean:
	rm -f *.o *.gcno *.gcda *.gcov gmon.out core tagstats osmstats similarity taginfo_unicode

