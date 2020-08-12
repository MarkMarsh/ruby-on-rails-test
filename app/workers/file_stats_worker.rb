require 'fileutils'

class FileStatsWorker
  include FileStatsHelper
  include Sidekiq::Worker
  sidekiq_options queue: 'file_stats'

  def perform(filename, results_base)
    results_dir = results_base  + jid + '/'
    process_file(filename, results_dir)
  end

end