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

#include <cstring>
#include <iterator>
#include <map>
#include <string>
#include <utility>
#include <vector>

#include <google/sparse_hash_map>
#include <boost/algorithm/string/split.hpp>
#include <boost/algorithm/string/classification.hpp>

#include <osmium/osm.hpp>
#include <osmium/util/memory.hpp>
#include <osmium/util/verbose_output.hpp>

#include "geodistribution.hpp"
#include "hash.hpp"
#include "sqlite.hpp"
#include "string_store.hpp"
#include "tagstats_handler.hpp"

void TagStatsHandler::_timer_info(const char* msg) {
    int duration = time(0) - m_timer;
    m_vout << "  " << msg << " took " << duration << " seconds (about " << duration / 60 << " minutes)\n";
    m_timer = time(0);
}

void TagStatsHandler::_update_key_combination_hash(osmium::item_type type,
                                                   osmium::TagList::const_iterator it1,
                                                   osmium::TagList::const_iterator end) {
    for (; it1 != end; ++it1) {
        const char* key1 = it1->key();
        key_hash_map_t::iterator tsi1(m_tags_stat.find(key1));
        for (auto it2 = std::next(it1); it2 != end; ++it2) {
            const char* key2 = it2->key();
            key_hash_map_t::iterator tsi2(m_tags_stat.find(key2));
            if (std::strcmp(key1, key2) < 0) {
                tsi1->second->add_key_combination(tsi2->first, type);
            } else {
                tsi2->second->add_key_combination(tsi1->first, type);
            }
        }
    }
}

