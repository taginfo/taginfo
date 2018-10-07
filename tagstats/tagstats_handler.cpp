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
#include <cstring>
#include <iomanip>
#include <iterator>
#include <map>
#include <string>
#include <utility>

#include <osmium/osm.hpp>
#include <osmium/util/memory.hpp>
#include <osmium/util/verbose_output.hpp>

#include "geodistribution.hpp"
#include "hash.hpp"
#include "sqlite.hpp"
#include "string_store.hpp"
#include "tagstats_handler.hpp"

struct split_result {
    const char* k;
    size_t ksize;
    const char* v;
    size_t vsize;
};

split_result split_key_value(const char* kv) noexcept {
    const char* v = std::strchr(kv, '=');

    if (v) {
        return split_result{kv, size_t(v - kv), v + 1, std::strlen(v+1)};
    } else {
        return split_result{kv, std::strlen(kv), "", 0};
    }
}

template <typename T>
uint64_t show_std_unordered_map_memory_usage(osmium::util::VerboseOutput& out, const T& hash_map) {
    const auto value_size = sizeof(typename T::value_type);
    const auto size = hash_map.size();
    const auto buckets = hash_map.bucket_count();

    const int64_t sum = size * (value_size + sizeof(void*)) + // members and next ptr * size
                        buckets * (sizeof(size_t) + sizeof(void*)); // bucket size and head ptr

    out << std::setw(8) << (sum / 1024) << " kB [size="
        << size << " buckets="
        << buckets << " sizeof(value_type)="
        << value_size << "]\n";

    return sum;
}

template <typename T>
uint64_t show_std_map_memory_usage(osmium::util::VerboseOutput& out, const T& map) {
    const auto value_size = sizeof(typename T::value_type);
    const auto size = map.size();

    const int64_t sum = size * (value_size + sizeof(void*) * 2); // members and left/right ptr * size

    out << std::setw(8) << (sum / 1024) << " kB [size="
        << size << " sizeof(value_type)="
        << value_size << "]\n";

    return sum;
}

template <typename TKey, typename TValue>
uint64_t show_sparsehash_map_memory_usage(osmium::util::VerboseOutput& out, uint64_t size, uint64_t buckets) {
    const auto key_size = sizeof(TKey);
    const auto value_size = sizeof(TValue);

    const auto size_values = (key_size*8 + value_size*8 + 3) * buckets / 8;

    out << std::setw(8) << (size_values / 1024) << " kB [(sizeof(hash key)("
        << key_size << ") + sizeof(hash value)("
        << value_size << ") + 2.5 bit overhead) * bucket_count("
        << buckets << "), size="
        << size << "]\n";

    return size_values;
}

uint64_t show_string_store_memory_usage(osmium::util::VerboseOutput& out, const StringStore& string_store) {
    const auto chunk_size = string_store.get_chunk_size() / 1024;
    const auto chunk_count = string_store.get_chunk_count();
    out << std::setw(8) << (chunk_size * chunk_count) << " kB ["
        << "chunk_size=" << chunk_size << "kB "
        << "chunks=" <<  chunk_count
        << "]\n";
    return string_store.get_chunk_size() * chunk_count;
}

uint64_t show_location_index_memory_usage(osmium::util::VerboseOutput& out, const LocationIndex& location_index) {
    out << std::setw(8) << (location_index.used_memory() / 1024) << " kB ["
        << "size=" << location_index.size()
        << "]\n";
    return location_index.used_memory();
}

void TagStatsHandler::timer_info(const char* msg) {
    const auto duration = time(0) - m_timer;
    m_vout << "  " << msg << " took " << duration << " seconds (about " << duration / 60 << " minutes)\n";
    m_timer = time(0);
}

