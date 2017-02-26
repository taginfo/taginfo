#ifndef TAGSTATS_HANDLER_HPP
#define TAGSTATS_HANDLER_HPP

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

#include <cassert>
#include <fstream>
#include <iostream>
#include <map>
#include <string>
#include <unordered_map>
#include <utility>

#include <google/sparse_hash_map>

#include <osmium/handler.hpp>
#include <osmium/index/map/dense_mem_array.hpp>
#include <osmium/index/map/dense_mmap_array.hpp>
#include <osmium/index/map/sparse_mem_array.hpp>
#include <osmium/index/map/sparse_mmap_array.hpp>
#include <osmium/util/memory.hpp>
#include <osmium/util/verbose_output.hpp>

#include "geodistribution.hpp"
#include "hash.hpp"
#include "sqlite.hpp"
#include "statistics_handler.hpp"
#include "string_store.hpp"

/**
 * Stores the location of nodes. Lookup is by node ID.
 *
 * Locations are stored with reduced resolution, either in 16 bit or 32 bit.
 * The bool better_resolution on the constructor decides which is used.
 */
class LocationIndex {

    template <typename T>
    using map_type = osmium::index::map::Map<osmium::unsigned_object_id_type, T>;

    std::unique_ptr<map_type<uint16_t>> m_location_index_16bit{nullptr};
    std::unique_ptr<map_type<uint32_t>> m_location_index_32bit{nullptr};

    template <typename T>
    static std::unique_ptr<map_type<T>> create_map(const std::string& location_index_type) {
        osmium::index::register_map<osmium::unsigned_object_id_type, T, osmium::index::map::DenseMemArray>("DenseMemArray");
        osmium::index::register_map<osmium::unsigned_object_id_type, T, osmium::index::map::DenseMmapArray>("DenseMmapArray");
        osmium::index::register_map<osmium::unsigned_object_id_type, T, osmium::index::map::SparseMemArray>("SparseMemArray");
        osmium::index::register_map<osmium::unsigned_object_id_type, T, osmium::index::map::SparseMmapArray>("SparseMmapArray");
        const auto& map_factory = osmium::index::MapFactory<osmium::unsigned_object_id_type, T>::instance();
        return map_factory.create_map(location_index_type);
    }

public:

    LocationIndex(const std::string& index_type_name, bool better_resolution) {
        if (better_resolution) {
            m_location_index_32bit = std::move(create_map<uint32_t>(index_type_name));
        } else {
            m_location_index_16bit = std::move(create_map<uint16_t>(index_type_name));
        }
    }

    void set(osmium::unsigned_object_id_type id, uint32_t value) {
        if (value == std::numeric_limits<uint32_t>::max()) {
            return;
        }
        if (m_location_index_16bit) {
            assert(value <= std::numeric_limits<uint16_t>::max());
            m_location_index_16bit->set(id, uint16_t(value));
        } else {
            m_location_index_32bit->set(id, value);
        }
    }

    uint32_t get(osmium::unsigned_object_id_type id) const {
        return m_location_index_16bit ? uint32_t(m_location_index_16bit->get(id))
                                      : m_location_index_32bit->get(id);
    }

    size_t size() const noexcept {
        return m_location_index_16bit ? m_location_index_16bit->size()
                                      : m_location_index_32bit->size();
    }

    size_t used_memory() const noexcept {
        return m_location_index_16bit ? m_location_index_16bit->used_memory()
                                      : m_location_index_32bit->used_memory();
    }

}; // class LocationIndex


/**
 * Holds some counter for nodes, ways, and relations.
 */
struct Counter {
    uint32_t count[3];

    Counter() noexcept {
        count[0] = 0; // nodes
        count[1] = 0; // ways
        count[2] = 0; // relations
    }

    uint32_t nodes() const noexcept {
        return count[0];
    }

    uint32_t ways() const noexcept {
        return count[1];
    }

    uint32_t relations() const noexcept {
        return count[2];
    }

    uint32_t all() const noexcept {
        return count[0] + count[1] + count[2];
    }

}; // struct Counter

using value_hash_map_type = google::sparse_hash_map<const char*, Counter, djb2_hash, eqstr>;

using user_hash_map_type = google::sparse_hash_map<osmium::user_id_type, uint32_t>;

using combination_hash_map_type = google::sparse_hash_map<const char*, Counter, djb2_hash, eqstr>;

/**
 * A KeyStats object holds all statistics for an OSM tag key.
 */
class KeyStats {

public:

    Counter key;
    Counter values;
    Counter cells;

    combination_hash_map_type key_combination_hash;

    user_hash_map_type user_hash;

    value_hash_map_type values_hash;

    GeoDistribution distribution;

    KeyStats()
        : key(),
          values(),
          cells(),
          key_combination_hash(),
          user_hash(),
          values_hash(),
          distribution() {
    }

