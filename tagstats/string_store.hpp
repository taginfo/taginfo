#ifndef TAGSTATS_STRING_STORE_HPP
#define TAGSTATS_STRING_STORE_HPP

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
#include <cstdlib>
#include <cstring>
#include <list>
#include <stdexcept>
#include <string>

/**
 * class StringStore
 *
 * Storage of lots of strings (const char *). Memory is allocated in chunks.
 * If a string is added and there is no space in the current chunk, a new
 * chunk will be allocated. Strings added to the store must not be larger
 * than the chunk size.
 *
 * All memory is released when the destructor is called. There is no other way
 * to release all or part of the memory.
 *
 */
class StringStore {

    size_t m_chunk_size;

    std::list<std::string> m_chunks;

    void add_chunk() {
        m_chunks.push_front(std::string());
        m_chunks.front().reserve(m_chunk_size);
    }

public:

    explicit StringStore(size_t chunk_size) :
        m_chunk_size(chunk_size),
        m_chunks() {
        add_chunk();
    }

    /**
     * Add a null terminated string to the store. This will
     * automatically get more memory if we are out.
     * Returns a pointer to the copy of the string we have
     * allocated.
     */
    const char* add(const char* string) {
        const size_t len = std::strlen(string) + 1;

        assert(len <= m_chunk_size);

        size_t chunk_len = m_chunks.front().size();
        if (chunk_len + len > m_chunks.front().capacity()) {
            add_chunk();
            chunk_len = 0;
        }

        m_chunks.front().append(string);
        m_chunks.front().append(1, '\0');

        return m_chunks.front().c_str() + chunk_len;
    }

    // These functions get you some idea how much memory was
    // used.
    size_t get_chunk_size() const noexcept {
        return m_chunk_size;
    }

    size_t get_chunk_count() const noexcept {
        return m_chunks.size();
    }

    size_t get_used_bytes_in_last_chunk() const noexcept {
        assert(!m_chunks.empty());
        return m_chunks.front().size();
    }

}; // class StringStore

#endif // TAGSTATS_STRING_STORE_HPP
