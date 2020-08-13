class FileStat < ApplicationRecord
  include FileStatsHelper

  before_save :do_before_save

  def do_before_save()
    set_defaults()
  end  
  
  def set_defaults
    self.username = get_current_user()
    self.status = "Queued"
  end

end
