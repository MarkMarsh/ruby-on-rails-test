class FileStatsWorker
  include Sidekiq::Worker

  def perform(name, count)
    puts("doing something", name, count)
    throw "fake error"
  end
end