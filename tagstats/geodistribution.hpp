#ifndef TAGSTATS_GEODISTRIBUTION_HPP
#define TAGSTATS_GEODISTRIBUTION_HPP

#include <stdexcept>
#include <limits>

#include <gd.h>

/**
 * Functor class defining the () operator as a function that limits a
 * Osmium::OSM::Position to a bounding box, reduces the resolution
 * of the coordinates and returns an integer.
 *
 * @tparam T Result type after conversion. Must be an unsigned integer type.
 */
template <typename T>
class MapToInt {

    double m_minx;
    double m_miny;
    double m_maxx;
    double m_maxy;

    unsigned int m_width;
    unsigned int m_height;

    double m_dx;
    double m_dy;

public:

    MapToInt(double minx = -180, double miny = -90, double maxx = 180, double maxy = 90, unsigned int width = 360, unsigned int height = 180) :
        m_minx(minx), m_miny(miny), m_maxx(maxx), m_maxy(maxy),
        m_width(width), m_height(height),
        m_dx(maxx - minx), m_dy(maxy - miny) {
        if (size() > std::numeric_limits<T>::max()) {
            throw std::range_error("width*height must be smaller than MAXINT for type T");
        }
    }

    T operator()(const Osmium::OSM::Position& p) const {
        if (p.lon() < m_minx || p.lat() < m_miny || p.lon() >= m_maxx || p.lat() >= m_maxy) {
            throw std::range_error("position out of bounds");
        }
        int x = (p.lon() - m_minx) / m_dx * m_width;
        int y = (m_maxy - p.lat()) / m_dy * m_height;

        if (x < 0) {
            x = 0;
        } else if (static_cast<unsigned int>(x) >= m_width) {
            x = m_width-1;
        }
        if (y < 0) {
            y = 0;
        } else if (static_cast<unsigned int>(y) >= m_height) {
            y = m_height-1;
        }

        return y * m_width + x;
    }

    unsigned int width() const {
        return m_width;
    }

    unsigned int height() const {
        return m_height;
    }

    unsigned int size() const {
        return m_width * m_height;
    }

};

/**
 * Stores the geographical distribution of something in a space efficient way.
 */
class GeoDistribution {

    typedef std::vector<bool> geo_distribution_t;

    /**
     * Contains a pointer to a bitset that gives us the distribution.
     * If only one grid cell is used so far, this pointer is NULL. Only
     * if more than one grid cell is used, we dynamically create an
     * object for this.
     */
    geo_distribution_t* m_distribution;

    /**
     * Number of set grid cells.
     */
    unsigned int m_cells;

    /// If there is only one grid cell location, this is where its kept.
    rough_position_t m_location;

    /// Overall distribution
    static geo_distribution_t c_distribution_all;

    static int c_width;
    static int c_height;

public:

    GeoDistribution() : m_distribution(NULL), m_cells(0), m_location(0) {
    }

    ~GeoDistribution() {
        delete m_distribution;
    }

    void clear() {
        delete m_distribution;
        m_distribution = NULL;
        m_cells = 0;
        m_location = 0;
    }

    static void set_dimensions(int width, int height) {
        c_width = width;
        c_height = height;
        c_distribution_all.resize(c_width * c_height);
    }

    /**
     * Add the given coordinate to the distribution store.
     */
    void add_coordinate(rough_position_t n) {
        if (m_cells == 0) {
            m_location = n;
            m_cells++;
            c_distribution_all[n] = true;
        } else if (m_cells == 1 && m_location != n) {
            m_distribution = new geo_distribution_t(c_width*c_height);
            (*m_distribution)[m_location] = true;
            c_distribution_all[m_location] = true;
            (*m_distribution)[n] = true;
            c_distribution_all[n] = true;
            m_cells++;
        } else if (m_cells == 1 && m_location == n) {
            // nothing to do
        } else if (! (*m_distribution)[n]) {
            m_cells++;
            (*m_distribution)[n] = true;
            c_distribution_all[n] = true;
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
    void* create_png(int* size) {
        gdImagePtr im = gdImageCreate(c_width, c_height);
        int bgColor = gdImageColorAllocate(im, 0, 0, 0);
        gdImageColorTransparent(im, bgColor);
        int fgColor = gdImageColorAllocate(im, 180, 0, 0);

        if (m_cells == 1) {
            int y = m_location / c_width;
            int x = m_location - (y * c_width);
            gdImageSetPixel(im, x, y, fgColor);
        } else if (m_cells >= 2) {
            int n=0;
            for (int y=0; y < c_height; y++) {
                for (int x=0; x < c_width; x++) {
                    if ((*m_distribution)[n]) {
                        gdImageSetPixel(im, x, y, fgColor);
                    }
                    n++;
                }
            }
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
     * Return the number of cells set.
     */
    unsigned int cells() const {
        return m_cells;
    }

    /**
     * Return the number of cells that are set in at least one GeoDistribution
     * object.
     */
    static unsigned int count_all_set_cells() {
        int c=0;
        for (int n=0; n < c_width*c_height; ++n) {
            if (c_distribution_all[n]) {
                c++;
            }
        }
        return c;
    }

};

#endif // TAGSTATS_GEODISTRIBUTION_HPP
