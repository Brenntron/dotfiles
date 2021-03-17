Delayed::Worker.raise_signal_exceptions = :term
Delayed::Worker.sleep_delay = 45
Delayed::Worker.max_attempts = 3
Delayed::Worker.max_run_time = 10.minutes
Delayed::Worker.read_ahead = 5
Delayed::Worker.logger = Logger.new(File.join(Rails.root, 'log', 'dj.log'))
