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

#include <iostream>

#include "tagstats_handler.hpp"

int main() {
    std::cout << "sizeof(Counter).................................= " << sizeof(Counter) << "\n";
    std::cout << "sizeof(GeoDistribution)........................ = " << sizeof(GeoDistribution) << "\n";
    std::cout << "sizeof(KeyStats)............................... = " << sizeof(KeyStats) << "\n";
    std::cout << "sizeof(KeyValueStats).......................... = " << sizeof(KeyValueStats) << "\n";
    std::cout << "sizeof(StringStore)............................ = " << sizeof(StringStore) << "\n";
    std::cout << "sizeof(key_hash_map_type)...................... = " << sizeof(key_hash_map_type) << "\n";
    std::cout << "sizeof(value_hash_map_type).................... = " << sizeof(value_hash_map_type) << "\n";
    std::cout << "sizeof(key_value_hash_map_type)................ = " << sizeof(key_value_hash_map_type) << "\n";
    std::cout << "sizeof(key_combination_hash_map_type).......... = " << sizeof(combination_hash_map_type) << "\n";
    std::cout << "sizeof(key_value_geodistribution_hash_map_type) = " << sizeof(key_value_geodistribution_hash_map_type) << "\n";
    std::cout << "sizeof(user_hash_map_type)..................... = " << sizeof(user_hash_map_type) << "\n";
}

