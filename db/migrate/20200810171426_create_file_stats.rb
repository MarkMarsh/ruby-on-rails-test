class CreateFileStats < ActiveRecord::Migration[6.0]
  def change
    create_table :file_stats do |t|
      t.string :username
      t.text :filename
      t.boolean :most_status
      t.boolean :least_status
      t.boolean :palindrome_status

      t.timestamps
    end
  end
end
