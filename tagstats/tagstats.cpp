/*

  Copyright (C) 2012-2017 Jochen Topf <jochen@topf.org>.

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

#include <osmium/io/any_input.hpp>
#include <osmium/osm/entity_bits.hpp>
#include <osmium/util/verbose_output.hpp>
#include <osmium/visitor.hpp>

#include "statistics_handler.hpp"

#include "geodistribution.hpp"

GeoDistribution::geo_distribution_type GeoDistribution::c_distribution_all;
int GeoDistribution::c_width;
int GeoDistribution::c_height;

#include "tagstats_handler.hpp"

void print_help() {
    std::cout << "tagstats [OPTIONS] OSMFILE DATABASE\n\n" \
              << "This program is part of taginfo. It calculates statistics on OSM tags\n" \
              << "from OSMFILE and puts them into DATABASE (an SQLite database).\n" \
              << "\nOptions:\n" \
              << "  -H, --help                    Print this help message and exit\n" \
              << "  -i, --index=INDEX_TYPE        Set index type for location index\n" \
              << "  -I, --show-index-types        Show available index types for location index\n" \
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

int main(int argc, char* argv[]) {
    static struct option long_options[] = {
        {"help",                      no_argument,       0, 'H'},
        {"index",                     required_argument, 0, 'i'},
        {"show-index-types",          no_argument,       0, 'I'},
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

    std::string index_type_name = "SparseMmapArray";

    double top    =   90;
    double right  =  180;
    double bottom =  -90;
    double left   = -180;

    unsigned int width  = 360;
    unsigned int height = 180;

    while (true) {
        int c = getopt_long(argc, argv, "Hi:Im:s:t:r:b:l:w:h:", long_options, 0);
        if (c == -1) {
            break;
        }

        switch (c) {
            case 'H':
                print_help();
                std::exit(0);
            case 'i':
                index_type_name = optarg;
                break;
            case 'I':
                std::cout << "Available index types:\n";
                std::cout << "  DenseMemArray\n";
                std::cout << "  DenseMmapArray\n";
                std::cout << "  SparseMemArray\n";
                std::cout << "  SparseMmapArray\n";
                std::exit(0);
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
                std::exit(1);
        }
    }

    if (argc - optind != 2) {
        std::cerr << "Usage: " << argv[0] << " [OPTIONS] OSMFILE DATABASE" << std::endl;
        std::exit(1);
    }

    osmium::util::VerboseOutput vout{true};
    vout << "Starting tagstats...\n";

    GeoDistribution::set_dimensions(width, height);
    osmium::io::File input_file{argv[optind]};
    Sqlite::Database db{argv[optind+1], SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE};

    MapToInt map_to_int{left, bottom, right, top, width, height};

    const bool better_resolution = (width * height) >= (1 << 16);
    LocationIndex location_index{index_type_name, better_resolution};
    TagStatsHandler handler{db, selection_database_name, map_to_int, min_tag_combination_count, vout, location_index};

    osmium::io::Reader reader{input_file};
    osmium::apply(reader, handler);

    handler.write_to_database();
}

