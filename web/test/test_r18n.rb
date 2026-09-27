require_relative '../lib/r18n'
require 'test/unit'

class TestR18n < Test::Unit::TestCase

    def test_normalizes_locale_casing
        assert_equal 'pt-br', Sinatra::R18n.normalize_locale('pt-BR')
        assert_equal 'ro-md', Sinatra::R18n.normalize_locale('ro_MD')
    end

    def test_normalizes_simplified_chinese_locales
        %w[zh zh-CN zh-SG zh-Hans].each do |locale|
            assert_equal 'zh-hans', Sinatra::R18n.normalize_locale(locale)
        end
    end

    def test_normalizes_traditional_chinese_locales
        %w[zh-TW zh-HK zh-MO zh-Hant].each do |locale|
            assert_equal 'zh-hant', Sinatra::R18n.normalize_locale(locale)
        end
    end

    def test_r18n_uses_the_normalized_translation
        translations = File.expand_path('../i18n', __dir__)
        expected = {
            'zh-CN' => 'zh-hans',
            'zh-SG' => 'zh-hans',
            'zh-TW' => 'zh-hant',
            'zh-HK' => 'zh-hant',
            'zh-MO' => 'zh-hant',
            'pt-BR' => 'pt-br'
        }

        expected.each do |browser_locale, application_locale|
            normalized = Sinatra::R18n.normalize_locale(browser_locale)
            i18n = ::R18n::I18n.new([normalized], translations)
            selected = Sinatra::R18n.normalize_locale(i18n.locale.code)
            assert_equal application_locale, selected
        end
    end

end
