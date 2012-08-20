/*

Copyright 2012 Jochen Topf <jochen@topf.org> and others (see README).

This file is part of Taginfo (https://github.com/joto/taginfo).

Osmium is free software: you can redistribute it and/or modify it under the
terms of the GNU Lesser General Public License or (at your option) the GNU
General Public License as published by the Free Software Foundation, either
version 3 of the Licenses, or (at your option) any later version.

Osmium is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU Lesser General Public License and the GNU
General Public License for more details.

You should have received a copy of the Licenses along with Osmium. If not, see
<http://www.gnu.org/licenses/>.

*/

#include <iostream>

#define OSMIUM_WITH_PBF_INPUT
#define OSMIUM_WITH_XML_INPUT

#include <osmium.hpp>
#include <osmium/handler.hpp>

#include "statistics_handler.hpp"

int main(int argc, char *argv[]) {
    if (argc != 3) {
        std::cerr << "Usage: " << argv[0] << " OSMFILE DATABASE" << std::endl;
        exit(1);
    }

    Osmium::OSMFile infile(argv[1]);

    Sqlite::Database db(argv[2]);
    sqlite3* sqlite_db = db.get_sqlite3();
    if (SQLITE_OK != sqlite3_exec(sqlite_db, \
                                  "CREATE TABLE stats (" \
                                  "  key    TEXT, " \
                                  "  value  INT64 " \
                                  ");", 0, 0, 0)) {
        std::cerr << "Database error: " << sqlite3_errmsg(sqlite_db) << "\n";
        sqlite3_close(sqlite_db);
        exit(1);
    }

    StatisticsHandler handler(db);
    Osmium::Input::read(infile, handler);

    google::protobuf::ShutdownProtobufLibrary();
}

