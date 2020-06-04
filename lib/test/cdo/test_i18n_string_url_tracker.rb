require_relative '../test_helper'
require 'cdo/i18n_string_url_tracker'

class TestI18nStringUrlTracker < Minitest::Test
  # We don't want to make actual calls to the AWS Firehose apis, so stub it and verify we are trying to send the right
  # data.
  def stub_firehose
    FirehoseClient.instance.stubs(:put_record_batch).with do |stream_name, args|
      # Capture the data we try to send to firehose so we can verify it is what we expect.
      @firehose_stream_name = stream_name
      @firehose_records = args.dup
      true
    end
  end

  def unstub_firehose
    FirehoseClient.instance.unstub(:put_record_batch)
  end

  def setup
    super
    stub_firehose
    I18nStringUrlTracker.instance.kill
  end

  def teardown
    super
    unstub_firehose
    I18nStringUrlTracker.instance.kill
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
    I18nStringUrlTracker.instance.flush_data
    assert_nil(@firehose_stream_name)
  end

  def test_upload_data_given_data_should_call_firehose
    # Disable the worker thread from getting created since we will skip testing that.
    I18nStringUrlTracker.instance.stubs(:create_update_worker_thread)
    test_record = {string_key: 'string.key', url: 'http://some.url.com/'}
    I18nStringUrlTracker.instance.log_association(test_record[:string_key], test_record[:url])
    I18nStringUrlTracker.instance.flush_data
    assert_equal(I18N_STRING_TRACKING_EVENTS_STREAM_NAME, @firehose_stream_name)
    assert(@firehose_records.include?(test_record))
  end

  def test_upload_data_given_duplicate_data_should_only_record_one_data
    # Disable the worker thread from getting created since we will skip testing that.
    I18nStringUrlTracker.instance.stubs(:create_update_worker_thread)
    test_record = {string_key: 'string.key', url: 'http://some.url.com/'}
    I18nStringUrlTracker.instance.log_association(test_record[:string_key], test_record[:url])
    I18nStringUrlTracker.instance.log_association(test_record[:string_key], test_record[:url])
    I18nStringUrlTracker.instance.flush_data
    assert_equal(1, @firehose_records.size)
  end
end
