class FileStat < ApplicationRecord
  before_save :set_user
  after_save :process_file

  def set_user
    self.username = "Eric"
  end

  def process_file
    logger.debug "Processing " + self.filename
    FileStatsWorker.perform_async(self.filename, 5) 
  end
end
