require_relative '../test_helper'
require 'cdo/i18n_string_url_tracker'

class TestI18nStringUrlTracker < Minitest::Test
  def stub_firehose
    FirehoseClient.instance.stubs(:put_record).with do |stream_name, args|
      @firehose_stream_name = stream_name
      @firehose_record = args
      true
    end
  end

  def setup
    super
    stub_firehose
  end

  def test_instance_not_empty
    assert I18nStringUrlTracker.instance
  end

  def test_alive_given_no_data_should_be_false
    # The tracker should only be started after it has been given some data.
    assert_equal false, I18nStringUrlTracker.instance.alive?
  end

  def test_alive_given_data_should_be_true
    I18nStringUrlTracker.instance.log_association('string.key', 'http://some.url.com/')
    # The tracker should only be started after it has been given some data.
    assert_equal true, I18nStringUrlTracker.instance.alive?
  end

  def test_upload_data_given_no_data_should_not_call_firehose
    I18nStringUrlTracker.instance.upload_data
    assert_equal(nil, @firehose_stream_name)
  end

  def test_upload_data_given_data_should_call_firehose
    I18nStringUrlTracker.ini
    I18nStringUrlTracker.instance.upload_data
    assert_equal(nil, @firehose_stream_name)
  end
end
