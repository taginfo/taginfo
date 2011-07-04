
#include <osmium.hpp>

#include <osmium/handler/statistics.hpp>
//#include <osmium/handler/node_location_store.hpp>
#include "geodistribution.hpp"
#include "tagstats_handler.hpp"

GeoDistribution::geo_distribution_t GeoDistribution::distribution_all;

class MyTagStatsHandler : public Osmium::Handler::Base {

    Osmium::Handler::Statistics      osmium_handler_stats;
    TagStatsHandler                  osmium_handler_tagstats;
    //Osmium::Handler::NLS_Sparsetable osmium_handler_node_location_store;

public:

    void init(Osmium::OSM::Meta& meta) {
        osmium_handler_tagstats.init(meta);
        // osmium_handler_node_location_store.init(meta);
    }

    void before_nodes() {
        osmium_handler_tagstats.before_nodes();
    }

    void node(Osmium::OSM::Node *node) {
        osmium_handler_stats.node(node);
        osmium_handler_tagstats.node(node);
        //    osmium_handler_node_location_store.node(node);
    }

    void after_nodes() {
        osmium_handler_tagstats.after_nodes();
    }

    void before_ways() {
        osmium_handler_tagstats.before_ways();
    }

    void way(Osmium::OSM::Way *way) {
        osmium_handler_stats.way(way);
        osmium_handler_tagstats.way(way);
        //    osmium_handler_node_location_store.way(way);
    }

    void after_ways() {
        osmium_handler_tagstats.after_ways();
    }

    void before_relations() {
        osmium_handler_tagstats.before_relations();
    }

    void relation(Osmium::OSM::Relation *relation) {
        osmium_handler_stats.relation(relation);
        osmium_handler_tagstats.relation(relation);
    }

    void after_relations() {
        osmium_handler_tagstats.after_relations();
    }

    void final() {
        // osmium_handler_node_location_store.final();
        osmium_handler_stats.final();
        osmium_handler_tagstats.final();
    }
};

/* ================================================== */

int main(int argc, char *argv[]) {
    Osmium::init();

    GeoDistribution::reset();
    if (argc != 2) {
        std::cerr << "Usage: " << argv[0] << " OSMFILE" << std::endl;
        exit(1);
    }

    Osmium::OSMFile infile(argv[1]);
    MyTagStatsHandler handler;
    infile.read(handler);
}

