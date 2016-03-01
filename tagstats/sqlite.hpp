#ifndef SQLITE_HPP
#define SQLITE_HPP

/*

  Author: Jochen Topf <jochen@topf.org>

  https://github.com/joto/sqlite-cpp-wrapper

  This code is released into the Public Domain.

*/

#include <cstdint>
#include <stdexcept>
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

    /**
     *  Wrapper class for Sqlite database
     */
    class Database {

    public:

        Database(const char* filename, const int flags) {
            if (SQLITE_OK != sqlite3_open_v2(filename, &m_db, flags, 0)) {
                std::string error = errmsg();
                sqlite3_close(m_db);
                throw Sqlite::Exception("Can't open database", error);
            }
        }

        Database(const std::string& filename, const int flags) : Database(filename.c_str(), flags) {
        }

        ~Database() {
            sqlite3_close(m_db);
        }

        std::string errmsg() {
            if (m_db) {
                return std::string{sqlite3_errmsg(m_db)};
            } else {
                return std::string{"Database is not open"};
            }
        }

        sqlite3* get_sqlite3() {
            return m_db;
        }

        void exec(const std::string& sql) {
            if (SQLITE_OK != sqlite3_exec(m_db, sql.c_str(), 0, 0, 0)) {
                std::string error = errmsg();
                sqlite3_close(m_db);
                throw Sqlite::Exception("Database error", error);
            }
        }

        void begin_transaction() {
            exec("BEGIN TRANSACTION;");
        }

        void commit() {
            exec("COMMIT;");
        }

        void rollback() {
            exec("ROLLBACK;");
        }

    private:

        sqlite3* m_db;

    }; // class Database

    /**
     * Wrapper class for Sqlite prepared statement.
     */
    class Statement {

    public:

        Statement(Database& db, const char* sql) :
            m_db(db),
            m_statement(0),
            m_bindnum(1) {
            sqlite3_prepare_v2(db.get_sqlite3(), sql, -1, &m_statement, 0);
            if (m_statement == 0) {
                throw Sqlite::Exception("Can't prepare statement", m_db.errmsg());
            }
        }

        ~Statement() {
            sqlite3_finalize(m_statement);
        }

        Statement& bind_null() {
            if (SQLITE_OK != sqlite3_bind_null(m_statement, m_bindnum++)) {
                throw Sqlite::Exception{"Can't bind null value", m_db.errmsg()};
            }
            return *this;
        }

        Statement& bind_text(const char* value) {
            if (SQLITE_OK != sqlite3_bind_text(m_statement, m_bindnum++, value, -1, SQLITE_STATIC)) {
                throw Sqlite::Exception{"Can't bind text value", m_db.errmsg()};
            }
            return *this;
        }

        Statement& bind_text(const char* value, size_t size) {
            if (SQLITE_OK != sqlite3_bind_text(m_statement, m_bindnum++, value, size, SQLITE_STATIC)) {
                throw Sqlite::Exception{"Can't bind text value", m_db.errmsg()};
            }
            return *this;
        }

        Statement& bind_text(const std::string& value) {
            if (SQLITE_OK != sqlite3_bind_text(m_statement, m_bindnum++, value.c_str(), value.size(), SQLITE_STATIC)) {
                throw Sqlite::Exception{"Can't bind text value", m_db.errmsg()};
            }
            return *this;
        }

        Statement& bind_int(const int value) {
            if (SQLITE_OK != sqlite3_bind_int(m_statement, m_bindnum++, value)) {
                throw Sqlite::Exception{"Can't bind int value", m_db.errmsg()};
            }
            return *this;
        }

        Statement& bind_int64(const int64_t value) {
            if (SQLITE_OK != sqlite3_bind_int64(m_statement, m_bindnum++, value)) {
                throw Sqlite::Exception{"Can't bind int64 value", m_db.errmsg()};
            }
            return *this;
        }

        Statement& bind_double(const double value) {
            if (SQLITE_OK != sqlite3_bind_double(m_statement, m_bindnum++, value)) {
                throw Sqlite::Exception{"Can't bind double value", m_db.errmsg()};
            }
            return *this;
        }

        Statement& bind_blob(const void* value, const int length) {
            if (SQLITE_OK != sqlite3_bind_blob(m_statement, m_bindnum++, value, length, 0)) {
                throw Sqlite::Exception{"Can't bind blob value", m_db.errmsg()};
            }
            return *this;
        }

        void execute() {
            sqlite3_step(m_statement);
            if (SQLITE_OK != sqlite3_reset(m_statement)) {
                throw Sqlite::Exception{"Can't execute statement", m_db.errmsg()};
            }
            m_bindnum = 1;
        }

        bool read() {
            switch (sqlite3_step(m_statement)) {
                case SQLITE_ROW:
                    return true;
                case SQLITE_DONE:
                    return false;
                default:
                    throw Sqlite::Exception{"Sqlite error", m_db.errmsg()};
            }
        }

        int column_count() {
            return sqlite3_column_count(m_statement);
        }

        const char* get_text_ptr(int column) {
            if (column >= column_count()) {
                throw Sqlite::Exception{"Column larger than max columns", ""};
            }
            const char* textptr = reinterpret_cast<const char*>(sqlite3_column_text(m_statement, column));
            if (!textptr) {
                throw Sqlite::Exception{"Error reading text column", m_db.errmsg()};
            }
            return textptr;
        }

        std::string get_text(int column) {
            return std::string{get_text_ptr(column)};
        }

        int get_int(int column) {
            if (column >= column_count()) {
                throw Sqlite::Exception{"Column larger than max columns", m_db.errmsg()};
            }
            return sqlite3_column_int(m_statement, column);
        }

    private:

        Database& m_db;
        sqlite3_stmt* m_statement;
        int m_bindnum;

    }; // class Statement

} // namespace Sqlite

#endif // SQLITE_HPP
