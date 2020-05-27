require_relative '../test_helper'
require 'cdo/i18n_string_url_tracker'

class TestI18nStringUrlTracker < Minitest::Test
  def setup
    super
  end

  def test_instance
    assert I18nStringUrlTracker.instance
  end

  def test_instance3
    assert I18nStringUrlTracker.instance
  end
end
