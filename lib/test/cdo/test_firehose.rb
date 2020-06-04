require_relative '../test_helper'
require 'cdo/i18n_string_url_tracker'

class TestFirehose < Minitest::Test
  def stub_firehose
    @firehose_mock = mock
    FirehoseClient.instance.instance_variable_set(:@rack_env, :unit_test)
    FirehoseClient.instance.instance_variable_set(:@firehose, @firehose_mock)
  end

  def unstub_firehose
    FirehoseClient.instance.instance_variable_set(:@rack_env, :test)
    FirehoseClient.instance.instance_variable_set(:@firehose, nil)
  end

  def setup
    stub_firehose
  end

  def teardown
    unstub_firehose
  end

  def test_instance_not_null
    assert FirehoseClient.instance
  end

  def test_put_record_batch_given_test_environment_should_do_nothing
    data = {test_key: 'key', test_value: 'value'}
    FirehoseClient.instance.instance_variable_set(:@rack_env, :test)

    @firehose_mock.expects(:put_record_batch).never
    Honeybadger.expects(:notify).never

    FirehoseClient.instance.put_record_batch('TEST_STREAM_NAME', [data])
  end

  # The :test and :development should not make actual calls to AWS.
  def test_put_record_batch_given_no_records_should_do_nothing
    @firehose_mock.expects(:put_record_batch).never
    Honeybadger.expects(:notify).never

    FirehoseClient.instance.put_record_batch('TEST_STREAM_NAME', [])
  end

  def test_put_record_batch_given_one_record_should_send_in_expected_format
    data = {test_key: 'key', test_value: 'value'}

    @firehose_mock.expects(:put_record_batch).with do |params|
    end
    Honeybadger.expects(:notify).never

    FirehoseClient.instance.put_record_batch('TEST_STREAM_NAME', [data])
  end
end
