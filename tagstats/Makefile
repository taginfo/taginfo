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

CXXFLAGS_WARNINGS := -Wall -Wextra -pedantic -Wredundant-decls -Wdisabled-optimization -Wctor-dtor-privacy -Wnon-virtual-dtor -Woverloaded-virtual -Wsign-promo -Wold-style-cast

LIB_IO     := -pthread -lexpat -lbz2 -lz
LIB_GD     := -lgd -lz -lm
LIB_SQLITE := -lsqlite3
LIB_ICU    := $(shell pkg-config --libs icu-uc icu-io)

CXXFLAGS_ICU := $(shell pkg-config --cflags icu-uc icu-io)

PROGRAMS := tagstats osmstats similarity sizes taginfo_unicode

CPPFILES := $(wildcard *.cpp)


.PHONY: all check indent clean

all: $(PROGRAMS)

sizes: sizes.cpp
	$(CXX) $(CXXFLAGS) $(CXXFLAGS_WARNINGS) $(CXXFLAGS_FEATURES) -o $@ $< $(LDFLAGS)

osmstats: osmstats.cpp statistics_handler.hpp
	$(CXX) $(CXXFLAGS) $(CXXFLAGS_WARNINGS) -o $@ $< $(LDFLAGS) $(LIB_IO) $(LIB_SQLITE)

tagstats.o: tagstats.cpp tagstats_handler.hpp statistics_handler.hpp string_store.hpp geodistribution.hpp sqlite.hpp
	$(CXX) -c $(CXXFLAGS) $(CXXFLAGS_WARNINGS) $(CXXFLAGS_FEATURES) -o $@ $<

tagstats_handler.o: tagstats_handler.cpp tagstats_handler.hpp statistics_handler.hpp string_store.hpp geodistribution.hpp sqlite.hpp
	$(CXX) -c $(CXXFLAGS) $(CXXFLAGS_WARNINGS) $(CXXFLAGS_FEATURES) -o $@ $<

tagstats: tagstats.o tagstats_handler.o
	$(CXX) -o $@ $^ $(LDFLAGS) $(LIB_IO) $(LIB_SQLITE) $(LIB_GD)

similarity: similarity.cpp sqlite.hpp
	$(CXX) $(CXXFLAGS) $(CXXFLAGS_WARNINGS) -o $@ $< $(LDFLAGS) $(LIB_SQLITE)

taginfo_unicode: taginfo_unicode.cpp sqlite.hpp
	$(CXX) $(CXXFLAGS) $(CXXFLAGS_WARNINGS) $(CXXFLAGS_ICU) -o $@ $< $(LDFLAGS) $(LIB_SQLITE) $(LIB_ICU)

check:
	cppcheck --enable=all $(CPPFILES)

indent:
	astyle --style=java --indent-namespaces --indent-switches --pad-header --suffix=none \*.hpp \*.cpp

clean:
	rm -f *.o *.gcno *.gcda *.gcov gmon.out core $(PROGRAMS)

