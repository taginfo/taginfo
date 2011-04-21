#ifndef TAGSTATS_GEODISTRIBUTION_HPP
#define TAGSTATS_GEODISTRIBUTION_HPP

#include <bitset>

#include <gd.h>

class GeoDistribution {

public:

    static const int resolution_y = 360;
    static const int resolution_x = 2 * resolution_y;

    static const int image_size_y = resolution_y;
    static const int image_size_x = resolution_x;

private:

    std::bitset<resolution_x * resolution_y> *location;

    int cells;
    int loc;

    static std::bitset<resolution_x * resolution_y> location_all;

public:

    GeoDistribution() : location(NULL), cells(0), loc(-1) {
    }

    ~GeoDistribution() {
        delete location;
    }

    /**
     * Add the given coordinate to the distribution store.
     */
    void add_coordinate(double dx, double dy) {
        int x =                int(2 * (dx + 180));
        int y = resolution_y - int(2 * (dy +  90));
        int n = resolution_x * y + x;
        if (cells == 0) {
            loc = n;
            cells++;
            location_all[n] = true;
        } else if (cells == 1) {
            if (loc != n) {
                location = new std::bitset<resolution_x * resolution_y>;
                (*location)[loc] = true;
                location_all[loc] = true;
                (*location)[n] = true;
                cells++;
            }
        } else {
            (*location)[n] = true;
            location_all[n] = true;
        }
    }

    /**
     * Create PNG image.
     * You have to call free_png() to free the memory allocated for the
     * PNG image once you are done with it.
     *
     * @param size Pointer to integer thats set to the size of the created
     *        image.
     * @returns Pointer to memory area with PNG image.
     */
    void *create_png(int *size) {
        gdImagePtr im = gdImageCreate(image_size_x, image_size_y);
        int bgColor = gdImageColorAllocate(im, 0, 0, 0);
        gdImageColorTransparent(im, bgColor);
        int fgColor = gdImageColorAllocate(im, 180, 0, 0);

        if (location) {
            int n=0;
            for (int y=0; y < resolution_y; y++) {
                for (int x=0; x < resolution_x; x++) {
                    if ((*location)[n]) {
                        cells++;
                        gdImageSetPixel(im, x, y, fgColor);
                    }
                    n++;
                }
            }
        } else {
            int y = loc / resolution_x;
            int x = loc - y;
            gdImageSetPixel(im, x, y, fgColor);
        }

        void *png = gdImagePngPtr(im, size);
        gdImageDestroy(im);

        return png;
    }

    /**
     * Call this to free the pointer returned by create_png().
     */
    void free_png(void *png) {
        gdFree(png);
    }

    /**
     * Return the number of cells set. This is only valid after a call to create_png().
     */
    int get_cells() const {
        return cells;
    }

    /**
     * Return the number of cells that are set in at least one GeoDistribution
     * object.
     */
    static int count_all_set_cells() {
        return location_all.count();
    }

};

#endif // TAGSTATS_GEODISTRIBUTION_HPP
