class FileStat
  include Mongoid::Document
  include FileStatsHelper

#  field :username, type: String, default: get_current_user()
  field :username, type: String, default: "Eric"
  field :filename, type: String
  field :job_id, type: String
  field :status, type: String, default: "Queued"
  field :status_message, type: String, default: ""
  field :progress, type: String, default: ""
end
