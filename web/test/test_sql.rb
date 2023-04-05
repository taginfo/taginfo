$LOAD_PATH << 'lib'
require File.join(File.dirname(__FILE__), '..', 'lib', 'sql.rb')
require 'test/unit'

class TestSql < Test::Unit::TestCase

    def setup
        @select = SQL::Select.new('test', 'test')
    end

    def test_order_by_no_block
        assert_kind_of SQL::Select, @select
        @select.order_by(:foo, 'ASC')
        assert_equal 'test ORDER BY foo ASC', @select.build_query
    end

    def test_order_by_no_block_desc
        assert_kind_of SQL::Select, @select
        @select.order_by(:foo, 'DESC')
        assert_equal 'test ORDER BY foo DESC', @select.build_query
    end

    def test_order_by_simple
        assert_kind_of SQL::Select, @select
        @select.order_by(:foo, 'ASC', &:foo)
        assert_equal 'test ORDER BY foo ASC', @select.build_query
    end

    def test_order_by_desc
        @select.order_by(:foo, 'DESC', &:foo)
        assert_equal 'test ORDER BY foo DESC', @select.build_query
    end

    def test_order_by_unused
        @select.order_by([:foo], 'ASC') do |o|
            o.foo
            o.bar! 'baz'
        end
        assert_equal 'test ORDER BY foo ASC', @select.build_query
    end

    def test_order_by_reverse
        @select.order_by(:bar, 'ASC') do |o|
            o.foo
            o.bar! 'baz'
        end
        assert_equal 'test ORDER BY baz DESC', @select.build_query
    end

    def test_order_by_array
        @select.order_by([:foo, 'bar'], 'ASC') do |o|
            o.bar! 'baz'
            o.foo
        end
        assert_equal 'test ORDER BY foo ASC,baz DESC', @select.build_query
    end

    def test_order_by_array_reverse
        @select.order_by(%i[bar foo], 'DESC') do |o|
            o.foo
            o.bar!
        end
        assert_equal 'test ORDER BY bar ASC,foo DESC', @select.build_query
    end

    def test_order_by_array_multiple
        @select.order_by(%i[bar foo], 'DESC') do |o|
            o.foo 'f1'
            o.foo! :f2
            o.bar :baz
        end
        assert_equal 'test ORDER BY baz DESC,f1 DESC,f2 ASC', @select.build_query
    end

    def test_order_by_map
        @select.order_by(:length, 'ASC') do |o|
            o.length 'length(foo)'
            o.length :foo
        end
        assert_equal 'test ORDER BY length(foo) ASC,foo ASC', @select.build_query
    end

    def test_order_by_asc_or_desc
        assert_raise ArgumentError do
            @select.order_by(:foo, 'blub', &:foo)
        end
    end

    def test_order_by_no_def
        assert_raise ArgumentError do
            @select.order_by(:foo, &:bar)
        end
    end

end
