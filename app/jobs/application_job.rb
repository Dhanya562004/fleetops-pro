class ApplicationJob < ActiveJob::Base
  retry_on ActiveRecord::Deadlocked, wait: 2.seconds, attempts: 5
end
