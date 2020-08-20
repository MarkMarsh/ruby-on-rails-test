require 'fileutils'

class FileStatsWorker
  include FileStatsHelper
  include Sidekiq::Worker

  sidekiq_options queue: 'file_stats'

  def perform(filename, dbid)
    process_file(filename, dbid)
  end


end