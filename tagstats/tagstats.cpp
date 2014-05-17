/*

  Copyright 2012-2014 Jochen Topf <jochen@topf.org>.

  This file is part of Tagstats.

  Tagstats is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  Tagstats is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with Tagstats.  If not, see <http://www.gnu.org/licenses/>.

*/

#include <getopt.h>

#define OSMIUM_WITH_PBF_INPUT
#define OSMIUM_WITH_XML_INPUT

#include <osmium.hpp>

#include "statistics_handler.hpp"

/**
 * Positions are stored in this type of integer for the distribution images.
 * TAGSTATS_GEODISTRIBUTION_INT must be set in Makefile, typically to uint16_t
 * or uint32_t (for higher resolution but needs twice as much memory).
 */
typedef TAGSTATS_GEODISTRIBUTION_INT rough_position_t;

// Set BYID in Makefile to SparseTable, MmapFile, or MmapAnon
#include TAGSTATS_GEODISTRIBUTION_INCLUDE
typedef Osmium::Storage::ById::TAGSTATS_GEODISTRIBUTION_FOR_WAYS<rough_position_t> storage_t;

#include "geodistribution.hpp"

GeoDistribution::geo_distribution_t GeoDistribution::c_distribution_all;
int GeoDistribution::c_width;
int GeoDistribution::c_height;

#include "tagstats_handler.hpp"

void print_help() {
    std::cout << "tagstats [OPTIONS] OSMFILE DATABASE\n\n" \
              << "This program is part of taginfo. It calculates statistics on OSM tags\n" \
              << "from OSMFILE and puts them into DATABASE (an SQLite database).\n" \
              << "\nOptions:\n" \
              << "  -H, --help                    Print this help message and exit\n" \
              << "  -m, --min-tag-combination-count=N  Tag combinations not appearing this often\n" \
              << "                                     are not written to database\n" \
              << "  -s, --selection-db=DATABASE   Name of selection database\n" \
              << "  -t, --top=NUMBER              Top of bounding box for distribution images\n" \
              << "  -r, --right=NUMBER            Right of bounding box for distribution images\n" \
              << "  -b, --bottom=NUMBER           Bottom of bounding box for distribution images\n" \
              << "  -l, --left=NUMBER             Left of bounding box for distribution images\n" \
              << "  -w, --width=NUMBER            Width of distribution images (default: 360)\n" \
              << "  -h, --height=NUMBER           Height of distribution images (default: 180)\n" \
              << "\nDefault for bounding box is: (-180, -90, 180, 90).\n";
}

int main(int argc, char *argv[]) {
    static struct option long_options[] = {
        {"help",                      no_argument,       0, 'H'},
        {"min-tag-combination-count", required_argument, 0, 'm'},
        {"selection-db",              required_argument, 0, 's'},
        {"top",                       required_argument, 0, 't'},
        {"right",                     required_argument, 0, 'r'},
        {"bottom",                    required_argument, 0, 'b'},
        {"left",                      required_argument, 0, 'l'},
        {"width",                     required_argument, 0, 'w'},
        {"height",                    required_argument, 0, 'h'},
        {0, 0, 0, 0}
    };

    unsigned int min_tag_combination_count = 1000;

    std::string selection_database_name;

    double top    =   90;
    double right  =  180;
    double bottom =  -90;
    double left   = -180;

    unsigned int width  = 360;
    unsigned int height = 180;

    while (true) {
        int c = getopt_long(argc, argv, "Hm:s:t:r:b:l:w:h:", long_options, 0);
        if (c == -1) {
            break;
        }

        switch (c) {
            case 'H':
                print_help();
                exit(0);
            case 's':
                selection_database_name = optarg;
                break;
            case 'm':
                min_tag_combination_count = atoi(optarg);
                break;
            case 't':
                top = atof(optarg);
                break;
            case 'r':
                right = atof(optarg);
                break;
            case 'b':
                bottom = atof(optarg);
                break;
            case 'l':
                left = atof(optarg);
                break;
            case 'w':
                width = atoi(optarg);
                break;
            case 'h':
                height = atoi(optarg);
                break;
            default:
                exit(1);
        }
    }

    if (argc - optind != 2) {
        std::cerr << "Usage: " << argv[0] << " [OPTIONS] OSMFILE DATABASE" << std::endl;
        exit(1);
    }

    GeoDistribution::set_dimensions(width, height);
    Osmium::OSMFile infile(argv[optind]);
    Sqlite::Database db(argv[optind+1], SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE);
    MapToInt<rough_position_t> map_to_int(left, bottom, right, top, width, height);
    TagStatsHandler handler(db, selection_database_name, map_to_int, min_tag_combination_count);
    Osmium::Input::read(infile, handler);

    google::protobuf::ShutdownProtobufLibrary();
}

