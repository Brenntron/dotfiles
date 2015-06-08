class RunRuleTestWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform
    "success"
  end
end