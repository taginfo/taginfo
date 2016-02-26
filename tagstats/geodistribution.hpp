#ifndef TAGSTATS_GEODISTRIBUTION_HPP
#define TAGSTATS_GEODISTRIBUTION_HPP

/*

  Copyright (C) 2012-2016 Jochen Topf <jochen@topf.org>.

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

#include <limits>
#include <memory>
#include <stdexcept>
#include <vector>

#include <gd.h>

#include <osmium/index/map/dense_mem_array.hpp>
#include <osmium/index/map/dense_mmap_array.hpp>
#include <osmium/index/map/sparse_mem_array.hpp>
#include <osmium/index/map/sparse_mmap_array.hpp>
#include <osmium/osm/location.hpp>
#include <osmium/osm/types.hpp>

/**
 * Positions are stored in this type of integer for the distribution images.
 * TAGSTATS_GEODISTRIBUTION_INT must be set in Makefile, typically to uint16_t
 * or uint32_t (for higher resolution but needs twice as much memory).
 */
using rough_position_type = TAGSTATS_GEODISTRIBUTION_INT;

using storage_type = osmium::index::map::Map<osmium::unsigned_object_id_type, rough_position_type>;

#ifdef OSMIUM_HAS_INDEX_MAP_DENSE_MEM_ARRAY
    REGISTER_MAP(osmium::unsigned_object_id_type, rough_position_type, osmium::index::map::DenseMemArray, DenseMemArray)
#endif

#ifdef OSMIUM_HAS_INDEX_MAP_DENSE_MMAP_ARRAY
    REGISTER_MAP(osmium::unsigned_object_id_type, rough_position_type, osmium::index::map::DenseMmapArray, DenseMmapArray)
#endif

#ifdef OSMIUM_HAS_INDEX_MAP_SPARSE_MEM_ARRAY
    REGISTER_MAP(osmium::unsigned_object_id_type, rough_position_type, osmium::index::map::SparseMemArray, SparseMemArray)
#endif

#ifdef OSMIUM_HAS_INDEX_MAP_SPARSE_MMAP_ARRAY
    REGISTER_MAP(osmium::unsigned_object_id_type, rough_position_type, osmium::index::map::SparseMmapArray, SparseMmapArray)
#endif


/**
 * Functor class defining the call operator as a function that limits a
 * osmium::Location to a bounding box, reduces the resolution
 * of the coordinates and returns an integer.
 *
 * If the position is outside the bounding box, std::numeric_limits<T>::max()
 * is returned.
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
        if (size() >= std::numeric_limits<T>::max()) {
            throw std::range_error("width*height must be smaller than MAXINT for type T");
        }
    }

    T operator()(const osmium::Location& p) const {
        if (p.lon() < m_minx || p.lat() < m_miny || p.lon() >= m_maxx || p.lat() >= m_maxy) {
            // if the position is out of bounds we return MAXINT for type T
            return std::numeric_limits<T>::max();
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

    typedef std::vector<bool> geo_distribution_type;

    /**
     * Contains a pointer to a bitset that gives us the distribution.
     * If only one grid cell is used so far, this pointer is nullptr. Only
     * if more than one grid cell is used, we dynamically create an
     * object for this.
     */
    std::unique_ptr<geo_distribution_type> m_distribution = nullptr;

    /**
     * Number of set grid cells.
     */
    unsigned int m_cells = 0;

    /// If there is only one grid cell location, this is where its kept.
    rough_position_type m_location = 0;

    /// Overall distribution
    static geo_distribution_type c_distribution_all;

    static int c_width;
    static int c_height;

public:

    GeoDistribution() = default;

    void clear() {
        m_distribution.reset(nullptr);
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
    void add_coordinate(rough_position_type n) {
        if (n == std::numeric_limits<rough_position_type>::max()) {
            // ignore positions that are out of bounds
            return;
        }
        if (m_cells == 0) {
            m_location = n;
            m_cells++;
            c_distribution_all[n] = true;
        } else if (m_cells == 1 && m_location != n) {
            m_distribution.reset(new geo_distribution_type(c_width * c_height));
            m_distribution->operator[](m_location) = true;
            c_distribution_all[m_location] = true;
            m_distribution->operator[](n) = true;
            c_distribution_all[n] = true;
            m_cells++;
        } else if (m_cells == 1 && m_location == n) {
            // nothing to do
        } else if (! m_distribution->operator[](n)) {
            m_cells++;
            m_distribution->operator[](n) = true;
            c_distribution_all[n] = true;
        }
    }

    class Image {

        gdImagePtr m_image;
        int m_color;

    public:

        Image(int width, int height) :
            m_image(gdImageCreate(width, height)) {
            gdImageColorTransparent(m_image, gdImageColorAllocate(m_image, 0, 0, 0));
            m_color = gdImageColorAllocate(m_image, 180, 0, 0);
        }

        ~Image() {
            gdImageDestroy(m_image);
        }

        void set_pixel(int x, int y) {
            gdImageSetPixel(m_image, x, y, m_color);
        }

        gdImagePtr data() {
            return m_image;
        }

    }; // class Image

    class Png {

    public:

        int size;
        void* data;

        Png(Image& image) :
            size(0),
            data(gdImagePngPtr(image.data(), &size)) {
        }

        Png(const Png&) = delete;
        Png(Png&&) = default;

        Png& operator=(const Png&) = delete;
        Png& operator=(Png&&) = default;

        ~Png() {
            gdFree(data);
        }

    }; // class Png

    /**
     * Create PNG image.
     * You have to call free_png() to free the memory allocated for the
     * PNG image once you are done with it.
     *
     * @param size Pointer to integer thats set to the size of the created
     *        image.
     * @returns Pointer to memory area with PNG image.
     */
    Png create_png() {
        Image image(c_width, c_height);

        if (m_cells == 1) {
            int y = m_location / c_width;
            int x = m_location - (y * c_width);
            image.set_pixel(x, y);
        } else if (m_cells >= 2) {
            int n=0;
            for (int y=0; y < c_height; y++) {
                for (int x=0; x < c_width; x++) {
                    if (m_distribution->operator[](n)) {
                        image.set_pixel(x, y);
                    }
                    n++;
                }
            }
        }

        return Png(image);
    }

    static Png create_empty_png() {
        Image image(c_width, c_height);
        return Png(image);
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
