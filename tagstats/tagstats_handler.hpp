#ifndef TAGSTATS_HANDLER_HPP
#define TAGSTATS_HANDLER_HPP

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

#include <string>
#include <fstream>
#include <iostream>
#include <map>
#include <utility>

#include <google/sparse_hash_map>
#include <boost/foreach.hpp>
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
        count[NODE]     = 0; // nodes
        count[WAY]      = 0; // ways
        count[RELATION] = 0; // relations
    }

    uint32_t nodes() const {
        return count[NODE];
    }
    uint32_t ways() const {
        return count[WAY];
    }
    uint32_t relations() const {
        return count[RELATION];
    }
    uint32_t all() const {
        return count[NODE] + count[WAY] + count[RELATION];
    }
};

typedef google::sparse_hash_map<const char *, Counter, djb2_hash, eqstr> value_hash_map_t;

typedef google::sparse_hash_map<osm_user_id_t, uint32_t> user_hash_map_t;

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

    void update(const char* value, const Osmium::OSM::Object& object, StringStore& string_store) {
        key.count[object.type()]++;

        value_hash_map_t::iterator values_iterator(values_hash.find(value));
        if (values_iterator == values_hash.end()) {
            Counter counter;
            counter.count[object.type()] = 1;
            values_hash.insert(std::pair<const char*, Counter>(string_store.add(value), counter));
            values.count[object.type()]++;
        } else {
            values_iterator->second.count[object.type()]++;
            if (values_iterator->second.count[object.type()] == 1) {
                values.count[object.type()]++;
            }
        }

        user_hash[object.uid()]++;
    }

    void add_key_combination(const char* other_key, osm_object_type_t type) {
        key_combination_hash[other_key].count[type]++;
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

    void add_key_combination(const char* other_key, osm_object_type_t type) {
        m_key_value_combination_hash[other_key].count[type]++;
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

    void add(const Osmium::OSM::Relation& relation) {
        m_count++;

        BOOST_FOREACH(const Osmium::OSM::RelationMember& member, relation.members()) {
            RelationRoleStats& r = m_role_counts[member.role()];
            switch (member.type()) {
                case 'n':
                    ++r.node;
                    ++m_node_members;
                    break;
                case 'w':
                    ++r.way;
                    ++m_way_members;
                    break;
                case 'r':
                    ++r.relation;
                    ++m_relation_members;
                    break;
            }
        }
    }

}; // class RelationTypeStats

typedef std::map<std::string, RelationTypeStats> relation_type_stats_map_t;

/**
 * Osmium handler that creates statistics for Taginfo.
 */
class TagStatsHandler : public Osmium::Handler::Base {

    /**
     * Tag combination not appearing at least this often are not written
     * to database.
     */
    unsigned int m_min_tag_combination_count;

    time_t timer;

    key_hash_map_t tags_stat;

    key_value_hash_map_t m_key_value_stats;

    key_value_geodistribution_hash_map_t m_key_value_geodistribution;

    relation_type_stats_map_t m_relation_type_stats;

    time_t m_max_timestamp;

    // this must be much bigger than the largest string we want to store
    static const int string_store_size = 1024 * 1024 * 10;
    StringStore m_string_store;

    Sqlite::Database& m_database;

    void _timer_info(const char *msg) {
        int duration = time(0) - timer;
        std::cerr << msg << " took " << duration << " seconds (about " << duration / 60 << " minutes)" << std::endl;
    }

    void _update_key_combination_hash(const Osmium::OSM::Object& object) {
        for (Osmium::OSM::TagList::const_iterator it1 = object.tags().begin(); it1 != object.tags().end(); ++it1) {
            const char* key1 = it1->key();
            key_hash_map_t::iterator tsi1(tags_stat.find(key1));
            for (Osmium::OSM::TagList::const_iterator it2 = it1+1; it2 != object.tags().end(); ++it2) {
                const char* key2 = it2->key();
                key_hash_map_t::iterator tsi2(tags_stat.find(key2));
                if (strcmp(key1, key2) < 0) {
                    tsi1->second->add_key_combination(tsi2->first, object.type());
                } else {
                    tsi2->second->add_key_combination(tsi1->first, object.type());
                }
            }
        }
    }

    void _update_key_value_combination_hash2(const Osmium::OSM::Object& object, Osmium::OSM::TagList::const_iterator it, key_value_hash_map_t::iterator kvi1, std::string& key_value1) {
        for (; it != object.tags().end(); ++it) {
            std::string key_value2(it->key());
            key_value_hash_map_t::iterator kvi2 = m_key_value_stats.find(key_value2.c_str());
            if (kvi2 != m_key_value_stats.end()) {
                if (key_value1 < key_value2) {
                    kvi1->second->add_key_combination(kvi2->first, object.type());
                } else {
                    kvi2->second->add_key_combination(kvi1->first, object.type());
                }
            }

            key_value2 += "=";
            key_value2 += it->value();

            kvi2 = m_key_value_stats.find(key_value2.c_str());
            if (kvi2 != m_key_value_stats.end()) {
                if (key_value1 < key_value2) {
                    kvi1->second->add_key_combination(kvi2->first, object.type());
                } else {
                    kvi2->second->add_key_combination(kvi1->first, object.type());
                }
            }
        }
    }

    void _update_key_value_combination_hash(const Osmium::OSM::Object& object) {
        for (Osmium::OSM::TagList::const_iterator it = object.tags().begin(); it != object.tags().end(); ++it) {
            std::string key_value1(it->key());
            key_value_hash_map_t::iterator kvi1 = m_key_value_stats.find(key_value1.c_str());
            if (kvi1 != m_key_value_stats.end()) {
                _update_key_value_combination_hash2(object, it+1, kvi1, key_value1);
            }

            key_value1 += "=";
            key_value1 += it->value();

            kvi1 = m_key_value_stats.find(key_value1.c_str());
            if (kvi1 != m_key_value_stats.end()) {
                _update_key_value_combination_hash2(object, it+1, kvi1, key_value1);
            }
        }
    }

    void _print_and_clear_key_distribution_images(bool for_nodes) {
        int sum_size=0;

        Sqlite::Statement statement_insert_into_key_distributions(m_database, "INSERT INTO key_distributions (key, object_type, png) VALUES (?, ?, ?);");
        m_database.begin_transaction();

        for (key_hash_map_t::const_iterator it = tags_stat.begin(); it != tags_stat.end(); it++) {
            KeyStats* stat = it->second;

            if (for_nodes) {
                stat->cells.count[NODE] = stat->distribution.cells();
            } else {
                stat->cells.count[WAY] = stat->distribution.cells();
            }

            int size;
            void* ptr = stat->distribution.create_png(&size);
            sum_size += size;

            statement_insert_into_key_distributions
            .bind_text(it->first)             // column: key
            .bind_text(for_nodes ? "n" : "w") // column: object_type
            .bind_blob(ptr, size)             // column: png
            .execute();

            stat->distribution.free_png(ptr);

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

        for (key_value_geodistribution_hash_map_t::const_iterator it = m_key_value_geodistribution.begin(); it != m_key_value_geodistribution.end(); it++) {
            GeoDistribution* geo = it->second;

            int size;
            void* ptr = geo->create_png(&size);
            sum_size += size;

            statement_insert_into_tag_distributions
            .bind_text(it->first.first)       // column: key
            .bind_text(it->first.second)      // column: value
            .bind_text(for_nodes ? "n" : "w") // column: object_type
            .bind_blob(ptr, size)             // column: png
            .execute();

            geo->free_png(ptr);

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

    void collect_tag_stats(const Osmium::OSM::Object& object) {
        if (m_max_timestamp < object.timestamp()) {
            m_max_timestamp = object.timestamp();
        }

        KeyStats* stat;
        Osmium::OSM::TagList::const_iterator end = object.tags().end();
        for (Osmium::OSM::TagList::const_iterator it = object.tags().begin(); it != end; ++it) {
            const char* key = it->key();

            key_hash_map_t::iterator tags_iterator(tags_stat.find(key));
            if (tags_iterator == tags_stat.end()) {
                stat = new KeyStats();
                tags_stat.insert(std::pair<const char *, KeyStats *>(m_string_store.add(key), stat));
            } else {
                stat = tags_iterator->second;
            }
            stat->update(it->value(), object, m_string_store);

            std::pair<const char*, const char*> keyvalue = std::make_pair(it->key(), it->value());

            if (object.type() == NODE) {
                rough_position_t location = m_map_to_int(static_cast<const Osmium::OSM::Node&>(object).position());
                stat->distribution.add_coordinate(location);
                key_value_geodistribution_hash_map_t::iterator gd_it = m_key_value_geodistribution.find(keyvalue);
                if (gd_it != m_key_value_geodistribution.end()) {
                    gd_it->second->add_coordinate(location);
                }
            }
#ifdef TAGSTATS_GEODISTRIBUTION_FOR_WAYS
            else if (object.type() == WAY) {
                // This will only add the coordinate of the first node in a way to the
                // distribution. We'll see how this goes, maybe we need to store the
                // coordinates of all nodes?
                const Osmium::OSM::WayNodeList& wnl = static_cast<const Osmium::OSM::Way&>(object).nodes();
                if (!wnl.empty()) {
                    key_value_geodistribution_hash_map_t::iterator gd_it = m_key_value_geodistribution.find(keyvalue);
                    for (Osmium::OSM::WayNodeList::const_iterator it = wnl.begin(); it != wnl.end(); ++it) {
                        rough_position_t location = m_storage[it->ref()];
                        stat->distribution.add_coordinate(location);
                        if (gd_it != m_key_value_geodistribution.end()) {
                            gd_it->second->add_coordinate(location);
                        }
                    }
                }
            }
#endif // TAGSTATS_GEODISTRIBUTION_FOR_WAYS
        }

        _update_key_combination_hash(object);
        _update_key_value_combination_hash(object);
    }

    StatisticsHandler statistics_handler;

    MapToInt<rough_position_t> m_map_to_int;

#ifdef TAGSTATS_GEODISTRIBUTION_FOR_WAYS
    storage_t m_storage;
#endif

public:

    TagStatsHandler(Sqlite::Database& database, const std::string& selection_database_name, MapToInt<rough_position_t>& map_to_int, unsigned int min_tag_combination_count) :
        Base(),
        m_min_tag_combination_count(min_tag_combination_count),
        m_max_timestamp(0),
        m_string_store(string_store_size),
        m_database(database),
        statistics_handler(database),
        m_map_to_int(map_to_int)
#ifdef TAGSTATS_GEODISTRIBUTION_FOR_WAYS
        , m_storage()
#endif
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

    void node(const shared_ptr<Osmium::OSM::Node const>& node) {
        statistics_handler.node(node);
        collect_tag_stats(*node);
#ifdef TAGSTATS_GEODISTRIBUTION_FOR_WAYS
        m_storage.set(node->id(), m_map_to_int(node->position()));
#endif
    }

    void way(const shared_ptr<Osmium::OSM::Way const>& way) {
        statistics_handler.way(way);
        collect_tag_stats(*way);
    }

    void relation(const shared_ptr<Osmium::OSM::Relation const>& relation) {
        statistics_handler.relation(relation);
        collect_tag_stats(*relation);

        const char* type = relation->tags().get_value_by_key("type");
        if (type) {
            relation_type_stats_map_t::iterator it = m_relation_type_stats.find(type);
            if (it != m_relation_type_stats.end()) {
                it->second.add(*relation);
            }
        }
    }

    void before_nodes() {
        timer = time(0);
    }

    void after_nodes() {
        _timer_info("processing nodes");
        _print_memory_usage();

        int size;
        void* ptr = GeoDistribution::create_empty_png(&size);
        Sqlite::Statement statement_insert_into_key_distributions(m_database, "INSERT INTO key_distributions (png) VALUES (?);");
        m_database.begin_transaction();
        statement_insert_into_key_distributions
        .bind_blob(ptr, size) // column: png
        .execute();
        m_database.commit();

        gdFree(ptr);

        _print_and_clear_key_distribution_images(true);
        _print_and_clear_tag_distribution_images(true);
        timer = time(0);
        _timer_info("dumping images");
        _print_memory_usage();
    }

    void before_ways() {
        timer = time(0);
    }

    void after_ways() {
        _timer_info("processing ways");
#ifdef TAGSTATS_GEODISTRIBUTION_FOR_WAYS
        _print_and_clear_key_distribution_images(false);
        _print_and_clear_tag_distribution_images(false);
#endif
        _print_memory_usage();
    }

    void before_relations() {
        timer = time(0);
    }

    void after_relations() {
        _timer_info("processing relations");
    }

    void init(Osmium::OSM::Meta&) {
        std::cerr << "Sizes of some important data structures:\n";
        std::cerr << "  sizeof(value_hash_map_t)           = " << sizeof(value_hash_map_t) << "\n";
        std::cerr << "  sizeof(Counter)                    = " << sizeof(Counter) << "\n";
        std::cerr << "  sizeof(key_combination_hash_map_t) = " << sizeof(combination_hash_map_t) << "\n";
        std::cerr << "  sizeof(user_hash_map_t)            = " << sizeof(user_hash_map_t) << "\n";
        std::cerr << "  sizeof(GeoDistribution)            = " << sizeof(GeoDistribution) << "\n";
        std::cerr << "  sizeof(KeyStats)                   = " << sizeof(KeyStats) << "\n\n";

        _print_memory_usage();
        std::cerr << "init done" << std::endl << std::endl;
    }

    void final() {
        statistics_handler.final();
        _print_memory_usage();
        timer = time(0);

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

        for (key_hash_map_t::const_iterator tags_iterator(tags_stat.begin()); tags_iterator != tags_stat.end(); tags_iterator++) {
            KeyStats *stat = tags_iterator->second;

            values_hash_size    += stat->values_hash.size();
            values_hash_buckets += stat->values_hash.bucket_count();

            for (value_hash_map_t::const_iterator values_iterator(stat->values_hash.begin()); values_iterator != stat->values_hash.end(); values_iterator++) {
                statement_insert_into_tags
                .bind_text(tags_iterator->first)                   // column: key
                .bind_text(values_iterator->first)                 // column: value
                .bind_int64(values_iterator->second.all())         // column: count_all
                .bind_int64(values_iterator->second.nodes())       // column: count_nodes
                .bind_int64(values_iterator->second.ways())        // column: count_ways
                .bind_int64(values_iterator->second.relations())   // column: count_relations
                .execute();
            }

            user_hash_size    += stat->user_hash.size();
            user_hash_buckets += stat->user_hash.bucket_count();

            statement_insert_into_keys
            .bind_text(tags_iterator->first)      // column: key
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

            for (combination_hash_map_t::const_iterator it(stat->key_combination_hash.begin()); it != stat->key_combination_hash.end(); it++) {
                const Counter *s = &(it->second);
                statement_insert_into_key_combinations
                .bind_text(tags_iterator->first) // column: key1
                .bind_text(it->first)            // column: key2
                .bind_int64(s->all())            // column: count_all
                .bind_int64(s->nodes())          // column: count_nodes
                .bind_int64(s->ways())           // column: count_ways
                .bind_int64(s->relations())      // column: count_relations
                .execute();
            }

            delete stat; // lets make valgrind happy
        }

        for (key_value_hash_map_t::const_iterator tags_iterator = m_key_value_stats.begin(); tags_iterator != m_key_value_stats.end(); ++tags_iterator) {
            KeyValueStats* stat = tags_iterator->second;

            std::vector<std::string> kv1;
            boost::split(kv1, tags_iterator->first, boost::is_any_of("="));
            kv1.push_back(""); // if there is no = in key, make sure there is an empty value

            for (combination_hash_map_t::const_iterator it = stat->m_key_value_combination_hash.begin(); it != stat->m_key_value_combination_hash.end(); ++it) {
                const Counter* s = &(it->second);

                if (s->all() >= m_min_tag_combination_count) {
                    std::vector<std::string> kv2;
                    boost::split(kv2, it->first, boost::is_any_of("="));
                    kv2.push_back(""); // if there is no = in key, make sure there is an empty value

                    statement_insert_into_tag_combinations
                    .bind_text(kv1[0])          // column: key1
                    .bind_text(kv1[1])          // column: value1
                    .bind_text(kv2[0])          // column: key2
                    .bind_text(kv2[1])          // column: value2
                    .bind_int64(s->all())       // column: count_all
                    .bind_int64(s->nodes())     // column: count_nodes
                    .bind_int64(s->ways())      // column: count_ways
                    .bind_int64(s->relations()) // column: count_relations
                    .execute();
                }
            }

            delete stat; // lets make valgrind happy
        }

        typedef std::pair<const std::string, RelationTypeStats> relation_type_stats_map_iterator_t;
        typedef std::pair<const std::string, RelationRoleStats> relation_role_stats_map_iterator_t;

        BOOST_FOREACH(relation_type_stats_map_iterator_t it, m_relation_type_stats) {
            const RelationTypeStats& r = it.second;
            statement_insert_into_relation_types
            .bind_text(it.first)                 // column: rtype
            .bind_int64(r.m_count)               // column: count
            .bind_int64(r.m_node_members + r.m_way_members + r.m_relation_members)  // column: members_all
            .bind_int64(r.m_node_members)        // columns: members_nodes
            .bind_int64(r.m_way_members)         // columns: members_ways
            .bind_int64(r.m_relation_members)    // columns: members_relations
            .execute();

            BOOST_FOREACH(relation_role_stats_map_iterator_t roleit, r.m_role_counts) {
                const RelationRoleStats& rstats = roleit.second;
                statement_insert_into_relation_roles
                .bind_text(it.first)             // column: rtype
                .bind_text(roleit.first)         // column: role
                .bind_int64(rstats.node + rstats.way + rstats.relation)  // column: count_all
                .bind_int64(rstats.node)         // column: count_nodes
                .bind_int64(rstats.way)          // column: count_ways
                .bind_int64(rstats.relation)     // column: count_relations
                .execute();
            }
        }

        m_database.commit();

        _timer_info("dumping to db");

        std::cerr << std::endl << "hash map sizes:" << std::endl;
        std::cerr << "  tags:     size=" <<   tags_hash_size << " buckets=" <<   tags_hash_buckets << " sizeof(KeyStats)="  << sizeof(KeyStats)  << " *=" <<   tags_hash_size * sizeof(KeyStats) << std::endl;
        std::cerr << "  values:   size=" << values_hash_size << " buckets=" << values_hash_buckets << " sizeof(Counter)=" << sizeof(Counter) << " *=" << values_hash_size * sizeof(Counter) << std::endl;
        std::cerr << "  key combinations: size=" << key_combination_hash_size << " buckets=" << key_combination_hash_buckets << " sizeof(Counter)=" << sizeof(Counter) << " *=" << key_combination_hash_size * sizeof(Counter) << std::endl;
        std::cerr << "  users:    size=" << user_hash_size << " buckets=" << user_hash_buckets << " sizeof(uint32_t)=" << sizeof(uint32_t) << " *=" << user_hash_size * sizeof(uint32_t) << std::endl;

        std::cerr << "  sum: " <<
                  tags_hash_size * sizeof(KeyStats)
                  + values_hash_size * sizeof(Counter)
                  + key_combination_hash_size * sizeof(Counter)
                  + user_hash_size * sizeof(uint32_t)
                  << std::endl;

        std::cerr << std::endl << "total memory for hashes:" << std::endl;
        std::cerr << "  (sizeof(hash key) + sizeof(hash value *) + 2.5 bit overhead) * bucket_count + sizeof(hash value) * size" << std::endl;
        std::cerr << " tags:     " << ((sizeof(const char*)*8 + sizeof(KeyStats *)*8 + 3) * tags_hash_buckets / 8 ) + sizeof(KeyStats) * tags_hash_size << std::endl;
        std::cerr << "  (sizeof(hash key) + sizeof(hash value  ) + 2.5 bit overhead) * bucket_count" << std::endl;
        std::cerr << " values:   " << ((sizeof(const char*)*8 + sizeof(Counter)*8 + 3) * values_hash_buckets / 8 ) << std::endl;
        std::cerr << " key combinations: " << ((sizeof(const char*)*8 + sizeof(Counter)*8 + 3) * key_combination_hash_buckets / 8 ) << std::endl;

        std::cerr << " users:    " << ((sizeof(osm_user_id_t)*8 + sizeof(uint32_t)*8 + 3) * user_hash_buckets / 8 )  << std::endl;

        std::cerr << std::endl;

        _print_memory_usage();
    }

}; // class TagStatsHandler

#endif // TAGSTATS_HANDLER_HPP
