$LOAD_PATH << 'lib'
require File.join(File.dirname(__FILE__), '..', 'lib', 'utils.rb')
require 'test/unit'

class TestSql < Test::Unit::TestCase

    def test_like_escape
        assert_equal 'x@%y', like_escape('x%y')
        assert_equal 'x@_', like_escape('x_')
        assert_equal '@@a', like_escape('@a')
        assert_equal '', like_escape('')
        assert_equal '', like_escape(nil)
    end

    def test_like_prefix
        assert_equal 'postal@_%', like_prefix('postal_')
        assert_equal '@%foo%', like_prefix('%foo')
    end

    def test_like_contains
        assert_equal '%name%', like_contains('name')
        assert_equal '%foo@_bar%', like_contains('foo_bar')
        assert_equal '%@@123%', like_contains('@123')
    end

end
