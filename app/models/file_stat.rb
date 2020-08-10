class FileStat < ApplicationRecord
  before_save :set_user

  def set_user
    self.username = "Eric"
  end
end
