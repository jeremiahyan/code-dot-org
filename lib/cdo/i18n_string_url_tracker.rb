require 'concurrent'
require 'cdo/firehose'

class I18nStringUrlTracker
  include Singleton
  # the time (seconds) between each upload.
  UPDATE_THREAD_PERIOD = 300 #5 minutes
  # random variance for each loop.
  UPDATE_THREAD_PERIOD_JITTER = 60 # 1 minute

  def initialize
    # store a buffer of data to send so updates can be batched together.
    @buffer = Concurrent::Set[]
    # a thread which keeps looping and sending batch updates of string_key:url associations.
    @update_thread = nil
  end

  # Records the given string_key and URL so we can analyze later what strings are present on what pages.
  # @param string_key [String] The key used to review the translated string from our i18n system.
  # @param url [String] The url which required the translation of the given string_key.
  def log_association(string_key, url)
    return unless string_key && url
    # create an update_thread if there isn't one already.
    @update_thread = create_update_worker_thread unless alive?
    # record the string : url association.
    @buffer.add({url: url, string_key: string_key})
  end

  # starts a worker thread which will periodically upload the recorded data.
  def create_update_worker_thread
    Thread.new do
      loop do
        # Jitter adds a little randomness to how long the sleep is. This makes it so we can avoid all the upload worker
        # threads starting at the same time.
        jitter = rand(UPDATE_THREAD_PERIOD_JITTER) - (UPDATE_THREAD_PERIOD_JITTER / 2)
        update_thread_period = UPDATE_THREAD_PERIOD + jitter
        sleep update_thread_period
        flush_data
      end
    end
  end

  # Sends the buffered string:url association data to Firehose.
  # This method is only meant to be called for testing purposes.
  def flush_data
    # upload the data to Firehose.
    FirehoseClient.instance.put_record_batch(I18N_STRING_TRACKING_EVENTS_STREAM_NAME, @buffer) unless @buffer.empty?
    # the data has been uploaded; therefore it not longer needs to be buffered.
    @buffer.clear
  end

  # returns true if the tracker has alive worker threads which are periodically uploading data.
  def alive?
    !@update_thread.nil? && @update_thread.alive?
  end

  # Used to stop any worker threads which were started and clear buffered data.
  def kill
    if alive?
      @update_thread.kill
      @update_thread = nil
    end
    @buffer.clear
  end
end
