class AddJobIDandChangeStatus < ActiveRecord::Migration[6.0]
  def change
    remove_column :file_stats, :most_status
    remove_column :file_stats, :least_status
    remove_column :file_stats, :palindrome_status
    add_column :file_stats, :job_id, :string
    add_column :file_stats, :status, :string
  end
end
