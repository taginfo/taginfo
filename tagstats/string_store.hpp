#ifndef STRING_STORE_HPP
#define STRING_STORE_HPP

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

#include <list>
#include <stdexcept>
#include <new>
#include <cstring>

/**
 * class StringStore
 *
 * Storage of lots of strings (const char *). Memory is allocated in chunks.
 * If a string is added and there is no space in the current chunk, a new
 * chunk will be allocated.
 *
 * All memory is released when the destructor is called. There is no other way
 * to release all or part of the memory.
 *
 */
class StringStore {

    int chunk_size;

    // number of bytes that are available in the current chunk
    int current_rest_length;

    // pointer where the next string is stored
    char *current_ptr;

    // list of chunks
    std::list<void *> chunks;

    const char *_add_chunk() {
        current_ptr = (char *) malloc(chunk_size);
        if (! current_ptr) {
            throw std::bad_alloc();
        }
        current_rest_length = chunk_size;
        chunks.push_back(current_ptr);
        return current_ptr;
    }

    bool _add(const char *string) {
        if (current_rest_length <= 1) {
            _add_chunk();
        }
        char *next_ptr = (char *) memccpy(current_ptr, string, 0, current_rest_length);
        if (next_ptr) {
            current_rest_length -= (next_ptr - current_ptr);
            current_ptr = next_ptr;
            return true;
        }
        return false;
    }

public:

    StringStore(int chunk_size) : chunk_size(chunk_size) {
        _add_chunk();
    }

    ~StringStore() {
        while (! chunks.empty()) {
            free(chunks.back());
            chunks.pop_back();
        }
    }

    /**
     * Add a null terminated string to the store. This will
     * automatically get more memory if we are out.
     * Returns a pointer to the copy of the string we have
     * allocated.
     *
     * Throws std::length_error if the string we want to
     * add is longer then the chunk size.
     */
    const char *add(const char *string) {
        const char *string_ptr = current_ptr;

        if (! _add(string)) {
            string_ptr = _add_chunk();
            if (! _add(string)) {
                throw std::length_error("strings added to StringStore must be shorter than chunk_size");
            }
        }

        return string_ptr;
    }

    // These functions get you some idea how much memory was
    // used.
    int get_chunk_size() const {
        return chunk_size;
    }

    int get_chunk_count() const {
        return chunks.size();
    }

    int get_used_bytes_in_last_chunk() const {
        return chunk_size - current_rest_length;
    }

};

#endif // STRING_STORE_HPP
