#ifndef TAGSTATS_SQLITE_HPP
#define TAGSTATS_SQLITE_HPP

/*

Copyright 2012 Jochen Topf <jochen@topf.org> and others (see README).

This file is part of Taginfo (https://github.com/joto/taginfo).

Osmium is free software: you can redistribute it and/or modify it under the
terms of the GNU Lesser General Public License or (at your option) the GNU
General Public License as published by the Free Software Foundation, either
version 3 of the Licenses, or (at your option) any later version.

Osmium is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU Lesser General Public License and the GNU
General Public License for more details.

You should have received a copy of the Licenses along with Osmium. If not, see
<http://www.gnu.org/licenses/>.

*/

#include <iostream>
#include <stdexcept>
#include <stdint.h>
#include <string>

#include <sqlite3.h>

/**
*  @brief The %Sqlite classes wrap the %Sqlite C library.
*/
namespace Sqlite {

    /**
    *  Exception returned by Sqlite wrapper classes when there are errors in the Sqlite3 lib
    */
    class Exception : public std::runtime_error {

    public:

        Exception(const std::string& msg, const std::string& error) :
            std::runtime_error(msg + ": " + error + '\n') {
        }

    };

    class Statement;

    /**
    *  Wrapper class for Sqlite database
    */
    class Database {

    private:

        sqlite3* m_db;

    public:

        Database(const char* filename) {
            if (sqlite3_open_v2(filename, &m_db, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, 0)) {
                sqlite3_close(m_db);
                throw Sqlite::Exception("Can't open database", errmsg());
            }
        }

        ~Database() {
            sqlite3_close(m_db);
        }

        const std::string& errmsg() const {
            static std::string error = std::string(sqlite3_errmsg(m_db));
            return error;
        }

        sqlite3* get_sqlite3() {
            return m_db;
        }

        void begin_transaction() {
            if (SQLITE_OK != sqlite3_exec(m_db, "BEGIN TRANSACTION;", 0, 0, 0)) {
                std::cerr << "Database error: " << sqlite3_errmsg(m_db) << "\n";
                sqlite3_close(m_db);
                throw std::runtime_error("Sqlite error");
            }
        }

        void commit() {
            if (SQLITE_OK != sqlite3_exec(m_db, "COMMIT;", 0, 0, 0)) {
                std::cerr << "Database error: " << sqlite3_errmsg(m_db) << "\n";
                sqlite3_close(m_db);
                throw std::runtime_error("Sqlite error");
            }
        }

        Statement* prepare(const char* sql);

    }; // class Database

    /**
    * Wrapper class for Sqlite prepared statement.
    */
    class Statement {

    private:

        Database* m_db;
        sqlite3_stmt* m_statement;
        int m_bindnum;

    public:

        Statement(Database* db, const char* sql) :
            m_db(db),
            m_statement(0),
            m_bindnum(1) {
            sqlite3_prepare_v2(db->get_sqlite3(), sql, -1, &m_statement, 0);
            if (m_statement == 0) {
                throw Sqlite::Exception("Can't prepare statement", m_db->errmsg());
            }
        }

        ~Statement() {
            sqlite3_finalize(m_statement);
        }

        Statement* bind_null() {
            if (SQLITE_OK != sqlite3_bind_null(m_statement, m_bindnum++)) {
                throw Sqlite::Exception("Can't bind null value", m_db->errmsg());
            }
            return this;
        }

        Statement* bind_text(const char* value) {
            if (SQLITE_OK != sqlite3_bind_text(m_statement, m_bindnum++, value, -1, SQLITE_STATIC)) {
                throw Sqlite::Exception("Can't bind text value", m_db->errmsg());
            }
            return this;
        }

        Statement* bind_text(const std::string& value) {
            if (SQLITE_OK != sqlite3_bind_text(m_statement, m_bindnum++, value.c_str(), -1, SQLITE_STATIC)) {
                throw Sqlite::Exception("Can't bind text value", m_db->errmsg());
            }
            return this;
        }

        Statement* bind_int(int value) {
            if (SQLITE_OK != sqlite3_bind_int(m_statement, m_bindnum++, value)) {
                throw Sqlite::Exception("Can't bind int value", m_db->errmsg());
            }
            return this;
        }

        Statement* bind_int64(int64_t value) {
            if (SQLITE_OK != sqlite3_bind_int64(m_statement, m_bindnum++, value)) {
                throw Sqlite::Exception("Can't bind int64 value", m_db->errmsg());
            }
            return this;
        }

        Statement* bind_double(double value) {
            if (SQLITE_OK != sqlite3_bind_double(m_statement, m_bindnum++, value)) {
                throw Sqlite::Exception("Can't bind double value", m_db->errmsg());
            }
            return this;
        }

        Statement* bind_blob(const void* value, int length) {
            if (SQLITE_OK != sqlite3_bind_blob(m_statement, m_bindnum++, value, length, 0)) {
                throw Sqlite::Exception("Can't bind blob value", m_db->errmsg());
            }
            return this;
        }

        void execute() {
            sqlite3_step(m_statement);
            if (SQLITE_OK != sqlite3_reset(m_statement)) {
                throw Sqlite::Exception("Can't execute statement", m_db->errmsg());
            }
            m_bindnum = 1;
        }

    }; // class Statement

    inline Statement* Database::prepare(const char* sql) {
        return new Statement(this, sql);
    }

} // namespace Sqlite

#endif // TAGSTATS_SQLITE_HPP
