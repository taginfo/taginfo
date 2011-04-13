
#define OSMIUM_MAIN
#include <osmium.hpp>

#include <osmium/handler/statistics.hpp>
//#include <osmium/handler/node_location_store.hpp>
#include "tagstats_handler.hpp"

class MyTagStatsHandler : public Osmium::Handler::Base {

    Osmium::Handler::Statistics      osmium_handler_stats;
    TagStatsHandler                  osmium_handler_tagstats;
    //Osmium::Handler::NLS_Sparsetable osmium_handler_node_location_store;

public:

    void callback_init() {
        osmium_handler_tagstats.callback_init();
        // osmium_handler_node_location_store.callback_init();
    }

    void callback_before_nodes() {
        osmium_handler_tagstats.callback_before_nodes();
    }

    void callback_object(Osmium::OSM::Object *object) {
        osmium_handler_stats.callback_object(object);
        osmium_handler_tagstats.callback_object(object);
    }

    void callback_node(Osmium::OSM::Node *node) {
        osmium_handler_stats.callback_node(node);
        //    osmium_handler_node_location_store.callback_node(node);
    }

    void callback_after_nodes() {
        osmium_handler_tagstats.callback_after_nodes();
    }

    void callback_before_ways() {
        osmium_handler_tagstats.callback_before_ways();
    }

    void callback_way(Osmium::OSM::Way *way) {
        osmium_handler_stats.callback_way(way);
        //    osmium_handler_node_location_store.callback_way(way);
    }

    void callback_after_ways() {
        osmium_handler_tagstats.callback_after_ways();
    }

    void callback_before_relations() {
        osmium_handler_tagstats.callback_before_relations();
    }

    void callback_relation(Osmium::OSM::Relation *relation) {
        osmium_handler_stats.callback_relation(relation);
    }

    void callback_after_relations() {
        osmium_handler_tagstats.callback_after_relations();
    }

    void callback_final() {
        // osmium_handler_node_location_store.callback_final();
        osmium_handler_stats.callback_final();
        osmium_handler_tagstats.callback_final();
    }
};

/* ================================================== */

int main(int argc, char *argv[]) {
    Osmium::Framework osmium;

    if (argc != 2) {
        std::cerr << "Usage: " << argv[0] << " OSMFILE" << std::endl;
        exit(1);
    }

    osmium.parse_osmfile<MyTagStatsHandler>(argv[1]);
}

