#ifndef TAGSTATS_GEODISTRIBUTION_HPP
#define TAGSTATS_GEODISTRIBUTION_HPP

#include <bitset>

#include <gd.h>

class GeoDistribution {

    static const int resolution_y = 360;
    static const int resolution_x = 2 * resolution_y;

    typedef std::bitset<resolution_x * resolution_y> geo_distribution_t;

    /**
     * Contains a pointer to a bitset that gives us the distribution.
     * If only one grid cell is used so far, this pointer is NULL. Only
     * if more than one grid cell is used, we dynamically create an
     * object for this.
     */
    geo_distribution_t *distribution;

    /**
     * Number of grid cells.
     * Will be 0 in the beginning, 1 if there is only one grid cell and
     * 2 if there are two or more.
     */
    int cells;

    /// If there is only one grid cell location, this is where its kept
    int location;

    /// Overall distribution
    static geo_distribution_t distribution_all;

public:

    GeoDistribution() : distribution(NULL), cells(0), location(-1) {
    }

    ~GeoDistribution() {
        delete distribution;
    }

    /**
     * Add the given coordinate to the distribution store.
     */
    void add_coordinate(double dx, double dy) {
        int x =                int(2 * (dx + 180));
        int y = resolution_y - int(2 * (dy +  90));

        if (x < 0) x=0;
        if (y < 0) y=0;
        if (x >= resolution_x) x = resolution_x-1;
        if (y >= resolution_y) y = resolution_y-1;

        int n = resolution_x * y + x;
        if (cells == 0) {
            location = n;
            cells++;
            distribution_all[n] = true;
        } else if (cells == 1) {
            if (location != n) {
                distribution = new geo_distribution_t;
                (*distribution)[location] = true;
                distribution_all[location] = true;
                (*distribution)[n] = true;
                distribution_all[n] = true;
                cells++;
            }
        } else {
            (*distribution)[n] = true;
            distribution_all[n] = true;
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
        gdImagePtr im = gdImageCreate(resolution_x, resolution_y);
        int bgColor = gdImageColorAllocate(im, 0, 0, 0);
        gdImageColorTransparent(im, bgColor);
        int fgColor = gdImageColorAllocate(im, 180, 0, 0);

        if (distribution) {
            int n=0;
            for (int y=0; y < resolution_y; y++) {
                for (int x=0; x < resolution_x; x++) {
                    if ((*distribution)[n]) {
                        cells++;
                        gdImageSetPixel(im, x, y, fgColor);
                    }
                    n++;
                }
            }
        } else {
            int y = location / resolution_x;
            int x = location - y;
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
        return distribution_all.count();
    }

    /**
     * Resets the distribution storage for the overall distribution.
     */
    static void reset() {
        distribution_all.reset();
    }
};

#endif // TAGSTATS_GEODISTRIBUTION_HPP
