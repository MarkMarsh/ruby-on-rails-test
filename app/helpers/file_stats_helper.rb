require 'sidekiq/api'

module FileStatsHelper

  def get_results_base_dir()
    return('/tmp/file_stats/results/')
  end
  
  def get_results_dir(dbid)
    return("#{get_results_base_dir()}/#{dbid.to_s()}/")
  end
  
  # stub for integration with authentication
  def get_current_user()  
    return "Eric"
  end

  # needs improving to search all queues and also to kill jobs that are processing
  def delete_job(job_id)
    Sidekiq::Queue.new("file_stats").each do |job|
      if job.jid == job_id
        job.delete 
      end
    end
  end

  def delete_results(dbid)
    FileUtils.rm_rf("#{get_results_base_dir()}#{dbid.to_s()}/")
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

  def update_status(status, message, dbid)
    # couldn't make updates to a model object work in sidekiq worker
    logger.debug("Setting Status #{status} Message #{message} for ID #{dbid}")

    fs = FileStat.find(dbid)
    fs.update(status: status, status_message: message)
  end

  # probably done better through Redis
  def update_progress(progress, dbid)
    # couldn't make updates to a model object work in sidekiq worker
    logger.debug("Setting Progress #{progress} for ID #{dbid}")

    fs = FileStat.find(dbid)
    fs.update(progress: progress)
  end

  # set / test a pause semaphore - use Redis
  def pause_job(job_id)
  end

  def is_job_paused(job_id)
  end

  # set / test a cancel semaphore - use Redis
  def cancel_job(job_id)
  end

  def is_job_paused(job_id)
  end

  def process_file(filename, dbid)
    update_status('Processing', '', dbid)
    begin
      if filename == "throw"          # test error condition (blank filename works as well)
        if Rails.env.development?
          throw "forced error"
        end
      elsif filename[0,5] == "sleep"  # simulate processing a file without high system load
        if Rails.env.development?
          len = 10*60 # default sleep length
          s = filename.split(' ')
          if s.size > 1
            logger.debug "sleeping for " + s[1] + "seconds"
            len = s[1].to_i()
          else
            logger.debug "sleeping for ten minutes"
          end
          (1..len).step(5) do |i|
            logger.debug "sleep step #{i} of #{len}"
            update_progress("#{(((i * 100.0) / len) + 0.5).to_i()}%", dbid)
            sleep(5)
          end
          update_progress("", dbid)
        end
      else                            # process a file
        FileUtils.mkdir_p(get_results_dir(dbid))
        words = Hash.new(0) # for most and least popular words
        pali = Hash.new(0) # for palindromic words
        flen = File.size(filename)
        freq = flen / 100 # update every 1% progress
        logger.debug "processing file: #{filename} length #{flen} freq #{freq}"
        charnum = 0
        s = File.open(filename,'r') do |s|
          word = ''
          s.each_char do |chr|
            if charnum % freq == 0
              update_progress("#{(((charnum * 100.0) / flen) + 0.5).to_i()}%", dbid)
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
        # dump the top 10 words by frequency desc
        most = File.new(get_results_dir(dbid) + 'most.txt', 'w')
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
        least = File.new(get_results_dir(dbid) + 'least.txt', 'w')
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
        palifile = File.new(get_results_dir(dbid) + 'palindromes.txt', 'w')
        pali.sort_by{|k, v| -v}.each do |row|
          #logger.debug "#{row[0]} = #{row[1]}"
          palifile.write("#{row[0]},#{row[1]}\n")
        end
        palifile.close()
        update_progress("", dbid)
      end
    rescue StandardError => e
      update_status("Processing error", e.message, dbid)  
      raise
    end
    update_status('Processed', '', dbid)
    return true
  end

end
