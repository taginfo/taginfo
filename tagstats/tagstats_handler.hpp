#ifndef TAGSTATS_HANDLER_HPP
#define TAGSTATS_HANDLER_HPP

#include <google/sparse_hash_map>
#include <string>
#include <fstream>

#include <osmium/utils/sqlite.hpp>
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
};

/**
 * String comparison used in google hash map.
 */
struct eqstr {
    bool operator()(const char* s1, const char* s2) const {
        return (s1 == s2) || (s1 && s2 && strcmp(s1, s2) == 0);
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

#ifdef TAGSTATS_COUNT_USERS
typedef google::sparse_hash_map<osm_user_id_t, uint32_t> user_hash_map_t;
#endif // TAGSTATS_COUNT_USERS

#ifdef TAGSTATS_COUNT_KEY_COMBINATIONS
typedef google::sparse_hash_map<const char *, Counter, djb2_hash, eqstr> key_combination_hash_map_t;
#endif // TAGSTATS_COUNT_KEY_COMBINATIONS

/**
 * A KeyStats object holds all statistics for an OSM tag key.
 */
class KeyStats {

public:

    Counter key;
    Counter values;

#ifdef TAGSTATS_COUNT_KEY_COMBINATIONS
    key_combination_hash_map_t key_combination_hash;
#endif // TAGSTATS_COUNT_KEY_COMBINATIONS

#ifdef TAGSTATS_COUNT_USERS
    user_hash_map_t user_hash;
#endif // TAGSTATS_COUNT_USERS

    value_hash_map_t values_hash;

    KeyStats()
        : key(),
          values(),
#ifdef TAGSTATS_COUNT_KEY_COMBINATIONS
          key_combination_hash(),
#endif // TAGSTATS_COUNT_KEY_COMBINATIONS
#ifdef TAGSTATS_COUNT_USERS
          user_hash(),
#endif // TAGSTATS_COUNT_USERS
          values_hash() {
    }

    GeoDistribution node_distribution;

    void update(const char *value, Osmium::OSM::Object *object, StringStore *string_store) {
        key.count[object->get_type()]++;

        value_hash_map_t::iterator values_iterator(values_hash.find(value));
        if (values_iterator == values_hash.end()) {
            Counter counter;
            counter.count[object->get_type()] = 1;
            values_hash.insert(std::pair<const char *, Counter>(string_store->add(value), counter));
            values.count[object->get_type()]++;
        } else {
            values_iterator->second.count[object->get_type()]++;
            if (values_iterator->second.count[object->get_type()] == 1) {
                values.count[object->get_type()]++;
            }
        }

#ifdef TAGSTATS_COUNT_USERS
        user_hash[object->get_uid()]++;
#endif // TAGSTATS_COUNT_USERS

        if (object->get_type() == NODE) {
            node_distribution.add_coordinate(static_cast<Osmium::OSM::Node *>(object)->get_lon(),
                                             static_cast<Osmium::OSM::Node *>(object)->get_lat());
        }
    }

    void add_key_kombination(const char *other_key, osm_object_id_t type) {
        key_combination_hash[other_key].count[type]++;
    }

}; // class KeyStats

typedef google::sparse_hash_map<const char *, KeyStats *, djb2_hash, eqstr> key_hash_map_t;


/**
 * Osmium handler that creates statistics for Taginfo.
 */
class TagStatsHandler : public Osmium::Handler::Base {

    time_t timer;

    key_hash_map_t tags_stat;

    time_t max_timestamp;

    // this must be much bigger than the largest string we want to store
    static const int string_store_size = 1024 * 1024 * 10;
    StringStore *string_store;

    Osmium::Sqlite::Database *db;

    void _timer_info(const char *msg) {
        int duration = time(0) - timer;
        std::cerr << msg << " took " << duration << " seconds (about " << duration / 60 << " minutes)" << std::endl;
    }

#ifdef TAGSTATS_COUNT_KEY_COMBINATIONS
    void _update_key_combination_hash(Osmium::OSM::Object *object) {
        const char *key1, *key2;

        int tag_count = object->tag_count();
        for (int i=0; i<tag_count; i++) {
            key1 = object->get_tag_key(i);
            key_hash_map_t::iterator tsi1(tags_stat.find(key1));
            for (int j=i+1; j<tag_count; j++) {
                key2 = object->get_tag_key(j);
                key_hash_map_t::iterator tsi2(tags_stat.find(key2));
                if (strcmp(key1, key2) < 0) {
                    tsi1->second->add_key_kombination(tsi2->first, object->get_type());
                } else {
                    tsi2->second->add_key_kombination(tsi1->first, object->get_type());
                }
            }
        }
    }
#endif // TAGSTATS_COUNT_KEY_COMBINATIONS

    void _print_images() {
        int sum_size=0;

        Osmium::Sqlite::Statement *statement_insert_into_key_distributions = db->prepare("INSERT INTO key_distributions (key, png) VALUES (?, ?);");
        db->begin_transaction();

        for (key_hash_map_t::const_iterator it(tags_stat.begin()); it != tags_stat.end(); it++) {
            KeyStats *stat = it->second;

            int size;
            void *ptr = stat->node_distribution.create_png(&size);
            sum_size += size;
            statement_insert_into_key_distributions
            ->bind_text(it->first) // column: key
            ->bind_blob(ptr, size) // column: png
            ->execute();

            stat->node_distribution.free_png(ptr);
        }

        std::cerr << "gridcells_all: " << GeoDistribution::count_all_set_cells() << std::endl;
        std::cerr << "sum of location image sizes: " << sum_size << std::endl;

        db->commit();
        delete statement_insert_into_key_distributions;
    }

    void _print_memory_usage() {
        std::cerr << "string_store: chunk_size=" << string_store->get_chunk_size() / 1024 / 1024 << "MB"
                  <<                  " chunks=" << string_store->get_chunk_count()
                  <<                  " memory=" << (string_store->get_chunk_size() / 1024 / 1024) * string_store->get_chunk_count() << "MB"
                  <<           " bytes_in_last=" << string_store->get_used_bytes_in_last_chunk() / 1024 << "kB"
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

    void collect_tag_stats(Osmium::OSM::Object *object) {
        if (max_timestamp < object->get_timestamp()) {
            max_timestamp = object->get_timestamp();
        }

        KeyStats *stat;
        int tag_count = object->tag_count();
        for (int i=0; i<tag_count; i++) {
            const char* key = object->get_tag_key(i);

            key_hash_map_t::iterator tags_iterator(tags_stat.find(key));
            if (tags_iterator == tags_stat.end()) {
                stat = new KeyStats();
                tags_stat.insert(std::pair<const char *, KeyStats *>(string_store->add(key), stat));
            } else {
                stat = tags_iterator->second;
            }
            stat->update(object->get_tag_value(i), object, string_store);
        }

#ifdef TAGSTATS_COUNT_KEY_COMBINATIONS
        _update_key_combination_hash(object);
#endif // TAGSTATS_COUNT_KEY_COMBINATIONS
    }

public:

    TagStatsHandler() : Base(), max_timestamp(0) {
        string_store = new StringStore(string_store_size);
        db = new Osmium::Sqlite::Database("taginfo-db.db");
    }

    ~TagStatsHandler() {
        delete db;
        delete string_store;
    }

    void callback_node(Osmium::OSM::Node *node) {
        collect_tag_stats(node);
    }

    void callback_way(Osmium::OSM::Way *way) {
        collect_tag_stats(way);
    }

    void callback_relation(Osmium::OSM::Relation *relation) {
        collect_tag_stats(relation);
    }

    void callback_before_nodes() {
        timer = time(0);
    }

    void callback_after_nodes() {
        _timer_info("processing nodes");
        _print_memory_usage();
        timer = time(0);
        _print_images();
        _timer_info("dumping images");
        _print_memory_usage();
    }

    void callback_before_ways() {
        timer = time(0);
    }

    void callback_after_ways() {
        _timer_info("processing ways");
        _print_memory_usage();
    }

    void callback_before_relations() {
        timer = time(0);
    }

    void callback_after_relations() {
        _timer_info("processing relations");
    }

    void callback_init() {
        std::cerr << "sizeof(value_hash_map_t) = " << sizeof(value_hash_map_t) << std::endl;
        std::cerr << "sizeof(Counter) = " << sizeof(Counter) << std::endl;

#ifdef TAGSTATS_COUNT_KEY_COMBINATIONS
        std::cerr << "sizeof(key_combination_hash_map_t) = " << sizeof(key_combination_hash_map_t) << std::endl;
#endif // TAGSTATS_COUNT_KEY_COMBINATIONS

#ifdef TAGSTATS_COUNT_USERS
        std::cerr << "sizeof(user_hash_map_t) = " << sizeof(user_hash_map_t) << std::endl;
#endif // TAGSTATS_COUNT_USERS

        std::cerr << "sizeof(GeoDistribution) = " << sizeof(GeoDistribution) << std::endl;
        std::cerr << "sizeof(KeyStats) = " << sizeof(KeyStats) << std::endl << std::endl;

        _print_memory_usage();
        std::cerr << "init done" << std::endl << std::endl;
    }

    void callback_final() {
        _print_memory_usage();
        timer = time(0);

        Osmium::Sqlite::Statement *statement_insert_into_keys = db->prepare("INSERT INTO keys (key, " \
                " count_all,  count_nodes,  count_ways,  count_relations, " \
                "values_all, values_nodes, values_ways, values_relations, " \
                " users_all, " \
                "grids) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);");

        Osmium::Sqlite::Statement *statement_insert_into_tags = db->prepare("INSERT INTO tags (key, value, " \
                "count_all, count_nodes, count_ways, count_relations) " \
                "VALUES (?, ?, ?, ?, ?, ?);");

#ifdef TAGSTATS_COUNT_KEY_COMBINATIONS
        Osmium::Sqlite::Statement *statement_insert_into_key_combinations = db->prepare("INSERT INTO keypairs (key1, key2, " \
                "count_all, count_nodes, count_ways, count_relations) " \
                "VALUES (?, ?, ?, ?, ?, ?);");
#endif // TAGSTATS_COUNT_KEY_COMBINATIONS

        Osmium::Sqlite::Statement *statement_update_meta = db->prepare("UPDATE source SET data_until=?");

        db->begin_transaction();

        struct tm *tm = gmtime(&max_timestamp);
        static char max_timestamp_str[Osmium::OSM::Object::max_length_timestamp+1];
        strftime(max_timestamp_str, sizeof(max_timestamp_str), "%Y-%m-%d %H:%M:%S", tm);
        statement_update_meta->bind_text(max_timestamp_str)->execute();

        uint64_t tags_hash_size=tags_stat.size();
        uint64_t tags_hash_buckets=tags_stat.size()*2; //bucket_count();

        uint64_t values_hash_size=0;
        uint64_t values_hash_buckets=0;

#ifdef TAGSTATS_COUNT_KEY_COMBINATIONS
        uint64_t key_combination_hash_size=0;
        uint64_t key_combination_hash_buckets=0;
#endif // TAGSTATS_COUNT_KEY_COMBINATIONS

#ifdef TAGSTATS_COUNT_USERS
        uint64_t user_hash_size=0;
        uint64_t user_hash_buckets=0;
#endif // TAGSTATS_COUNT_USERS

        for (key_hash_map_t::const_iterator tags_iterator(tags_stat.begin()); tags_iterator != tags_stat.end(); tags_iterator++) {
            KeyStats *stat = tags_iterator->second;

            values_hash_size    += stat->values_hash.size();
            values_hash_buckets += stat->values_hash.bucket_count();

            for (value_hash_map_t::const_iterator values_iterator(stat->values_hash.begin()); values_iterator != stat->values_hash.end(); values_iterator++) {
                statement_insert_into_tags
                ->bind_text(tags_iterator->first)                   // column: key
                ->bind_text(values_iterator->first)                 // column: value
                ->bind_int64(values_iterator->second.all())         // column: count_all
                ->bind_int64(values_iterator->second.nodes())       // column: count_nodes
                ->bind_int64(values_iterator->second.ways())        // column: count_ways
                ->bind_int64(values_iterator->second.relations())   // column: count_relations
                ->execute();
            }

#ifdef TAGSTATS_COUNT_USERS
            user_hash_size    += stat->user_hash.size();
            user_hash_buckets += stat->user_hash.bucket_count();
#endif // TAGSTATS_COUNT_USERS

            statement_insert_into_keys
            ->bind_text(tags_iterator->first)      // column: key
            ->bind_int64(stat->key.all())          // column: count_all
            ->bind_int64(stat->key.nodes())        // column: count_nodes
            ->bind_int64(stat->key.ways())         // column: count_ways
            ->bind_int64(stat->key.relations())    // column: count_relations
            ->bind_int64(stat->values_hash.size()) // column: values_all
            ->bind_int64(stat->values.nodes())     // column: values_nodes
            ->bind_int64(stat->values.ways())      // column: values_ways
            ->bind_int64(stat->values.relations()) // column: values_relations
#ifdef TAGSTATS_COUNT_USERS
            ->bind_int64(stat->user_hash.size())   // column: users_all
#else
            ->bind_int64(0)
#endif // TAGSTATS_COUNT_USERS
            ->bind_int64(stat->node_distribution.get_cells()) // column: grids
            ->execute();

#ifdef TAGSTATS_COUNT_KEY_COMBINATIONS
            key_combination_hash_size    += stat->key_combination_hash.size();
            key_combination_hash_buckets += stat->key_combination_hash.bucket_count();

            for (key_combination_hash_map_t::const_iterator it(stat->key_combination_hash.begin()); it != stat->key_combination_hash.end(); it++) {
                const Counter *s = &(it->second);
                statement_insert_into_key_combinations
                ->bind_text(tags_iterator->first) // column: key1
                ->bind_text(it->first)            // column: key2
                ->bind_int64(s->all())            // column: count_all
                ->bind_int64(s->nodes())          // column: count_nodes
                ->bind_int64(s->ways())           // column: count_ways
                ->bind_int64(s->relations())      // column: count_relations
                ->execute();
            }
#endif // TAGSTATS_COUNT_KEY_COMBINATIONS

            delete stat; // lets make valgrind happy
        }

        db->commit();

        delete statement_update_meta;
#ifdef TAGSTATS_COUNT_KEY_COMBINATIONS
        delete statement_insert_into_key_combinations;
#endif // TAGSTATS_COUNT_KEY_COMBINATIONS
        delete statement_insert_into_tags;
        delete statement_insert_into_keys;

        _timer_info("dumping to db");

        std::cerr << std::endl << "hash map sizes:" << std::endl;
        std::cerr << "  tags:     size=" <<   tags_hash_size << " buckets=" <<   tags_hash_buckets << " sizeof(KeyStats)="  << sizeof(KeyStats)  << " *=" <<   tags_hash_size * sizeof(KeyStats) << std::endl;
        std::cerr << "  values:   size=" << values_hash_size << " buckets=" << values_hash_buckets << " sizeof(Counter)=" << sizeof(Counter) << " *=" << values_hash_size * sizeof(Counter) << std::endl;

#ifdef TAGSTATS_COUNT_KEY_COMBINATIONS
        std::cerr << "  key combinations: size=" << key_combination_hash_size << " buckets=" << key_combination_hash_buckets << " sizeof(Counter)=" << sizeof(Counter) << " *=" << key_combination_hash_size * sizeof(Counter) << std::endl;
#endif // TAGSTATS_COUNT_KEY_COMBINATIONS

#ifdef TAGSTATS_COUNT_USERS
        std::cerr << "  users:    size=" << user_hash_size << " buckets=" << user_hash_buckets << " sizeof(uint32_t)=" << sizeof(uint32_t) << " *=" << user_hash_size * sizeof(uint32_t) << std::endl;
#endif // TAGSTATS_COUNT_USERS

        std::cerr << "  sum: " <<
                  tags_hash_size * sizeof(KeyStats)
                  + values_hash_size * sizeof(Counter)
#ifdef TAGSTATS_COUNT_KEY_COMBINATIONS
                  + key_combination_hash_size * sizeof(Counter)
#endif // TAGSTATS_COUNT_KEY_COMBINATIONS
#ifdef TAGSTATS_COUNT_USERS
                  + user_hash_size * sizeof(uint32_t)
#endif // TAGSTATS_COUNT_USERS
                  << std::endl;

        std::cerr << std::endl << "total memory for hashes:" << std::endl;
        std::cerr << "  (sizeof(hash key) + sizeof(hash value *) + 2.5 bit overhead) * bucket_count + sizeof(hash value) * size" << std::endl;
        std::cerr << " tags:     " << ((sizeof(const char*)*8 + sizeof(KeyStats *)*8 + 3) * tags_hash_buckets / 8 ) + sizeof(KeyStats) * tags_hash_size << std::endl;
        std::cerr << "  (sizeof(hash key) + sizeof(hash value  ) + 2.5 bit overhead) * bucket_count" << std::endl;
        std::cerr << " values:   " << ((sizeof(const char*)*8 + sizeof(Counter)*8 + 3) * values_hash_buckets / 8 ) << std::endl;
#ifdef TAGSTATS_COUNT_KEY_COMBINATIONS
        std::cerr << " key combinations: " << ((sizeof(const char*)*8 + sizeof(Counter)*8 + 3) * key_combination_hash_buckets / 8 ) << std::endl;
#endif // TAGSTATS_COUNT_KEY_COMBINATIONS

#ifdef TAGSTATS_COUNT_USERS
        std::cerr << " users:    " << ((sizeof(osm_user_id_t)*8 + sizeof(uint32_t)*8 + 3) * user_hash_buckets / 8 )  << std::endl;
#endif // TAGSTATS_COUNT_USERS

        std::cerr << std::endl;

        _print_memory_usage();
    }

}; // class TagStatsHandler

#endif // TAGSTATS_HANDLER_HPP
