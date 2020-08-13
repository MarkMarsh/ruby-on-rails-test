class ChangeProgress2 < ActiveRecord::Migration[6.0]
  def change
    change_column :file_stats, :progress, :string
  end
end