    void update(const char* value, const osmium::OSMObject& object, StringStore& string_store) {
        const int type = osmium::item_type_to_nwr_index(object.type());

        key.count[type]++;

        const auto values_iterator = values_hash.find(value);
        if (values_iterator == values_hash.end()) {
            Counter counter;
            counter.count[type] = 1;
            values_hash.insert(std::pair<const char*, Counter>(string_store.add(value), counter));
            values.count[type]++;
        } else {
            values_iterator->second.count[type]++;
            if (values_iterator->second.count[type] == 1) {
                values.count[type]++;
            }
        }

        user_hash[object.uid()]++;
    }

    void add_key_combination(const char* other_key, osmium::item_type type) {
        key_combination_hash[other_key].count[osmium::item_type_to_nwr_index(type)]++;
    }

}; // class KeyStats

using key_hash_map_type = std::unordered_map<const char*, KeyStats, djb2_hash, eqstr>;

/**
 * A KeyValueStats object holds some statistics for an OSM tag (key/value pair).
 */
class KeyValueStats {

public:

    combination_hash_map_type m_key_value_combination_hash;

    KeyValueStats() : m_key_value_combination_hash() {
    }

    void add_key_combination(const char* other_key, osmium::item_type type) {
        m_key_value_combination_hash[other_key].count[osmium::item_type_to_nwr_index(type)]++;
    }

}; // class KeyValueStats

using key_value_hash_map_type = std::unordered_map<const char*, KeyValueStats, djb2_hash, eqstr>;
using key_value_geodistribution_hash_map_type = std::unordered_map<std::pair<const char*, const char*>, GeoDistribution, djb2_hash, eqstr>;

struct RelationRoleStats {
    uint32_t node;
    uint32_t way;
    uint32_t relation;
};

class RelationTypeStats {

public:

    uint64_t m_count = 0;
    uint64_t m_node_members = 0;
    uint64_t m_way_members = 0;
    uint64_t m_relation_members = 0;

    std::map<std::string, RelationRoleStats> m_role_counts;

    RelationTypeStats() = default;

    void add(const osmium::Relation& relation) {
        ++m_count;

        for (const auto& member : relation.members()) {
            RelationRoleStats& r = m_role_counts[member.role()];
            switch (member.type()) {
                case osmium::item_type::node:
                    ++r.node;
                    ++m_node_members;
                    break;
                case osmium::item_type::way:
                    ++r.way;
                    ++m_way_members;
                    break;
                case osmium::item_type::relation:
                    ++r.relation;
                    ++m_relation_members;
                    break;
                default:
                    break;
            }
        }
    }

}; // class RelationTypeStats


/**
 * Osmium handler that creates statistics for Taginfo.
 */
class TagStatsHandler : public osmium::handler::Handler {

    osmium::util::VerboseOutput& m_vout;

    /**
     * Tag combination not appearing at least this often are not written
     * to database.
     */
    unsigned int m_min_tag_combination_count;

    time_t m_timer;

    key_hash_map_type m_tags_stat;

    key_value_hash_map_type m_key_value_stats;

    key_value_geodistribution_hash_map_type m_key_value_geodistribution;

    std::map<std::string, RelationTypeStats> m_relation_type_stats;

    time_t m_max_timestamp;

    // this must be much bigger than the largest string we want to store
    static const int string_store_size = 1024 * 1024 * 10;
    StringStore m_string_store;

    Sqlite::Database& m_database;

    StatisticsHandler m_statistics_handler;

    MapToInt& m_map_to_int;

    LocationIndex& m_location_index;

    osmium::item_type m_last_type;

    void timer_info(const char* msg);

    void update_key_combination_hash(osmium::item_type type,
                                      osmium::TagList::const_iterator it1,
                                      osmium::TagList::const_iterator end);

    void update_key_value_combination_hash2(osmium::item_type type,
                                             osmium::TagList::const_iterator it,
                                             osmium::TagList::const_iterator end,
                                             key_value_hash_map_type::iterator kvi1,
                                             const std::string& key_value1);

    void update_key_value_combination_hash(osmium::item_type type,
                                            osmium::TagList::const_iterator it,
                                            osmium::TagList::const_iterator end);

    void print_and_clear_key_distribution_images(bool for_nodes);

    void print_and_clear_tag_distribution_images(bool for_nodes);

    void print_actual_memory_usage();

    KeyStats& get_stat(const char* key);
    void collect_tag_stats(const osmium::OSMObject& object);

public:

    TagStatsHandler(Sqlite::Database& database,
                    const std::string& selection_database_name,
                    MapToInt& map_to_int,
                    unsigned int min_tag_combination_count,
                    osmium::util::VerboseOutput& vout,
                    LocationIndex& location_index);

    void node(const osmium::Node& node);

    void way(const osmium::Way& way);

    void relation(const osmium::Relation& relation);

    void before_ways();

    void before_relations();

    void write_to_database();

}; // class TagStatsHandler

#endif // TAGSTATS_HANDLER_HPP
