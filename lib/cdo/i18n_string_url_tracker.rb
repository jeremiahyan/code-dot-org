require 'concurrent'
require 'cdo/firehose'

class I18nStringUrlTracker
  @@buffer = Concurrent::Set[]
  @@update_thread = nil
  UPDATE_THREAD_PERIOD = 4 #5 minutes

  # starts a worker thread which will periodically upload the recorded data.
  def self.create_update_worker_thread
    Thread.new do
      loop do
        sleep UPDATE_THREAD_PERIOD
        upload_data
      end
    end
  end

  # sends the buffered string:url association data to Firehose.
  def self.upload_data
    # upload the data to Firehose.
    FirehoseClient.instance.put_record_batch(I18N_STRING_TRACKING_EVENTS_STREAM_NAME, @@buffer)
    @@buffer.clear
  end

  def self.log_association(string_key, url)
    return unless string_key && url
    # create an update_thread if there isn't one already.
    @@update_thread = create_update_worker_thread unless @@update_thread && @@update_thread.alive?
    # record the string : url association.
    @@buffer.add({url: url, string_key: string_key})
  end
end
