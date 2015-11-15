#ifndef TAGSTATS_HANDLER_HPP
#define TAGSTATS_HANDLER_HPP

/*

  Copyright (C) 2012-2015 Jochen Topf <jochen@topf.org>.

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
#include <boost/algorithm/string/split.hpp>
#include <boost/algorithm/string/classification.hpp>

#include "sqlite.hpp"
#include "string_store.hpp"

/**
 * Hash function used in google hash map that seems to work well with tag
 * key/value strings.
 */
struct djb2_hash {
    size_t operator()(const char *str) const {
        size_t hash = 5381;
        int c;

        while ((c = *str++)) {
            hash = ((hash << 5) + hash) + c; /* hash * 33 + c */
        }

        return hash;
    }

    size_t operator()(std::pair<const char *, const char*> p) const {
        std::string s = p.first;
        s += '=';
        s += p.second;
        return operator()(s.c_str());
    }
};

/**
 * String comparison used in google hash map.
 */
struct eqstr {
    bool operator()(const char* s1, const char* s2) const {
        return (s1 == s2) || (s1 && s2 && strcmp(s1, s2) == 0);
    }

    bool operator()(std::pair<const char*, const char*> p1, std::pair<const char*, const char*> p2) const {
        return operator()(p1.first, p2.first) && operator()(p1.second, p2.second);
    }
};

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

    void _timer_info(const char *msg) {
        int duration = time(0) - timer;
        std::cerr << "  " << msg << " took " << duration << " seconds (about " << duration / 60 << " minutes)\n\n";
    }

    void _update_key_combination_hash(osmium::item_type type, osmium::TagList::const_iterator it1, osmium::TagList::const_iterator end) {
        for (; it1 != end; ++it1) {
            const char* key1 = it1->key();
            key_hash_map_t::iterator tsi1(tags_stat.find(key1));
            for (auto it2 = std::next(it1); it2 != end; ++it2) {
                const char* key2 = it2->key();
                key_hash_map_t::iterator tsi2(tags_stat.find(key2));
                if (strcmp(key1, key2) < 0) {
                    tsi1->second->add_key_combination(tsi2->first, type);
                } else {
                    tsi2->second->add_key_combination(tsi1->first, type);
                }
            }
        }
    }

    void _update_key_value_combination_hash2(osmium::item_type type, osmium::TagList::const_iterator it, osmium::TagList::const_iterator end, key_value_hash_map_t::iterator kvi1, std::string& key_value1) {
        for (; it != end; ++it) {
            std::string key_value2(it->key());
            key_value_hash_map_t::iterator kvi2 = m_key_value_stats.find(key_value2.c_str());
            if (kvi2 != m_key_value_stats.end()) {
                if (key_value1 < key_value2) {
                    kvi1->second->add_key_combination(kvi2->first, type);
                } else {
                    kvi2->second->add_key_combination(kvi1->first, type);
                }
            }

            key_value2 += "=";
            key_value2 += it->value();

            kvi2 = m_key_value_stats.find(key_value2.c_str());
            if (kvi2 != m_key_value_stats.end()) {
                if (key_value1 < key_value2) {
                    kvi1->second->add_key_combination(kvi2->first, type);
                } else {
                    kvi2->second->add_key_combination(kvi1->first, type);
                }
            }
        }
    }

    void _update_key_value_combination_hash(osmium::item_type type, osmium::TagList::const_iterator it, osmium::TagList::const_iterator end) {
        for (; it != end; ++it) {
            std::string key_value1(it->key());
            key_value_hash_map_t::iterator kvi1 = m_key_value_stats.find(key_value1.c_str());
            if (kvi1 != m_key_value_stats.end()) {
                _update_key_value_combination_hash2(type, std::next(it), end, kvi1, key_value1);
            }

            key_value1 += "=";
            key_value1 += it->value();

            kvi1 = m_key_value_stats.find(key_value1.c_str());
            if (kvi1 != m_key_value_stats.end()) {
                _update_key_value_combination_hash2(type, std::next(it), end, kvi1, key_value1);
            }
        }
    }

    void _print_and_clear_key_distribution_images(bool for_nodes) {
        int sum_size=0;

        Sqlite::Statement statement_insert_into_key_distributions(m_database, "INSERT INTO key_distributions (key, object_type, png) VALUES (?, ?, ?);");
        m_database.begin_transaction();

        for (const auto& p : tags_stat) {
            KeyStats* stat = p.second;

            if (for_nodes) {
                stat->cells.count[0] = stat->distribution.cells();
            } else {
                stat->cells.count[1] = stat->distribution.cells();
            }

            auto png = stat->distribution.create_png();
            sum_size += png.size;

            statement_insert_into_key_distributions
            .bind_text(p.first)               // column: key
            .bind_text(for_nodes ? "n" : "w") // column: object_type
            .bind_blob(png.data, png.size)    // column: png
            .execute();

            stat->distribution.clear();
        }

        std::cerr << "gridcells_all: " << GeoDistribution::count_all_set_cells() << std::endl;
        std::cerr << "sum of key location image sizes: " << sum_size << " bytes\n";

        m_database.commit();
    }

    void _print_and_clear_tag_distribution_images(bool for_nodes) {
        int sum_size=0;

        Sqlite::Statement statement_insert_into_tag_distributions(m_database, "INSERT INTO tag_distributions (key, value, object_type, png) VALUES (?, ?, ?, ?);");
        m_database.begin_transaction();

        for (key_value_geodistribution_hash_map_t::const_iterator it = m_key_value_geodistribution.begin(); it != m_key_value_geodistribution.end(); ++it) {
            GeoDistribution* geo = it->second;

            auto png = geo->create_png();
            sum_size += png.size;

            statement_insert_into_tag_distributions
            .bind_text(it->first.first)       // column: key
            .bind_text(it->first.second)      // column: value
            .bind_text(for_nodes ? "n" : "w") // column: object_type
            .bind_blob(png.data, png.size)    // column: png
            .execute();

            if (for_nodes) {
                geo->clear();
            } else {
                delete geo;
            }
        }

        std::cerr << "sum of tag location image sizes: " << sum_size << " bytes\n";

        m_database.commit();
    }

    void _print_memory_usage() {
        std::cerr << "string_store: chunk_size=" << m_string_store.get_chunk_size() / 1024 / 1024 << "MB"
                  <<                  " chunks=" << m_string_store.get_chunk_count()
                  <<                  " memory=" << (m_string_store.get_chunk_size() / 1024 / 1024) * m_string_store.get_chunk_count() << "MB"
                  <<           " bytes_in_last=" << m_string_store.get_used_bytes_in_last_chunk() / 1024 << "kB"
                  << std::endl;

        char filename[100];
        sprintf(filename, "/proc/%d/status", getpid());
        std::ifstream status_file(filename);
        std::string line;

        if (status_file.is_open()) {
            while (! status_file.eof() ) {
                std::getline(status_file, line);
                if (line.substr(0, 6) == "VmPeak" || line.substr(0, 6) == "VmSize") {
                    std::cerr << line << std::endl;
                }
            }
            status_file.close();
        }

    }

    void collect_tag_stats(const osmium::OSMObject& object) {
        if (m_max_timestamp < object.timestamp()) {
            m_max_timestamp = object.timestamp();
        }

        if (object.tags().empty()) {
            return;
        }

        KeyStats* stat;
        for (const auto& tag : object.tags()) {
            const auto tags_iterator = tags_stat.find(tag.key());
            if (tags_iterator == tags_stat.end()) {
                stat = new KeyStats();
                tags_stat.insert(std::pair<const char *, KeyStats *>(m_string_store.add(tag.key()), stat));
            } else {
                stat = tags_iterator->second;
            }
            stat->update(tag.value(), object, m_string_store);

            std::pair<const char*, const char*> keyvalue = std::make_pair(tag.key(), tag.value());

            if (object.type() == osmium::item_type::node) {
                rough_position_type location = m_map_to_int(static_cast<const osmium::Node&>(object).location());
                stat->distribution.add_coordinate(location);
                key_value_geodistribution_hash_map_t::iterator gd_it = m_key_value_geodistribution.find(keyvalue);
                if (gd_it != m_key_value_geodistribution.end()) {
                    gd_it->second->add_coordinate(location);
                }
            }
            else if (object.type() == osmium::item_type::way) {
                const auto& wnl = static_cast<const osmium::Way&>(object).nodes();
                if (!wnl.empty()) {
                    key_value_geodistribution_hash_map_t::iterator gd_it = m_key_value_geodistribution.find(keyvalue);
                    for (const auto& wn : wnl) {
                        try {
                            rough_position_type location = m_storage.get(wn.positive_ref());
                            stat->distribution.add_coordinate(location);
                            if (gd_it != m_key_value_geodistribution.end()) {
                                gd_it->second->add_coordinate(location);
                            }
                        } catch (const osmium::not_found&) {
                            // node is missing for way: ignore
                        }
                    }
                }
            }
        }

        osmium::TagList::const_iterator begin = object.tags().begin();
        osmium::TagList::const_iterator end   = object.tags().end();
        _update_key_combination_hash(object.type(), begin, end);
        _update_key_value_combination_hash(object.type(), begin, end);
    }

    StatisticsHandler statistics_handler;

    MapToInt<rough_position_type> m_map_to_int;

    storage_type m_storage;

    osmium::item_type m_last_type = osmium::item_type::node;

