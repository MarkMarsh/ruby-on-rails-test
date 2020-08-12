class FileStat < ApplicationRecord
  include FileStatsHelper
  before_save :do_before_save

  def do_before_save()
    set_user()
    set_defaults()
    enqueue_file()
  end

  def set_user
    self.username = "Eric"
  end

  def set_defaults
    self.status = "Queued"
  end

  def enqueue_file
    logger.debug "Queued " + self.filename
    jid = FileStatsWorker.perform_async(self.filename, get_results_base_dir()) 
    logger.debug "Job ID " + jid
    self.job_id = jid
  end
end
