require 'sidekiq/api'

module FileStatsHelper

  def get_results_base_dir()
    return('/tmp/file_stats/results/')
  end

  def delete_job(job_id)
    Sidekiq::Queue.new("file_stats").each do |job|
      if job.jid == job_id
        job.delete 
      end
    end
  end

  def get_queue_length()
    return(Sidekiq::Queue.new("file_stats").size)
  end

  def dump_job_status()

    queue = Sidekiq::Queue.new("file_stats")
    queue.each do |job|
      p job.jid
      if job.jid == "8474c114a6445169fd2fd2fa"
        job.delete 
      end
    end

    ps = Sidekiq::ProcessSet.new
    ps.size # => 2
    ps.each do |process|
      p process['busy']     # => 3
      p process['hostname'] # => 'myhost.local'
      p process['pid']      # => 16131
    end

    j = Sidekiq::Queue.new("file_stats").find_job('f6e816407690649b226b7b75')

    return(queue.size)
  end    

  def process_file(filename, results_base)
    results_dir = results_base
    logger.warn("processing file: " + filename + ' results_dir: ' + results_dir)
    if filename == "throw"
      throw "fake error"
    elsif filename[0,5] == "sleep"
      s = filename.split(' ')
      if s.size > 1
        logger.warn "sleeping for " + s[1] + "seconds"
        sleep(s[1].to_i())
      else
        logger.warn "sleeping for ten minutes"
        sleep(10*60)
      end
    else  # process a file
      logger.warn "processing file: " + filename
      FileUtils.mkdir_p(results_dir)
      words = Hash.new(0) # for most and least popular words
      pali = Hash.new(0) # for palindromic words
      s = File.open(filename,'r') do |s|
        word = ''
        s.each_char do |chr|
          c = chr.downcase
          o = c.ord
          if((o >= 97 && o <= 122) || (o >= 48 && o <= 57) || o == 45)  # check if number / letter / hyphen
            word.concat(c)
          else
            if word.size > 0
              words[word] += 1
              if word == word.reverse
                pali[word] += 1
              end
              word = ''
            end
          end
        end
      end
      # write the result files
      # dump the top 10 words by frequency desc
      most = File.new(results_dir + 'most.txt', 'w')
      n = 0
      words.sort_by{|k, v| -v}.each do |row|
        #logger.warn "#{row[0]} = #{row[1]}"
        most.write("#{row[0]} = #{row[1]}\n")
        if (n += 1) >= 10
          break
        end
      end
      most.close()
      # dump all the words with the lowest frequency
      least = File.new(results_dir + 'least.txt', 'w')
      min = -1
      words.sort_by{|k, v| v}.each do |row|
        if min == -1
          min = row[1]
        end
        if row[1] != min
          break
        end
        #logger.warn "#{row[0]} = #{row[1]}"
        least.write("#{row[0]} = #{row[1]}\n")
      end
      least.close()
      # dump all the palindromes but sort desc
      palifile = File.new(results_dir + 'palindromes.txt', 'w')
      pali.sort_by{|k, v| -v}.each do |row|
        #logger.warn "#{row[0]} = #{row[1]}"
        palifile.write("#{row[0]} = #{row[1]}\n")
      end
      palifile.close()
    end
  return true
  end
end
