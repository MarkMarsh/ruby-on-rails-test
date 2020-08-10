class CreateFileStats < ActiveRecord::Migration[6.0]
  def change
    create_table :file_stats do |t|
      t.string :username, null: false
      t.text :filename, null: false
      t.boolean :most_status, null: false, default: false
      t.boolean :least_status, null: false, default: false
      t.boolean :palindrome_status, null: false, default: false

      t.timestamps
    end
  end
end