void TagStatsHandler::update_key_combination_hash(osmium::item_type type,
                                                  osmium::TagList::const_iterator it1,
                                                  osmium::TagList::const_iterator end) {
    for (; it1 != end; ++it1) {
        const char* key1 = it1->key();
        const auto tsi1 = m_tags_stat.find(key1);
        for (auto it2 = std::next(it1); it2 != end; ++it2) {
            const char* key2 = it2->key();
            const auto tsi2 = m_tags_stat.find(key2);
            if (std::strcmp(key1, key2) < 0) {
                tsi1->second.add_key_combination(tsi2->first, type);
            } else {
                tsi2->second.add_key_combination(tsi1->first, type);
            }
        }
    }
}

void TagStatsHandler::update_key_value_combination_hash2(osmium::item_type type,
                                                         osmium::TagList::const_iterator it,
                                                         osmium::TagList::const_iterator end,
                                                         key_value_hash_map_type::iterator kvi1,
                                                         const std::string& key_value1) {
    std::string key_value2;
    for (; it != end; ++it) {
        key_value2 = it->key();
        auto kvi2 = m_key_value_stats.find(key_value2.c_str());
        if (kvi2 != m_key_value_stats.end()) {
            if (key_value1 < key_value2) {
                kvi1->second.add_key_combination(kvi2->first, type);
            } else {
                kvi2->second.add_key_combination(kvi1->first, type);
            }
        }

        key_value2 += '=';
        key_value2 += it->value();

        kvi2 = m_key_value_stats.find(key_value2.c_str());
        if (kvi2 != m_key_value_stats.end()) {
            if (key_value1 < key_value2) {
                kvi1->second.add_key_combination(kvi2->first, type);
            } else {
                kvi2->second.add_key_combination(kvi1->first, type);
            }
        }
    }
}

void TagStatsHandler::update_key_value_combination_hash(osmium::item_type type,
                                                        osmium::TagList::const_iterator it,
                                                        osmium::TagList::const_iterator end) {
    std::string key_value1;
    for (; it != end; ++it) {
        key_value1 = it->key();
        auto kvi1 = m_key_value_stats.find(key_value1.c_str());
        if (kvi1 != m_key_value_stats.end()) {
            update_key_value_combination_hash2(type, std::next(it), end, kvi1, key_value1);
        }

        key_value1 += '=';
        key_value1 += it->value();

        kvi1 = m_key_value_stats.find(key_value1.c_str());
        if (kvi1 != m_key_value_stats.end()) {
            update_key_value_combination_hash2(type, std::next(it), end, kvi1, key_value1);
        }
    }
}

