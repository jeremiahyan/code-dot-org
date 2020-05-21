require 'concurrent'
require 'cdo/firehose'

class I18nStringUrlTracker
  include Singleton

  # store a buffer of data to send so updates can be batched together.
  @buffer = Concurrent::Set[]
  # a thread which keeps looping and sending batch updates of string_key:url associations.
  @update_thread = nil
  # the time (seconds) between each upload.
  UPDATE_THREAD_PERIOD = 300 #5 minutes

  # Records the given string_key and URL so we can analyze later what strings are present on what pages.
  # @param string_key [string] The key used to review the translated string from our i18n system.
  # @param url [string] The url which required the translation of the given string_key.
  def log_association(string_key, url)
    return unless string_key && url
    # create an update_thread if there isn't one already.
    @update_thread = create_update_worker_thread unless @update_thread && @update_thread.alive?
    # record the string : url association.
    @buffer.add({url: url, string_key: string_key})
  end

  private

  # starts a worker thread which will periodically upload the recorded data.
  def create_update_worker_thread
    Thread.new do
      loop do
        sleep UPDATE_THREAD_PERIOD
        upload_data
      end
    end
  end

  # sends the buffered string:url association data to Firehose.
  def upload_data
    # upload the data to Firehose.
    FirehoseClient.instance.put_record_batch(I18N_STRING_TRACKING_EVENTS_STREAM_NAME, @buffer)
    # the data has been uploaded; therefore it not longer needs to be buffered.
    @buffer.clear
  end
end
