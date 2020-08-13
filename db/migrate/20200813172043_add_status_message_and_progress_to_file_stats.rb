class AddStatusMessageAndProgressToFileStats < ActiveRecord::Migration[6.0]
  def change
    add_column :file_stats, :status_message, :string
    add_column :file_stats, :progress, :integer
  end
end
