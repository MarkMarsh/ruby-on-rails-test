class FileStatsWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'file_stats'

  def perform(name, count)
    puts("doing something", name, count)
    if name == "throw"
      throw "fake error"
    end

    if name == "sleep"
      sleep(10*60)
    end
  end

end