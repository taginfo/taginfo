#ifndef TAGSTATS_STATISTICS_HANDLER_HPP
#define TAGSTATS_STATISTICS_HANDLER_HPP

/*

  Copyright 2012 Jochen Topf <jochen@topf.org>.

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

#include <boost/foreach.hpp>

#include "sqlite.hpp"

/**
 * Osmium handler that collects basic statistics from OSM data and
 * writes it to a Sqlite database.
 */
class StatisticsHandler : public Osmium::Handler::Base {

public:

    StatisticsHandler(Sqlite::Database& database) :
        Base(),
        m_database(database) {
        // if you change anything in this array, also change the corresponding struct below
        static const char *sn[] = {
            "nodes",
            "nodes_without_tags",
            "node_tags",
            "max_node_id",
            "max_tags_on_node",
            "ways",
            "way_tags",
            "way_nodes",
            "way_nodes_consecutive",
            "way_nodes_within_127",
            "way_nodes_within_32767",
            "max_way_id",
            "max_tags_on_way",
            "max_nodes_on_way",
            "closed_ways",
            "relations",
            "relation_tags",
            "relation_members",
            "relation_member_nodes",
            "relation_member_ways",
            "relation_member_relations",
            "max_relation_id",
            "max_tags_on_relation",
            "max_members_on_relation",
            "max_user_id",
            "anon_user_objects",
            "max_node_version",
            "max_way_version",
            "max_relation_version",
            "sum_node_version",
            "sum_way_version",
            "sum_relation_version",
            "max_changeset_id",
            0    // last element (sentinel) must always be 0
        };
        m_stat_names = sn;

        // initialize all statistics to zero
        for (int i=0; m_stat_names[i]; ++i) {
            reinterpret_cast<uint64_t*>(&m_stats)[i] = 0;
        }
    }

    void node(const shared_ptr<Osmium::OSM::Node const>& node) {
        update_common_stats(*node);
        m_stats.nodes++;
        if (m_tag_count == 0) {
            m_stats.nodes_without_tags++;
        }
        if (m_id > static_cast<int64_t>(m_stats.max_node_id)) {
            m_stats.max_node_id = m_id;
        }
        m_stats.node_tags += m_tag_count;
        if (m_tag_count > static_cast<int64_t>(m_stats.max_tags_on_node)) {
            m_stats.max_tags_on_node = m_tag_count;
        }
        if (m_version > static_cast<int64_t>(m_stats.max_node_version)) {
            m_stats.max_node_version = m_version;
        }
        m_stats.sum_node_version += m_version;
    }

    void way(const shared_ptr<Osmium::OSM::Way const>& way) {
        update_common_stats(*way);
        m_stats.ways++;
        if (way->is_closed()) {
            m_stats.closed_ways++;
        }
        if (m_id > static_cast<int64_t>(m_stats.max_way_id)) {
            m_stats.max_way_id = m_id;
        }
        m_stats.way_tags += m_tag_count;
        m_stats.way_nodes += way->nodes().size();
        if (m_tag_count > static_cast<int64_t>(m_stats.max_tags_on_way)) {
            m_stats.max_tags_on_way = m_tag_count;
        }
        if (way->nodes().size() > static_cast<int64_t>(m_stats.max_nodes_on_way)) {
            m_stats.max_nodes_on_way = way->nodes().size();
        }
        if (m_version > static_cast<int64_t>(m_stats.max_way_version)) {
            m_stats.max_way_version = m_version;
        }
        m_stats.sum_way_version += m_version;

        osm_object_id_t ref = 0;
        BOOST_FOREACH(const Osmium::OSM::WayNode& wn, way->nodes()) {
            osm_object_id_t diff = wn.ref() - ref;
            if (diff == 1) {
                ++m_stats.way_nodes_consecutive;
            } else if (diff <= 127) { // 2^7-1
                ++m_stats.way_nodes_within_127;
            } else if (diff <= 32767) { // 2^15-1
                ++m_stats.way_nodes_within_32767;
            }
            ref = wn.ref();
        }
    }