public:

    TagStatsHandler(Sqlite::Database& database, const std::string& selection_database_name, MapToInt<rough_position_type>& map_to_int, unsigned int min_tag_combination_count) :
        Handler(),
        m_min_tag_combination_count(min_tag_combination_count),
        m_max_timestamp(0),
        m_string_store(string_store_size),
        m_database(database),
        statistics_handler(database),
        m_map_to_int(map_to_int),
        m_storage()
    {
        if (!selection_database_name.empty()) {
            Sqlite::Database sdb(selection_database_name.c_str(), SQLITE_OPEN_READONLY);

            {
                Sqlite::Statement select(sdb, "SELECT key FROM interesting_tags WHERE value IS NULL;");
                while (select.read()) {
                    std::string key_value = select.get_text(0);
                    m_key_value_stats[m_string_store.add(key_value.c_str())] = new KeyValueStats();
                }
            }
            {
                Sqlite::Statement select(sdb, "SELECT key || '=' || value FROM interesting_tags WHERE value IS NOT NULL;");
                while (select.read()) {
                    std::string key_value = select.get_text(0);
                    m_key_value_stats[m_string_store.add(key_value.c_str())] = new KeyValueStats();
                }
            }
            {
                Sqlite::Statement select(sdb, "SELECT key, value FROM frequent_tags;");
                while (select.read()) {
                    std::string key   = select.get_text(0);
                    std::string value = select.get_text(1);
                    m_key_value_geodistribution[std::make_pair(m_string_store.add(key.c_str()), m_string_store.add(value.c_str()))] = new GeoDistribution();
                }
            }
            {
                Sqlite::Statement select(sdb, "SELECT rtype FROM interesting_relation_types;");
                while (select.read()) {
                    std::string rtype = select.get_text(0);
                    m_relation_type_stats[rtype] = RelationTypeStats();
                }
            }
        }
    }

    void node(const osmium::Node& node) {
        statistics_handler.node(node);
        collect_tag_stats(node);
        m_storage.set(node.positive_id(), m_map_to_int(node.location()));
    }

    void way(const osmium::Way& way) {
        if (m_last_type != osmium::item_type::way) {
            before_ways();
            m_last_type = osmium::item_type::way;
        }

        statistics_handler.way(way);
        collect_tag_stats(way);
    }

    void relation(const osmium::Relation& relation) {
        if (m_last_type != osmium::item_type::relation) {
            before_relations();
            m_last_type = osmium::item_type::relation;
        }

        statistics_handler.relation(relation);
        collect_tag_stats(relation);

        const char* type = relation.tags().get_value_by_key("type");
        if (type) {
            auto it = m_relation_type_stats.find(type);
            if (it != m_relation_type_stats.end()) {
                it->second.add(relation);
            }
        }
    }

    void before_ways() {
        _timer_info("processing nodes");
        _print_memory_usage();

        auto png = GeoDistribution::create_empty_png();
        Sqlite::Statement statement_insert_into_key_distributions(m_database, "INSERT INTO key_distributions (png) VALUES (?);");
        m_database.begin_transaction();
        statement_insert_into_key_distributions
        .bind_blob(png.data, png.size) // column: png
        .execute();
        m_database.commit();

        _print_and_clear_key_distribution_images(true);
        _print_and_clear_tag_distribution_images(true);
        timer = time(0);
        _timer_info("dumping images");
        _print_memory_usage();

        std::cerr << "------------------------------------------------------------------------------\n";
        std::cerr << "Processing ways...\n";
        timer = time(0);
    }

    void before_relations() {
        _timer_info("processing ways");
        _print_and_clear_key_distribution_images(false);
        _print_and_clear_tag_distribution_images(false);
        _print_memory_usage();

        std::cerr << "------------------------------------------------------------------------------\n";
        std::cerr << "Processing relations...\n";
        timer = time(0);
    }

    void init() { // XXX
        std::cerr << "------------------------------------------------------------------------------\n";
        std::cerr << "Starting tagstats...\n\n";
        std::cerr << "Sizes of some important data structures:\n";
        std::cerr << "  sizeof(value_hash_map_t)           = " << sizeof(value_hash_map_t) << "\n";
        std::cerr << "  sizeof(Counter)                    = " << sizeof(Counter) << "\n";
        std::cerr << "  sizeof(key_combination_hash_map_t) = " << sizeof(combination_hash_map_t) << "\n";
        std::cerr << "  sizeof(user_hash_map_t)            = " << sizeof(user_hash_map_t) << "\n";
        std::cerr << "  sizeof(GeoDistribution)            = " << sizeof(GeoDistribution) << "\n";
        std::cerr << "  sizeof(KeyStats)                   = " << sizeof(KeyStats) << "\n\n";

        _print_memory_usage();

        std::cerr << "------------------------------------------------------------------------------\n";
        std::cerr << "Processing nodes...\n";
        timer = time(0);
    }

    void write_to_database() {
        _timer_info("processing relations");
        _print_memory_usage();

        std::cerr << "------------------------------------------------------------------------------\n";
        std::cerr << "Writing results to database...\n";
        timer = time(0);
        statistics_handler.write_to_database();

        Sqlite::Statement statement_insert_into_keys(m_database, "INSERT INTO keys (key, " \
                " count_all,  count_nodes,  count_ways,  count_relations, " \
                "values_all, values_nodes, values_ways, values_relations, " \
                " users_all, " \
                "cells_nodes, cells_ways) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);");

        Sqlite::Statement statement_insert_into_tags(m_database, "INSERT INTO tags (key, value, " \
                "count_all, count_nodes, count_ways, count_relations) " \
                "VALUES (?, ?, ?, ?, ?, ?);");

        Sqlite::Statement statement_insert_into_key_combinations(m_database, "INSERT INTO key_combinations (key1, key2, " \
                "count_all, count_nodes, count_ways, count_relations) " \
                "VALUES (?, ?, ?, ?, ?, ?);");

        Sqlite::Statement statement_insert_into_tag_combinations(m_database, "INSERT INTO tag_combinations (key1, value1, key2, value2, " \
                "count_all, count_nodes, count_ways, count_relations) " \
                "VALUES (?, ?, ?, ?, ?, ?, ?, ?);");

        Sqlite::Statement statement_insert_into_relation_types(m_database, "INSERT INTO relation_types (rtype, count, " \
                "members_all, members_nodes, members_ways, members_relations) " \
                "VALUES (?, ?, ?, ?, ?, ?);");

        Sqlite::Statement statement_insert_into_relation_roles(m_database, "INSERT INTO relation_roles (rtype, role, " \
                "count_all, count_nodes, count_ways, count_relations) " \
                "VALUES (?, ?, ?, ?, ?, ?);");

        Sqlite::Statement statement_update_meta(m_database, "UPDATE source SET data_until=?");

        m_database.begin_transaction();

        struct tm* tm = gmtime(&m_max_timestamp);
        static char max_timestamp_str[20]; // thats enough space for the timestamp generated from the pattern in the next line
        strftime(max_timestamp_str, sizeof(max_timestamp_str), "%Y-%m-%d %H:%M:%S", tm);
        statement_update_meta.bind_text(max_timestamp_str).execute();

        uint64_t tags_hash_size=tags_stat.size();
        uint64_t tags_hash_buckets=tags_stat.size()*2; //bucket_count();

        uint64_t values_hash_size=0;
        uint64_t values_hash_buckets=0;

        uint64_t key_combination_hash_size=0;
        uint64_t key_combination_hash_buckets=0;

        uint64_t user_hash_size=0;
        uint64_t user_hash_buckets=0;

        for (const auto& key_stat : tags_stat) {
            KeyStats *stat = key_stat.second;

            values_hash_size    += stat->values_hash.size();
            values_hash_buckets += stat->values_hash.bucket_count();

            for (const auto& value_stat : stat->values_hash) {
                statement_insert_into_tags
                .bind_text(key_stat.first)                   // column: key
                .bind_text(value_stat.first)                 // column: value
                .bind_int64(value_stat.second.all())         // column: count_all
                .bind_int64(value_stat.second.nodes())       // column: count_nodes
                .bind_int64(value_stat.second.ways())        // column: count_ways
                .bind_int64(value_stat.second.relations())   // column: count_relations
                .execute();
            }

            user_hash_size    += stat->user_hash.size();
            user_hash_buckets += stat->user_hash.bucket_count();

            statement_insert_into_keys
            .bind_text(key_stat.first)            // column: key
            .bind_int64(stat->key.all())          // column: count_all
            .bind_int64(stat->key.nodes())        // column: count_nodes
            .bind_int64(stat->key.ways())         // column: count_ways
            .bind_int64(stat->key.relations())    // column: count_relations
            .bind_int64(stat->values_hash.size()) // column: values_all
            .bind_int64(stat->values.nodes())     // column: values_nodes
            .bind_int64(stat->values.ways())      // column: values_ways
            .bind_int64(stat->values.relations()) // column: values_relations
            .bind_int64(stat->user_hash.size())   // column: users_all
            .bind_int64(stat->cells.nodes())      // column: cells_nodes
            .bind_int64(stat->cells.ways())       // column: cells_ways
            .execute();

            key_combination_hash_size    += stat->key_combination_hash.size();
            key_combination_hash_buckets += stat->key_combination_hash.bucket_count();

            for (const auto& key_combo_stat : stat->key_combination_hash) {
                statement_insert_into_key_combinations
                .bind_text(key_stat.first)         // column: key1
                .bind_text(key_combo_stat.first)   // column: key2
                .bind_int64(key_combo_stat.second.all())            // column: count_all
                .bind_int64(key_combo_stat.second.nodes())          // column: count_nodes
                .bind_int64(key_combo_stat.second.ways())           // column: count_ways
                .bind_int64(key_combo_stat.second.relations())      // column: count_relations
                .execute();
            }

            delete stat; // lets make valgrind happy
        }

        for (const auto& key_value_stat : m_key_value_stats) {
            KeyValueStats *stat = key_value_stat.second;

            std::vector<std::string> kv1;
            boost::split(kv1, key_value_stat.first, boost::is_any_of("="));
            kv1.push_back(""); // if there is no = in key, make sure there is an empty value

            for (const auto& key_value_combo_stat : stat->m_key_value_combination_hash) {
                if (key_value_combo_stat.second.all() >= m_min_tag_combination_count) {
                    std::vector<std::string> kv2;
                    boost::split(kv2, key_value_combo_stat.first, boost::is_any_of("="));
                    kv2.push_back(""); // if there is no = in key, make sure there is an empty value

                    statement_insert_into_tag_combinations
                    .bind_text(kv1[0])          // column: key1
                    .bind_text(kv1[1])          // column: value1
                    .bind_text(kv2[0])          // column: key2
                    .bind_text(kv2[1])          // column: value2
                    .bind_int64(key_value_combo_stat.second.all())       // column: count_all
                    .bind_int64(key_value_combo_stat.second.nodes())     // column: count_nodes
                    .bind_int64(key_value_combo_stat.second.ways())      // column: count_ways
                    .bind_int64(key_value_combo_stat.second.relations()) // column: count_relations
                    .execute();
                }
            }

            delete stat; // lets make valgrind happy
        }

        for (const auto& rtype_stats : m_relation_type_stats) {
            const RelationTypeStats& r = rtype_stats.second;
            statement_insert_into_relation_types
            .bind_text(rtype_stats.first)        // column: rtype
            .bind_int64(r.m_count)               // column: count
            .bind_int64(r.m_node_members + r.m_way_members + r.m_relation_members)  // column: members_all
            .bind_int64(r.m_node_members)        // columns: members_nodes
            .bind_int64(r.m_way_members)         // columns: members_ways
            .bind_int64(r.m_relation_members)    // columns: members_relations
            .execute();

            for (const auto& role_stats : r.m_role_counts) {
                const RelationRoleStats& rstats = role_stats.second;
                statement_insert_into_relation_roles
                .bind_text(rtype_stats.first)    // column: rtype
                .bind_text(role_stats.first)     // column: role
                .bind_int64(rstats.node + rstats.way + rstats.relation)  // column: count_all
                .bind_int64(rstats.node)         // column: count_nodes
                .bind_int64(rstats.way)          // column: count_ways
                .bind_int64(rstats.relation)     // column: count_relations
                .execute();
            }
        }

        m_database.commit();

        _timer_info("writing results to database");

        std::cerr << "hash map sizes:\n";
        std::cerr << "  tags:     size=" <<   tags_hash_size << " buckets=" <<   tags_hash_buckets << " sizeof(KeyStats)="  << sizeof(KeyStats)  << " *=" <<   tags_hash_size * sizeof(KeyStats) << "\n";
        std::cerr << "  values:   size=" << values_hash_size << " buckets=" << values_hash_buckets << " sizeof(Counter)=" << sizeof(Counter) << " *=" << values_hash_size * sizeof(Counter) << "\n";
        std::cerr << "  key combinations: size=" << key_combination_hash_size << " buckets=" << key_combination_hash_buckets << " sizeof(Counter)=" << sizeof(Counter) << " *=" << key_combination_hash_size * sizeof(Counter) << "\n";
        std::cerr << "  users:    size=" << user_hash_size << " buckets=" << user_hash_buckets << " sizeof(uint32_t)=" << sizeof(uint32_t) << " *=" << user_hash_size * sizeof(uint32_t) << "\n";

        std::cerr << "  sum: " <<
                  tags_hash_size * sizeof(KeyStats)
                  + values_hash_size * sizeof(Counter)
                  + key_combination_hash_size * sizeof(Counter)
                  + user_hash_size * sizeof(uint32_t)
                  << "\n";

        std::cerr << "\n" << "total memory for hashes:" << "\n";
        std::cerr << "  (sizeof(hash key) + sizeof(hash value *) + 2.5 bit overhead) * bucket_count + sizeof(hash value) * size\n";
        std::cerr << " tags:             " << ((sizeof(const char*)*8 + sizeof(KeyStats *)*8 + 3) * tags_hash_buckets / 8 ) + sizeof(KeyStats) * tags_hash_size << "\n";
        std::cerr << "  (sizeof(hash key) + sizeof(hash value  ) + 2.5 bit overhead) * bucket_count\n";
        std::cerr << " values:           " << ((sizeof(const char*)*8 + sizeof(Counter)*8 + 3) * values_hash_buckets / 8 ) << "\n";
        std::cerr << " key combinations: " << ((sizeof(const char*)*8 + sizeof(Counter)*8 + 3) * key_combination_hash_buckets / 8 ) << "\n";

        std::cerr << " users:    " << ((sizeof(osmium::user_id_type)*8 + sizeof(uint32_t)*8 + 3) * user_hash_buckets / 8 )  << "\n";

        std::cerr << std::endl;

        _print_memory_usage();

        std::cerr << "------------------------------------------------------------------------------\n";
    }

}; // class TagStatsHandler

#endif // TAGSTATS_HANDLER_HPP
