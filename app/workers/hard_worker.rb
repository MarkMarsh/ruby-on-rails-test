class HardWorker
  include Sidekiq::Worker

  def perform(name, count)
    puts("doing something", name, count)
  end
end