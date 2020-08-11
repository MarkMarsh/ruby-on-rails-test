require 'sidekiq/api'

module FileStatsHelper

  def get_job_status(job_id)
    return("Finished")
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

    # ps = Sidekiq::ProcessSet.new
    # ps.size # => 2
    # ps.each do |process|
    #   p process['busy']     # => 3
    #   p process['hostname'] # => 'myhost.local'
    #   p process['pid']      # => 16131
    # end

    return(queue.size)
  end    

end
