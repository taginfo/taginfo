
/*

Copyright 2011 Jochen Topf <jochen@topf.org> and others (see README).

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

#include <getopt.h>

#include <osmium.hpp>

#include "statistics_handler.hpp"

/**
 * Positions are stored in this type of integer for the distribution images.
 * TAGSTATS_GEODISTRIBUTION_INT must be set in Makefile, typically to uint16_t
 * or uint32_t (for higher resolution but needs twice as much memory).
 */
typedef TAGSTATS_GEODISTRIBUTION_INT rough_position_t;

#ifdef TAGSTATS_GEODISTRIBUTION_FOR_WAYS
# include <osmium/storage/byid.hpp>
// Set TAGSTATS_GEODISTRIBUTION_STORAGE to SparseTable or Mmap in Makefile
typedef Osmium::Storage::TAGSTATS_GEODISTRIBUTION_FOR_WAYS<rough_position_t> storage_t;
#endif // TAGSTATS_GEODISTRIBUTION_FOR_WAYS

#include "geodistribution.hpp"

GeoDistribution::geo_distribution_t GeoDistribution::c_distribution_all;
int GeoDistribution::c_width;
int GeoDistribution::c_height;

#include "tagstats_handler.hpp"


/* ================================================== */

void print_help() {
    std::cout << "tagstats [OPTIONS] OSMFILE DATABASE\n\n" \
              << "This program is part of Taginfo. It calculates statistics\n" \
              << "on OSM tags and puts them into taginfo-db.db and count.db.\n" \
              << "\nOptions:\n" \
              << "  -H, --help           This help message\n" \
              << "  -d, --debug          Enable debugging output\n" \
              << "  -t, --top=NUMBER     Top of bounding box for distribution images\n" \
              << "  -r, --right=NUMBER   Right of bounding box for distribution images\n" \
              << "  -b, --bottom=NUMBER  Bottom of bounding box for distribution images\n" \
              << "  -l, --left=NUMBER    Left of bounding box for distribution images\n" \
              << "  -w, --width=NUMBER   Width of distribution images (default: 360)\n" \
              << "  -h, --height=NUMBER  Height of distribution images (default: 180)\n" \
              << "\nDefault for bounding box is: (-180, -90, 180, 90)\n";
}

int main(int argc, char *argv[]) {
    static struct option long_options[] = {
        {"debug",  no_argument, 0, 'd'},
        {"help",   no_argument, 0, 'H'},
        {"top",    required_argument, 0, 't'},
        {"right",  required_argument, 0, 'r'},
        {"bottom", required_argument, 0, 'b'},
        {"left",   required_argument, 0, 'l'},
        {"width",  required_argument, 0, 'w'},
        {"height", required_argument, 0, 'h'},
        {0, 0, 0, 0}
    };

    bool debug = false;

    double top    =   90;
    double right  =  180;
    double bottom =  -90;
    double left   = -180;

    unsigned int width  = 360;
    unsigned int height = 180;

    while (true) {
        int c = getopt_long(argc, argv, "dHt:r:b:l:w:h:", long_options, 0);
        if (c == -1) {
            break;
        }

        switch (c) {
            case 'd':
                debug = true;
                break;
            case 'H':
                print_help();
                exit(0);
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

    Osmium::init(debug);

    if (argc - optind != 2) {
        std::cerr << "Usage: " << argv[0] << " [OPTIONS] OSMFILE DATABASE" << std::endl;
        exit(1);
    }

    GeoDistribution::set_dimensions(width, height);
    Osmium::OSMFile infile(argv[optind]);
    Osmium::Sqlite::Database db(argv[optind+1]);
    MapToInt<rough_position_t> map_to_int(left, bottom, right, top, width, height);
    TagStatsHandler handler(db, map_to_int);
    infile.read(handler);
}