    void relation(const shared_ptr<Osmium::OSM::Relation const>& relation) {
        update_common_stats(*relation);
        m_stats.relations++;
        if (m_id > static_cast<int64_t>(m_stats.max_relation_id)) {
            m_stats.max_relation_id = m_id;
        }
        m_stats.relation_tags += m_tag_count;
        osm_sequence_id_t member_count = relation->members().size();
        m_stats.relation_members += member_count;
        if (m_tag_count > static_cast<int64_t>(m_stats.max_tags_on_relation)) {
            m_stats.max_tags_on_relation = m_tag_count;
        }
        if (member_count > static_cast<int64_t>(m_stats.max_members_on_relation)) {
            m_stats.max_members_on_relation = member_count;
        }
        if (m_version > static_cast<int64_t>(m_stats.max_relation_version)) {
            m_stats.max_relation_version = m_version;
        }
        m_stats.sum_relation_version += m_version;

        BOOST_FOREACH(const Osmium::OSM::RelationMember& member, relation->members()) {
            switch (member.type()) {
                case 'n':
                    ++m_stats.relation_member_nodes;
                    break;
                case 'w':
                    ++m_stats.relation_member_ways;
                    break;
                case 'r':
                    ++m_stats.relation_member_relations;
                    break;
            }
        }
    }

    void final() {
        Sqlite::Statement statement_insert_into_main_stats(m_database, "INSERT INTO stats (key, value) VALUES (?, ?);");
        m_database.begin_transaction();

        for (int i=0; m_stat_names[i]; ++i) {
            statement_insert_into_main_stats
            .bind_text(m_stat_names[i])
            .bind_int64(reinterpret_cast<uint64_t*>(&m_stats)[i])
            .execute();
        }
        statement_insert_into_main_stats
        .bind_text("nodes_with_tags")
        .bind_int64(m_stats.nodes - m_stats.nodes_without_tags)
        .execute();

        m_database.commit();
    }

private:

    // if you change anything in this struct, also change the corresponding array above
    struct statistics {
        uint64_t nodes;
        uint64_t nodes_without_tags;
        uint64_t node_tags;
        uint64_t max_node_id;
        uint64_t max_tags_on_node;
        uint64_t ways;
        uint64_t way_tags;
        uint64_t way_nodes;
        uint64_t way_nodes_consecutive;
        uint64_t way_nodes_within_127;
        uint64_t way_nodes_within_32767;
        uint64_t max_way_id;
        uint64_t max_tags_on_way;
        uint64_t max_nodes_on_way;
        uint64_t closed_ways;
        uint64_t relations;
        uint64_t relation_tags;
        uint64_t relation_members;
        uint64_t relation_member_nodes;
        uint64_t relation_member_ways;
        uint64_t relation_member_relations;
        uint64_t max_relation_id;
        uint64_t max_tags_on_relation;
        uint64_t max_members_on_relation;
        uint64_t max_user_id;
        uint64_t anon_user_objects;
        uint64_t max_node_version;
        uint64_t max_way_version;
        uint64_t max_relation_version;
        uint64_t sum_node_version;
        uint64_t sum_way_version;
        uint64_t sum_relation_version;
        uint64_t max_changeset_id;
    } m_stats;

    const char **m_stat_names;

    Sqlite::Database& m_database;

    osm_object_id_t m_id;
    osm_version_t   m_version;
    int             m_tag_count;

    void update_common_stats(const Osmium::OSM::Object& object) {
        m_id        = object.id();
        m_version   = object.version();
        m_tag_count = object.tags().size();

        osm_user_id_t uid = object.uid();
        if (uid == 0) {
            m_stats.anon_user_objects++;
        }
        if (uid > static_cast<int64_t>(m_stats.max_user_id)) {
            m_stats.max_user_id = uid;
        }

        osm_changeset_id_t changeset = object.changeset();
        if (changeset > static_cast<int64_t>(m_stats.max_changeset_id)) {
            m_stats.max_changeset_id = changeset;
        }
    }

}; // class StatisticsHandler

#endif // TAGSTATS_STATISTICS_HANDLER_HPP
