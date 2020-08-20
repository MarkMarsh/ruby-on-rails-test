require 'sidekiq/api'

module FileStatsHelper
 
  class CancelledException < StandardError
  end

  def get_results_base_dir()
    return('/tmp/file_stats/results/')
  end
  
  def get_results_dir(db_id)
    dir = "#{get_results_base_dir()}#{db_id}/"
    return dir
  end
  
  # stub for integration with authentication
  def get_current_user()  
    return "Eric"
  end

  # needs improving to search all queues and also to kill jobs that are processing
  def delete_job(job_id)
    ################################## TODO cancel_job(job_id)   # cancel the job if it's currently executing
    Sidekiq::Queue.new("file_stats").each do |job|
      if job.jid == job_id
        job.delete 
      end
    end
  end

  def delete_results(db_id)
    dir = "#{get_results_base_dir()}#{db_id}/"
    FileUtils.rm_rf(dir)
  end

  # to report how many jobs are queued
  def get_queue_length()
    return(Sidekiq::Queue.new("file_stats").size)
  end

  # to report how many jobs are running
  def get_running_jobs()
    running = 0
    Sidekiq::ProcessSet.new.each do |process|
      running += process['busy']   
    end
    return(running)
  end    

  # set / test a pause semaphore
  def pause_job(job_id)
    Sidekiq.redis {|c| c.setex("pause-#{job_id}", 86400, 1) }
  end

  def unpause_job(job_id)
    Sidekiq.redis {|c| c.del("pause-#{job_id}", 86400, 1) }
  end

  def is_job_paused?(job_id)
    x = Sidekiq.redis {|c| c.exists?("pause-#{job_id}") }
    return x
  end

  # set / test a cancel semaphore
  # 10 minute timeout should be plenty
  def cancel_job(job_id)
    x = Sidekiq.redis {|c| c.setex("cancel-#{job_id}", 600, 1) }   
    return x
  end

  def is_job_cancelled?(job_id)
    x = Sidekiq.redis {|c| c.exists?("cancel-#{job_id}") }
    return x
  end

  # check whether processing should be cancelled
  def check_cancelled(file_stat)
    if is_job_cancelled?(file_stat.job_id)
      raise CancelledException.new, 'Cancelled'
    end
  end

  # check whether processing should be paused
  def check_paused(file_stat)
    if file_stat.job_id.length() < 6
      raise "Bad Job ID in check_paused()"
    end
    if !is_job_paused?(file_stat.job_id)
      return
    end
    prev_progress = file_stat.progress
    file_stat.update(progress: 'Paused')
    loop do
      check_cancelled(file_stat)
      sleep 5
      break if !is_job_paused?(file_stat.job_id)
    end 
    file_stat.update(progress: prev_progress)
  end

  # maybe better done better through Redis or possibly actionCable
  def update_progress(progress, file_stat)
    logger.debug("Setting Progress #{progress} for ID #{file_stat._id}")
    file_stat.update(progress: progress)
  end

  def process_file(filename, db_id)
    file_stat = nil
    begin
      file_stat = FileStat.find(db_id)
      if file_stat == nil
        throw "Failed to find record for FileStat #{db_id}"
      end
      file_stat.update(status: 'Processing', status_message: '')

      if Rails.env.development? && filename == "throw"          # for testing error handling
        throw "forced error"
      elsif Rails.env.development? && filename[0,5] == "sleep"  # simulate processing a file without high system load
        len = 10*60 # default sleep length
        s = filename.split(' ')
        if s.size > 1
          logger.debug "sleeping for " + s[1] + "seconds"
          len = s[1].to_i()
        else
          logger.debug "sleeping for ten minutes"
        end
        (1..len).step(5) do |i|
          check_cancelled(file_stat)
          check_paused(file_stat)
          #logger.debug "sleep step #{i} of #{len}"
          update_progress("#{(((i * 100.0) / len) + 0.5).to_i()}%", file_stat)
          sleep(5)
        end
        update_progress("", file_stat)
      else                            # process a file
        words = Hash.new(0) # for most and least popular words
        pali = Hash.new(0) # for palindromic words
        flen = File.size(filename)
        freq = [flen / 100, 1000].max # update every 1% progress or 1000 records whichever is the greater
        logger.debug "processing file: #{filename} length #{flen} freq #{freq}"
        charnum = 0
        # ToDo: 
        s = File.open(filename,'r') do |s|
          word = ''
          s.each_char do |chr|
            # check_cancelled and check_paused could be checked at a different frequency
            if charnum % freq == 0
              check_cancelled(file_stat)
              update_progress("#{(((charnum * 100.0) / flen) + 0.5).to_i()}%", file_stat)
              check_paused(file_stat)
            end
            charnum += 1
            c = chr.downcase
            o = c.ord
            if((o >= 97 && o <= 122) || (o >= 48 && o <= 57) || o == 45)  # check if number / letter / hyphen
              word.concat(c)
            else
              if word.size > 0
                words[word] += 1
                if word.size > 1 && word == word.reverse
                  pali[word] += 1
                end
                word = ''
              end
            end
          end
        end
        # write the result files
        FileUtils.mkdir_p(get_results_dir(db_id))
        # dump the top 10 words by frequency desc
        most = File.new(get_results_dir(db_id) + 'most.txt', 'w')
        n = 0
        words.sort_by{|k, v| -v}.each do |row|
          #logger.debug "#{row[0]} = #{row[1]}"
          most.write("#{row[0]},#{row[1]}\n")
          if (n += 1) >= 10
            break
          end
        end
        most.close()
        # dump all the words with the lowest frequency
        least = File.new(get_results_dir(db_id) + 'least.txt', 'w')
        min = -1
        words.sort_by{|k, v| v}.each do |row|
          if min == -1
            min = row[1]
          end
          if row[1] != min
            break
          end
          #logger.debug "#{row[0]} = #{row[1]}"
          least.write("#{row[0]},#{row[1]}\n")
        end
        least.close()
        # dump all the palindromes but sort desc
        palifile = File.new(get_results_dir(db_id) + 'palindromes.txt', 'w')
        pali.sort_by{|k, v| -v}.each do |row|
          #logger.debug "#{row[0]} = #{row[1]}"
          palifile.write("#{row[0]},#{row[1]}\n")
        end
        palifile.close()
        update_progress("", file_stat)
      end
    rescue CancelledException => c
      file_stat.update(status: 'Cancelled', status_message: '')
      return true 
    rescue StandardError => e
      file_stat.update(status: 'Processing error', status_message: e.message)
      raise
    end
    file_stat.update(status: 'Processed', status_message: '')
    return true
  end

end