void TagStatsHandler::print_and_clear_key_distribution_images(bool for_nodes) {
    uint64_t sum_size = 0;

    Sqlite::Statement statement_insert_into_key_distributions{m_database,
        "INSERT INTO key_distributions (key, object_type, png) VALUES (?, ?, ?);"};

    m_database.begin_transaction();

    for (auto& p : m_tags_stat) {
        KeyStats& stat = p.second;

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
    m_vout << "sum of key location image sizes: " << std::setw(6) << (sum_size / 1024) << " kB\n";

    m_database.commit();
}

void TagStatsHandler::print_and_clear_tag_distribution_images(bool for_nodes) {
    uint64_t sum_size = 0;

    Sqlite::Statement statement_insert_into_tag_distributions{m_database,
        "INSERT INTO tag_distributions (key, value, object_type, png) VALUES (?, ?, ?, ?);"};
    m_database.begin_transaction();

    for (auto& geodist : m_key_value_geodistribution) {
        GeoDistribution& geo = geodist.second;

        const auto png = geo.create_png();
        sum_size += png.size;

        statement_insert_into_tag_distributions
            .bind_text(geodist.first.first)   // column: key
            .bind_text(geodist.first.second)  // column: value
            .bind_text(for_nodes ? "n" : "w") // column: object_type
            .bind_blob(png.data, png.size)    // column: png
            .execute();

        if (for_nodes) {
            geo.clear();
        }
    }

    m_vout << "sum of tag location image sizes: " << std::setw(6) << (sum_size / 1024) << " kB\n";

    m_database.commit();
}

void TagStatsHandler::print_actual_memory_usage() {
    osmium::MemoryUsage mcheck;
    m_vout << "\n"
           << "Actual memory usage:\n"
           << "  current: " << mcheck.current() << "MB\n"
           << "  peak:    " << mcheck.peak() << "MB\n";
}

KeyStats& TagStatsHandler::get_stat(const char* key) {
    const auto it = m_tags_stat.find(key);
    if (it == m_tags_stat.end()) {
        const auto sit = m_tags_stat.emplace(std::make_pair(m_string_store.add(key), KeyStats{}));
        assert(sit.second);
        return sit.first->second;
    } else {
        return it->second;
    }
}

void TagStatsHandler::collect_tag_stats(const osmium::OSMObject& object) {
    if (m_max_timestamp < object.timestamp().seconds_since_epoch()) {
        m_max_timestamp = object.timestamp().seconds_since_epoch();
    }

    if (object.tags().empty()) {
        return;
    }

    for (const auto& tag : object.tags()) {
        KeyStats& stat = get_stat(tag.key());
        stat.update(tag.value(), object, m_string_store);

        const auto keyvalue = std::make_pair(tag.key(), tag.value());

        if (object.type() == osmium::item_type::node) {
            const auto location = m_map_to_int(static_cast<const osmium::Node&>(object).location());
            stat.distribution.add_coordinate(location);
            const auto gd_it = m_key_value_geodistribution.find(keyvalue);
            if (gd_it != m_key_value_geodistribution.end()) {
                gd_it->second.add_coordinate(location);
            }
        } else if (object.type() == osmium::item_type::way) {
            const auto& wnl = static_cast<const osmium::Way&>(object).nodes();
            if (!wnl.empty()) {
                const auto gd_it = m_key_value_geodistribution.find(keyvalue);
                for (const auto& wn : wnl) {
                    try {
                        const auto location = m_location_index.get(wn.positive_ref());
                        stat.distribution.add_coordinate(location);
                        if (gd_it != m_key_value_geodistribution.end()) {
                            gd_it->second.add_coordinate(location);
                        }
                    } catch (const osmium::not_found&) {
                        // node is missing for way: ignore
                    }
                }
            }
        }
    }

    const auto first = object.tags().begin();
    const auto last  = object.tags().end();
    update_key_combination_hash(object.type(), first, last);
    update_key_value_combination_hash(object.type(), first, last);
}

TagStatsHandler::TagStatsHandler(Sqlite::Database& database,
        const std::string& selection_database_name,
        MapToInt& map_to_int,
        unsigned int min_tag_combination_count,
        osmium::util::VerboseOutput& vout,
        LocationIndex& location_index) :
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
    m_location_index(location_index),
    m_last_type(osmium::item_type::node)
{
    if (!selection_database_name.empty()) {
        Sqlite::Database sdb(selection_database_name.c_str(), SQLITE_OPEN_READONLY);

        {
            Sqlite::Statement select{sdb, "SELECT key FROM interesting_tags WHERE value IS NULL;"};
            while (select.read()) {
                const auto key_value = select.get_text_ptr(0);
                m_key_value_stats.emplace(m_string_store.add(key_value), KeyValueStats{});
            }
        }
        {
            Sqlite::Statement select{sdb, "SELECT key || '=' || value FROM interesting_tags WHERE value IS NOT NULL;"};
            while (select.read()) {
                const auto key_value = select.get_text_ptr(0);
                m_key_value_stats.emplace(m_string_store.add(key_value), KeyValueStats{});
            }
        }
        {
            Sqlite::Statement select{sdb, "SELECT key, value FROM frequent_tags;"};
            while (select.read()) {
                const auto key   = select.get_text_ptr(0);
                const auto value = select.get_text_ptr(1);
                m_key_value_geodistribution.emplace(std::make_pair(m_string_store.add(key),
                                                                   m_string_store.add(value)),
                                                    GeoDistribution{});
            }
        }
        {
            Sqlite::Statement select{sdb, "SELECT rtype FROM interesting_relation_types;"};
            while (select.read()) {
                const auto rtype = select.get_text_ptr(0);
                m_relation_type_stats[rtype] = RelationTypeStats{};
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
    m_location_index.set(node.positive_id(), m_map_to_int(node.location()));
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
        const auto it = m_relation_type_stats.find(type);
        if (it != m_relation_type_stats.end()) {
            it->second.add(relation);
        }
    }
}

void TagStatsHandler::before_ways() {
    timer_info("processing nodes");

    auto png = GeoDistribution::create_empty_png();
    Sqlite::Statement statement_insert_into_key_distributions{m_database, "INSERT INTO key_distributions (png) VALUES (?);"};
    m_database.begin_transaction();
    statement_insert_into_key_distributions
        .bind_blob(png.data, png.size) // column: png
        .execute();
    m_database.commit();

    print_and_clear_key_distribution_images(true);
    print_and_clear_tag_distribution_images(true);
    timer_info("dumping images");

    print_actual_memory_usage();

    m_vout << "------------------------------------------------------------------------------\n";
    m_vout << "Processing ways...\n";
}

void TagStatsHandler::before_relations() {
    timer_info("processing ways");

    print_and_clear_key_distribution_images(false);
    print_and_clear_tag_distribution_images(false);
    timer_info("dumping images");

    print_actual_memory_usage();

    m_vout << "------------------------------------------------------------------------------\n";
    m_vout << "Processing relations...\n";
}

void TagStatsHandler::write_to_database() {
    timer_info("processing relations");
    print_actual_memory_usage();

    m_vout << "------------------------------------------------------------------------------\n";
    m_vout << "Writing results to database...\n";
    m_statistics_handler.write_to_database();

    Sqlite::Statement statement_insert_into_keys{m_database, "INSERT INTO keys (key, " \
            " count_all,  count_nodes,  count_ways,  count_relations, " \
            "values_all, values_nodes, values_ways, values_relations, " \
            " users_all, " \
            "cells_nodes, cells_ways) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);"};

    Sqlite::Statement statement_insert_into_tags{m_database, "INSERT INTO tags (key, value, " \
            "count_all, count_nodes, count_ways, count_relations) " \
            "VALUES (?, ?, ?, ?, ?, ?);"};

    Sqlite::Statement statement_insert_into_key_combinations{m_database, "INSERT INTO key_combinations (key1, key2, " \
            "count_all, count_nodes, count_ways, count_relations) " \
            "VALUES (?, ?, ?, ?, ?, ?);"};

    Sqlite::Statement statement_insert_into_tag_combinations{m_database, "INSERT INTO tag_combinations (key1, value1, key2, value2, " \
            "count_all, count_nodes, count_ways, count_relations) " \
            "VALUES (?, ?, ?, ?, ?, ?, ?, ?);"};

    Sqlite::Statement statement_insert_into_relation_types{m_database, "INSERT INTO relation_types (rtype, count, " \
            "members_all, members_nodes, members_ways, members_relations) " \
            "VALUES (?, ?, ?, ?, ?, ?);"};

    Sqlite::Statement statement_insert_into_relation_roles{m_database, "INSERT INTO relation_roles (rtype, role, " \
            "count_all, count_nodes, count_ways, count_relations) " \
            "VALUES (?, ?, ?, ?, ?, ?);"};

    Sqlite::Statement statement_update_meta{m_database, "UPDATE source SET data_until=?"};

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
        const KeyStats& stat = key_stat.second;

        values_hash_size    += stat.values_hash.size();
        values_hash_buckets += stat.values_hash.bucket_count();

        for (const auto& value_stat : stat.values_hash) {
            statement_insert_into_tags
                .bind_text(key_stat.first)                 // column: key
                .bind_text(value_stat.first)               // column: value
                .bind_int64(value_stat.second.all())       // column: count_all
                .bind_int64(value_stat.second.nodes())     // column: count_nodes
                .bind_int64(value_stat.second.ways())      // column: count_ways
                .bind_int64(value_stat.second.relations()) // column: count_relations
                .execute();
        }

        user_hash_size    += stat.user_hash.size();
        user_hash_buckets += stat.user_hash.bucket_count();

        statement_insert_into_keys
            .bind_text(key_stat.first)           // column: key
            .bind_int64(stat.key.all())          // column: count_all
            .bind_int64(stat.key.nodes())        // column: count_nodes
            .bind_int64(stat.key.ways())         // column: count_ways
            .bind_int64(stat.key.relations())    // column: count_relations
            .bind_int64(stat.values_hash.size()) // column: values_all
            .bind_int64(stat.values.nodes())     // column: values_nodes
            .bind_int64(stat.values.ways())      // column: values_ways
            .bind_int64(stat.values.relations()) // column: values_relations
            .bind_int64(stat.user_hash.size())   // column: users_all
            .bind_int64(stat.cells.nodes())      // column: cells_nodes
            .bind_int64(stat.cells.ways())       // column: cells_ways
            .execute();

        key_combination_hash_size    += stat.key_combination_hash.size();
        key_combination_hash_buckets += stat.key_combination_hash.bucket_count();

        for (const auto& key_combo_stat : stat.key_combination_hash) {
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
        const KeyValueStats& stat = key_value_stat.second;
        const auto sr1 = split_key_value(key_value_stat.first);
        for (const auto& key_value_combo_stat : stat.m_key_value_combination_hash) {
            if (key_value_combo_stat.second.all() >= m_min_tag_combination_count) {
                const auto sr2 = split_key_value(key_value_combo_stat.first);
                statement_insert_into_tag_combinations
                    .bind_text(sr1.k, sr1.ksize)                         // column: key1
                    .bind_text(sr1.v, sr1.vsize)                         // column: value1
                    .bind_text(sr2.k, sr2.ksize)                         // column: key2
                    .bind_text(sr2.v, sr2.vsize)                         // column: value2
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

    timer_info("writing results to database");

    m_vout << "\n" << "Estimated memory usage:" << "\n";

    m_vout << "  tags_stat: ............... ";
    uint64_t total = show_std_unordered_map_memory_usage(m_vout, m_tags_stat);

    m_vout << "  key_value_stats: ......... ";
    total += show_std_unordered_map_memory_usage(m_vout, m_key_value_stats);

    m_vout << "  key_value_geodistribution: ";
    total += show_std_unordered_map_memory_usage(m_vout, m_key_value_geodistribution);

    m_vout << "  relation_type_stats: ..... ";
    total += show_std_map_memory_usage(m_vout, m_relation_type_stats);

    m_vout << "  values: .................. ";
    total += show_sparsehash_map_memory_usage<const char*, Counter>(m_vout, values_hash_size, values_hash_buckets);

    m_vout << "  key_combos: .............. ";
    total += show_sparsehash_map_memory_usage<const char*, Counter>(m_vout, key_combination_hash_size, key_combination_hash_buckets);

    m_vout << "  users: ................... ";
    total += show_sparsehash_map_memory_usage<osmium::user_id_type, uint32_t>(m_vout, user_hash_size, user_hash_buckets);

    m_vout << "  string_store: ............ ";
    total += show_string_store_memory_usage(m_vout, m_string_store);

    m_vout << "  location_index: .......... ";
    total += show_location_index_memory_usage(m_vout, m_location_index);

    m_vout << "  ======================================\n";
    m_vout << "  total: ................... " << std::setw(8) << (total / 1024) << " kB\n";

    print_actual_memory_usage();

    m_vout << "------------------------------------------------------------------------------\n";
}

