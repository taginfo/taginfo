/*

  Copyright (C) 2015-2017 Jochen Topf <jochen@topf.org>.

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

#include <cassert>
#include <cstdlib>
#include <cstring>
#include <fcntl.h>
#include <iostream>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>
#include <vector>

#include "sqlite.hpp"

const int MIN_STRLEN = 4;
const int MAX_STRLEN = 120;
const int MAX_EDIT_DISTANCE = 2;

/**
 * Compute Levenshtein edit distance. This is a very simple implementation of
 * the Levenshtein algorithm I copied from somewhere on the Internet, but it
 * is fast enough for our purpose here.
 */
unsigned int edit_distance(const char* str1, int len1, const char* str2, int len2) noexcept {
    static unsigned d[MAX_STRLEN][MAX_STRLEN];

    d[0][0] = 0;
    for (int i = 1; i <= len1; ++i) d[i][0] = i;
    for (int i = 1; i <= len2; ++i) d[0][i] = i;

    for (int i = 1; i <= len1; ++i) {
        for (int j = 1; j <= len2; ++j) {
            d[i][j] = std::min( std::min(d[i - 1][j] + 1,d[i][j - 1] + 1),
                                d[i - 1][j - 1] + (str1[i - 1] == str2[j - 1] ? 0 : 1) );
        }
    }

    return d[len1][len2];
}

/**
 * Are the two given strings similar according to some metric?
 */
int similarity(const char* str1, int len1, const char* str2, int len2) noexcept {
    // Do not check very short strings, because they create too many false
    // positives.
    if (len1 < MIN_STRLEN || len2 < MIN_STRLEN) {
        return -1;
    }

    // Do not check very long strings. This keeps memory use and run time for
    // Levenshtein algorithm in check.
    if (len1 >= MAX_STRLEN || len2 >= MAX_STRLEN) {
        return -1;
    }

    // Check if one string is a substring of the other. This will also check
    // if both strings differ only in case.
    if (strcasestr(str1, str2) || strcasestr(str2, str1)) {
        return 0;
    }

    // Do not check strings if they have very different lengths, they can't
    // be similar according to Levenshtein anyway.
    if (std::abs(len1 - len2) >= MAX_EDIT_DISTANCE) {
        return -1;
    }

    // Check Levenshtein edit distance.
    const int distance = edit_distance(str1, len1, str2, len2);
    if (distance <= MAX_EDIT_DISTANCE) {
        return distance;
    }

    return -1;
}

/**
 * Iterate over all (null-terminated) strings in the memory between begin and
 * end and find similar strings.
 */
void find_similarities(const char* begin, const char* end, Sqlite::Statement& insert) {
    int len1;
    for (const char* str1 = begin; str1 != end; str1 += len1 + 1) {
        len1 = std::strlen(str1);
        int len2;
        for (const char* str2 = str1 + len1; str2 != end; str2 += len2 + 1) {
            len2 = std::strlen(str2);
            int sim = similarity(str1, len1, str2, len2);
            if (sim >= 0) {
                //std::cout << "[" << str1 << "][" << str2 << "]\n";
                insert.bind_text(str1).bind_text(str2).bind_int(sim).execute();
            }
        }
    }
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        std::cerr << "similarity DATABASE\n";
        return 1;
    }

    std::string data;

    Sqlite::Database db{argv[1], SQLITE_OPEN_READWRITE};
    Sqlite::Statement select{db, "SELECT key FROM keys ORDER BY key"};
    while (select.read()) {
        data += select.get_text_ptr(0);
        data += '\0';
    }

    Sqlite::Statement insert{db, "INSERT INTO similar_keys (key1, key2, similarity) VALUES (?, ?, ?)"};
    db.begin_transaction();
    find_similarities(data.c_str(), data.c_str() + data.size(), insert);
    db.commit();

    return 0;
}

