json.extract! file_stat, :id, :username, :filename, :most_status, :least_status, :palindrome_status, :created_at, :updated_at
json.url file_stat_url(file_stat, format: :json)