void TagStatsHandler::_update_key_value_combination_hash2(osmium::item_type type,
                                                          osmium::TagList::const_iterator it,
                                                          osmium::TagList::const_iterator end,
                                                          key_value_hash_map_t::iterator kvi1,
                                                          const std::string& key_value1) {
    for (; it != end; ++it) {
        std::string key_value2{it->key()};
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

void TagStatsHandler::_update_key_value_combination_hash(osmium::item_type type,
                                                         osmium::TagList::const_iterator it,
                                                         osmium::TagList::const_iterator end) {
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

void TagStatsHandler::_print_and_clear_key_distribution_images(bool for_nodes) {
    uint64_t sum_size=0;

    Sqlite::Statement statement_insert_into_key_distributions(m_database,
        "INSERT INTO key_distributions (key, object_type, png) VALUES (?, ?, ?);");

    m_database.begin_transaction();

    for (const auto& p : m_tags_stat) {
        KeyStats& stat = *p.second;

        if (for_nodes) {
            stat.cells.count[0] = stat.distribution.cells();
        } else {
            stat.cells.count[1] = stat.distribution.cells();
        }

        const auto png = stat.distribution.create_png();
        sum_size += png.size;

        statement_insert_into_key_distributions
            .bind_text(p.first)               // column: key
            .bind_text(for_nodes ? "n" : "w") // column: object_type
            .bind_blob(png.data, png.size)    // column: png
            .execute();

        stat.distribution.clear();
    }

    m_vout << "gridcells_all: " << GeoDistribution::count_all_set_cells() << "\n";
    m_vout << "sum of key location image sizes: " << (sum_size / 1024) << "kB\n";

    m_database.commit();
}

void TagStatsHandler::_print_and_clear_tag_distribution_images(bool for_nodes) {
    uint64_t sum_size=0;

    Sqlite::Statement statement_insert_into_tag_distributions(m_database,
        "INSERT INTO tag_distributions (key, value, object_type, png) VALUES (?, ?, ?, ?);");
    m_database.begin_transaction();

    for (const auto& geodist : m_key_value_geodistribution) {
        GeoDistribution* geo = geodist.second;

        auto png = geo->create_png();
        sum_size += png.size;

        statement_insert_into_tag_distributions
            .bind_text(geodist.first.first)       // column: key
            .bind_text(geodist.first.second)      // column: value
            .bind_text(for_nodes ? "n" : "w") // column: object_type
            .bind_blob(png.data, png.size)    // column: png
            .execute();

        if (for_nodes) {
            geo->clear();
        }
    }

    m_vout << "sum of tag location image sizes: " << (sum_size / 1024) << "kB\n";

    m_database.commit();
}

template <typename T>
size_t container_size_mb(const T& container) {
    return container.size() * sizeof(typename T::value_type) / (1024 * 1024);
}

void TagStatsHandler::_print_memory_usage() {
    m_vout << "MEMORY USAGE:\n";

    auto chunk_size = m_string_store.get_chunk_size() / (1024 * 1024);
    auto chunk_count = m_string_store.get_chunk_count();

    m_vout << "  string store:           " << (chunk_size * chunk_count) << "MB ["
           << "chunk_size=" << chunk_size << "MB "
           << "chunks=" <<  chunk_count
           << " bytes_in_last=" << (m_string_store.get_used_bytes_in_last_chunk() / 1024) << "kB"
           << "]\n";

    m_vout << "  key stats store:        " << container_size_mb(m_key_stats_store) << "MB\n";
    m_vout << "  key_value stats store:  " << container_size_mb(m_key_value_stats) << "MB\n";
    m_vout << "  geo distribution store: " << container_size_mb(m_geo_distribution_store) << "MB\n";

    osmium::MemoryUsage mcheck;
    m_vout << "  overall memory used:\n"
           << "    current:              " << mcheck.current() << "MB\n"
           << "    peak:                 " << mcheck.peak() << "MB\n";
}

void TagStatsHandler::collect_tag_stats(const osmium::OSMObject& object) {
    if (m_max_timestamp < object.timestamp().seconds_since_epoch()) {
        m_max_timestamp = object.timestamp().seconds_since_epoch();
    }

    if (object.tags().empty()) {
        return;
    }

    KeyStats* stat;
    for (const auto& tag : object.tags()) {
        const auto tags_iterator = m_tags_stat.find(tag.key());
        if (tags_iterator == m_tags_stat.end()) {
            m_key_stats_store.emplace_back();
            stat = &m_key_stats_store.back();
            m_tags_stat.insert(std::pair<const char*, KeyStats*>(m_string_store.add(tag.key()), stat));
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
        } else if (object.type() == osmium::item_type::way) {
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

    auto first = object.tags().begin();
    auto last  = object.tags().end();
    _update_key_combination_hash(object.type(), first, last);
    _update_key_value_combination_hash(object.type(), first, last);
}

TagStatsHandler::TagStatsHandler(Sqlite::Database& database,
        const std::string& selection_database_name,
        MapToInt<rough_position_type>& map_to_int,
        unsigned int min_tag_combination_count,
        osmium::util::VerboseOutput& vout) :
    Handler(),
    m_vout(vout),
    m_min_tag_combination_count(min_tag_combination_count),
    m_timer(time(0)),
    m_tags_stat(),
    m_key_value_stats(),
    m_key_value_geodistribution(),
    m_relation_type_stats(),
    m_max_timestamp(0),
    m_string_store(string_store_size),
    m_database(database),
    m_statistics_handler(database),
    m_map_to_int(map_to_int),
    m_storage(),
    m_last_type(osmium::item_type::node)
{
    if (!selection_database_name.empty()) {
        Sqlite::Database sdb(selection_database_name.c_str(), SQLITE_OPEN_READONLY);

        {
            Sqlite::Statement select(sdb, "SELECT key FROM interesting_tags WHERE value IS NULL;");
            while (select.read()) {
                std::string key_value = select.get_text(0);
                m_key_value_stats_store.emplace_back();
                m_key_value_stats[m_string_store.add(key_value.c_str())] = &m_key_value_stats_store.back();
            }
        }
        {
            Sqlite::Statement select(sdb, "SELECT key || '=' || value FROM interesting_tags WHERE value IS NOT NULL;");
            while (select.read()) {
                std::string key_value = select.get_text(0);
                m_key_value_stats_store.emplace_back();
                m_key_value_stats[m_string_store.add(key_value.c_str())] = &m_key_value_stats_store.back();
            }
        }
        {
            Sqlite::Statement select(sdb, "SELECT key, value FROM frequent_tags;");
            while (select.read()) {
                std::string key   = select.get_text(0);
                std::string value = select.get_text(1);
                m_geo_distribution_store.emplace_back();
                m_key_value_geodistribution[std::make_pair(m_string_store.add(key.c_str()),
                                                           m_string_store.add(value.c_str()))] = &m_geo_distribution_store.back();
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

    m_vout << "------------------------------------------------------------------------------\n";
    m_vout << "Processing nodes...\n";
    m_timer = time(0);
}

void TagStatsHandler::node(const osmium::Node& node) {
    m_statistics_handler.node(node);
    collect_tag_stats(node);
    m_storage.set(node.positive_id(), m_map_to_int(node.location()));
}

void TagStatsHandler::way(const osmium::Way& way) {
    if (m_last_type != osmium::item_type::way) {
        before_ways();
        m_last_type = osmium::item_type::way;
    }

    m_statistics_handler.way(way);
    collect_tag_stats(way);
}

void TagStatsHandler::relation(const osmium::Relation& relation) {
    if (m_last_type != osmium::item_type::relation) {
        before_relations();
        m_last_type = osmium::item_type::relation;
    }

    m_statistics_handler.relation(relation);
    collect_tag_stats(relation);

    const char* type = relation.tags().get_value_by_key("type");
    if (type) {
        auto it = m_relation_type_stats.find(type);
        if (it != m_relation_type_stats.end()) {
            it->second.add(relation);
        }
    }
}

void TagStatsHandler::before_ways() {
    _timer_info("processing nodes");

    auto png = GeoDistribution::create_empty_png();
    Sqlite::Statement statement_insert_into_key_distributions(m_database, "INSERT INTO key_distributions (png) VALUES (?);");
    m_database.begin_transaction();
    statement_insert_into_key_distributions
        .bind_blob(png.data, png.size) // column: png
        .execute();
    m_database.commit();

    _print_and_clear_key_distribution_images(true);
    _print_and_clear_tag_distribution_images(true);
    _timer_info("dumping images");

    _print_memory_usage();

    m_vout << "------------------------------------------------------------------------------\n";
    m_vout << "Processing ways...\n";
}

void TagStatsHandler::before_relations() {
    _timer_info("processing ways");

    _print_and_clear_key_distribution_images(false);
    _print_and_clear_tag_distribution_images(false);
    _timer_info("dumping images");

    _print_memory_usage();

    m_vout << "------------------------------------------------------------------------------\n";
    m_vout << "Processing relations...\n";
}

void TagStatsHandler::write_to_database() {
    _timer_info("processing relations");
    _print_memory_usage();

    m_vout << "------------------------------------------------------------------------------\n";
    m_vout << "Writing results to database...\n";
    m_statistics_handler.write_to_database();

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

    uint64_t values_hash_size = 0;
    uint64_t values_hash_buckets = 0;

    uint64_t key_combination_hash_size = 0;
    uint64_t key_combination_hash_buckets = 0;

    uint64_t user_hash_size = 0;
    uint64_t user_hash_buckets = 0;

    for (const auto& key_stat : m_tags_stat) {
        KeyStats* stat = key_stat.second;

        values_hash_size    += stat->values_hash.size();
        values_hash_buckets += stat->values_hash.bucket_count();

        for (const auto& value_stat : stat->values_hash) {
            statement_insert_into_tags
                .bind_text(key_stat.first)                 // column: key
                .bind_text(value_stat.first)               // column: value
                .bind_int64(value_stat.second.all())       // column: count_all
                .bind_int64(value_stat.second.nodes())     // column: count_nodes
                .bind_int64(value_stat.second.ways())      // column: count_ways
                .bind_int64(value_stat.second.relations()) // column: count_relations
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
                .bind_text(key_stat.first)                     // column: key1
                .bind_text(key_combo_stat.first)               // column: key2
                .bind_int64(key_combo_stat.second.all())       // column: count_all
                .bind_int64(key_combo_stat.second.nodes())     // column: count_nodes
                .bind_int64(key_combo_stat.second.ways())      // column: count_ways
                .bind_int64(key_combo_stat.second.relations()) // column: count_relations
                .execute();
        }
    }

    for (const auto& key_value_stat : m_key_value_stats) {
        KeyValueStats* stat = key_value_stat.second;

        std::vector<std::string> kv1;
        boost::split(kv1, key_value_stat.first, boost::is_any_of("="));
        kv1.push_back(""); // if there is no = in key, make sure there is an empty value

        for (const auto& key_value_combo_stat : stat->m_key_value_combination_hash) {
            if (key_value_combo_stat.second.all() >= m_min_tag_combination_count) {
                std::vector<std::string> kv2;
                boost::split(kv2, key_value_combo_stat.first, boost::is_any_of("="));
                kv2.push_back(""); // if there is no = in key, make sure there is an empty value

                statement_insert_into_tag_combinations
                    .bind_text(kv1[0])                                   // column: key1
                    .bind_text(kv1[1])                                   // column: value1
                    .bind_text(kv2[0])                                   // column: key2
                    .bind_text(kv2[1])                                   // column: value2
                    .bind_int64(key_value_combo_stat.second.all())       // column: count_all
                    .bind_int64(key_value_combo_stat.second.nodes())     // column: count_nodes
                    .bind_int64(key_value_combo_stat.second.ways())      // column: count_ways
                    .bind_int64(key_value_combo_stat.second.relations()) // column: count_relations
                    .execute();
            }
        }
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

    const uint64_t tags_hash_size = m_tags_stat.size();
    const uint64_t tags_hash_buckets = m_tags_stat.size()*2; //bucket_count();

    m_vout << "hash map sizes:\n";
    m_vout << "  tags:       " << (tags_hash_size * sizeof(KeyStats) / 1024) << "kB"
           << " [size=" << tags_hash_size << " buckets=" << tags_hash_buckets << " sizeof(KeyStats)="  << sizeof(KeyStats) << "]\n";
    m_vout << "  values:     " << (values_hash_size * sizeof(Counter) / 1024) << "kB"
           << " [size=" << values_hash_size << " buckets=" << values_hash_buckets << " sizeof(Counter)=" << sizeof(Counter) << "]\n";
    m_vout << "  key combos: " << (key_combination_hash_size * sizeof(Counter) / 1024) << "kB"
           << " [size=" << key_combination_hash_size << " buckets=" << key_combination_hash_buckets << " sizeof(Counter)=" << sizeof(Counter) << "]\n";
    m_vout << "  users:      " << (user_hash_size * sizeof(uint32_t) / 1024) << "kB"
           << " [size=" << user_hash_size << " buckets=" << user_hash_buckets << " sizeof(uint32_t)=" << sizeof(uint32_t) << "]\n";

    m_vout << "  sum:        " << (
                (tags_hash_size * sizeof(KeyStats)
                + values_hash_size * sizeof(Counter)
                + key_combination_hash_size * sizeof(Counter)
                + user_hash_size * sizeof(uint32_t))
                / 1024)
                << "kB\n";

    m_vout << "\n" << "estimated total memory for hashes:" << "\n";

    auto size_tags = ((sizeof(const char*)*8 + sizeof(KeyStats *)*8 + 3) * tags_hash_buckets / 8 ) + sizeof(KeyStats) * tags_hash_size;
    m_vout << " tags:       " << (size_tags / 1024) << "kB"
           << " [(sizeof(hash key) + sizeof(hash value*) + 2.5 bit overhead) * bucket_count + sizeof(hash value) * size]\n";

    auto size_values = (sizeof(const char*)*8 + sizeof(Counter)*8 + 3) * values_hash_buckets / 8;
    m_vout << " values:     " << (size_values / 1024) << "kB"
           << " [(sizeof(hash key) + sizeof(hash value) + 2.5 bit overhead) * bucket_count]\n";

    auto size_key_combos = (sizeof(const char*)*8 + sizeof(Counter)*8 + 3) * key_combination_hash_buckets / 8;
    m_vout << " key combos: " << (size_key_combos / 1024) << "kB\n";

    auto size_users = (sizeof(osmium::user_id_type)*8 + sizeof(uint32_t)*8 + 3) * user_hash_buckets / 8;
    m_vout << " users:      " << (size_users / 1024) << "kB\n";

    m_vout << " sum:        " << ((size_tags + size_values + size_key_combos + size_users) / 1024) << "kB\n";

    m_vout << "\n";

    _print_memory_usage();

    m_vout << "------------------------------------------------------------------------------\n";
}

