require 'fileutils'

class FileStatsWorker
  include FileStatsHelper
  include Sidekiq::Worker

  sidekiq_options queue: 'file_stats'

  def perform(filename, db_id)
    process_file(filename, db_id)
  end


end
