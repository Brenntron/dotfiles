Delayed::Worker.raise_signal_exceptions = :term
Delayed::Worker.sleep_delay = 45
Delayed::Worker.max_attempts = 12
Delayed::Worker.max_run_time = 5.minutes
Delayed::Worker.read_ahead = 5
Delayed::Worker.logger = Logger.new(File.join(Rails.root, 'log', 'dj.log'))
