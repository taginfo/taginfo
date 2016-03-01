#pragma once

#include <cstring>
#include <string>
#include <utility>

/**
 * Hash function used in hash maps that works well with tag
 * key/value strings.
 */
struct djb2_hash {
    size_t operator()(const char *str) const noexcept {
        size_t hash = 5381;
        int c;

        while ((c = *str++)) {
            hash = ((hash << 5) + hash) + c; /* hash * 33 + c */
        }

        return hash;
    }

    size_t operator()(std::pair<const char *, const char*> p) const {
        std::string s{p.first};
        s += '=';
        s += p.second;
        return operator()(s.c_str());
    }
};

/**
 * String comparison used in hash maps.
 */
struct eqstr {
    bool operator()(const char* s1, const char* s2) const noexcept {
        return (s1 == s2) || (s1 && s2 && std::strcmp(s1, s2) == 0);
    }

    bool operator()(std::pair<const char*, const char*> p1,
                    std::pair<const char*, const char*> p2) const noexcept {
        return operator()(p1.first, p2.first) && operator()(p1.second, p2.second);
    }
};

struct strless {
    bool operator()(const char* s1, const char* s2) const noexcept {
        return std::strcmp(s1, s2) < 0;
    }
};

