#ifndef TAGSTATS_HANDLER_HPP
#define TAGSTATS_HANDLER_HPP

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

#include <fstream>
#include <iostream>
#include <map>
#include <string>
#include <utility>

#include <google/sparse_hash_map>

#include <osmium/handler.hpp>
#include <osmium/util/memory.hpp>
#include <osmium/util/verbose_output.hpp>

#include "hash.hpp"
#include "sqlite.hpp"
#include "statistics_handler.hpp"
#include "string_store.hpp"

/**
 * Holds some counter for nodes, ways, and relations.
 */
struct Counter {
    uint32_t count[3];

    Counter() {
        count[0] = 0; // nodes
        count[1] = 0; // ways
        count[2] = 0; // relations
    }

    uint32_t nodes() const {
        return count[0];
    }
    uint32_t ways() const {
        return count[1];
    }
    uint32_t relations() const {
        return count[2];
    }
    uint32_t all() const {
        return count[0] + count[1] + count[2];
    }
};

typedef google::sparse_hash_map<const char *, Counter, djb2_hash, eqstr> value_hash_map_t;

typedef google::sparse_hash_map<osmium::user_id_type, uint32_t> user_hash_map_t;

typedef google::sparse_hash_map<const char *, Counter, djb2_hash, eqstr> combination_hash_map_t;

/**
 * A KeyStats object holds all statistics for an OSM tag key.
 */
class KeyStats {

public:

    Counter key;
    Counter values;
    Counter cells;

    combination_hash_map_t key_combination_hash;

    user_hash_map_t user_hash;

    value_hash_map_t values_hash;

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
        int type = osmium::item_type_to_nwr_index(object.type());

        key.count[type]++;

        value_hash_map_t::iterator values_iterator(values_hash.find(value));
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

typedef google::sparse_hash_map<const char *, KeyStats *, djb2_hash, eqstr> key_hash_map_t;

/**
 * A KeyValueStats object holds some statistics for an OSM tag (key/value pair).
 */
class KeyValueStats {

public:

    combination_hash_map_t m_key_value_combination_hash;

    KeyValueStats() : m_key_value_combination_hash() {
    }

    void add_key_combination(const char* other_key, osmium::item_type type) {
        m_key_value_combination_hash[other_key].count[osmium::item_type_to_nwr_index(type)]++;
    }

}; // class KeyValueStats

typedef google::sparse_hash_map<const char *, KeyValueStats *, djb2_hash, eqstr> key_value_hash_map_t;
typedef google::sparse_hash_map<std::pair<const char*, const char*>, GeoDistribution *, djb2_hash, eqstr> key_value_geodistribution_hash_map_t;

struct RelationRoleStats {
    uint32_t node;
    uint32_t way;
    uint32_t relation;
};

class RelationTypeStats {

public:

    uint64_t m_count;
    uint64_t m_node_members;
    uint64_t m_way_members;
    uint64_t m_relation_members;

    std::map<std::string, RelationRoleStats> m_role_counts;

    RelationTypeStats() :
        m_count(0),
        m_node_members(0),
        m_way_members(0),
        m_relation_members(0),
        m_role_counts() {
    }

    void add(const osmium::Relation& relation) {
        m_count++;

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

    time_t timer;

    key_hash_map_t tags_stat;

    key_value_hash_map_t m_key_value_stats;

    key_value_geodistribution_hash_map_t m_key_value_geodistribution;

    std::map<std::string, RelationTypeStats> m_relation_type_stats;

    time_t m_max_timestamp;

    // this must be much bigger than the largest string we want to store
    static const int string_store_size = 1024 * 1024 * 10;
    StringStore m_string_store;

    Sqlite::Database& m_database;

    void _timer_info(const char *msg);

    void _update_key_combination_hash(osmium::item_type type, osmium::TagList::const_iterator it1, osmium::TagList::const_iterator end);

    void _update_key_value_combination_hash2(osmium::item_type type, osmium::TagList::const_iterator it, osmium::TagList::const_iterator end, key_value_hash_map_t::iterator kvi1, std::string& key_value1);

    void _update_key_value_combination_hash(osmium::item_type type, osmium::TagList::const_iterator it, osmium::TagList::const_iterator end);

    void _print_and_clear_key_distribution_images(bool for_nodes);

    void _print_and_clear_tag_distribution_images(bool for_nodes);

    void _print_memory_usage();

    void collect_tag_stats(const osmium::OSMObject& object);

    StatisticsHandler statistics_handler;

    MapToInt<rough_position_type> m_map_to_int;

    storage_type m_storage;

    osmium::item_type m_last_type = osmium::item_type::node;

public:

    TagStatsHandler(Sqlite::Database& database, const std::string& selection_database_name, MapToInt<rough_position_type>& map_to_int, unsigned int min_tag_combination_count, osmium::util::VerboseOutput& vout);

    void node(const osmium::Node& node);

    void way(const osmium::Way& way);

    void relation(const osmium::Relation& relation);

    void before_ways();

    void before_relations();

    void init();

    void write_to_database();

}; // class TagStatsHandler

#endif // TAGSTATS_HANDLER_HPP
