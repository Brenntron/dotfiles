class RunAttachTestWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform

    "success"
  end
end