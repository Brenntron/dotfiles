class ServiceStatus < ApplicationRecord
  has_many :service_status_logs

  #SERVICE STATUS NAMES
  # RULEAPI:CATEGORY
  # RULEAPI:WEB_REPUTATION
  # RULEAPI:CATEGORY_PREFIX
  # RULEAPI:CATEGORY_HISTORY
  # RULEAPI:CLUSTER
  # RULEAPI:THREAT_CATEGORY
  # RULEAPI:WSA_STATUS
  # RULEAPI:RULEHIT
  # RULEAPI:COMPLAINT_RECORD

  def report_outage
    if self.exception_count < 0
      self.exception_count = 0
    end

    self.exception_count += 1
    self.save
  end

  def report_working

    if self.exception_count > 0
      self.exception_count -= 1
      self.save
    end

  end

  def current_status
    if self.exception_count < 3
      return "green"
    end
    if self.exception_count >= 3 && self.exception_count < 10
      return "yellow"
    end
    if self.exception_count >= 10
      return "red"
    end
  end

  def status_quick_details
    status_details = {}
    status_details[:current_exception_count] = self.exception_count
    status_details[:current_status] = self.current_status
    status_details[:last_exception] = self.last_exception
    status_details[:last_exception_timestamp] = self.last_exception_at

    status_details
  end

  def status_exception_details(limit = 100)
    logs = ServiceStatusLog.where(:service_status_id => self.id).order("created_on desc").limit(limit)

    logs
  end

  def log(log_data)
    if log_data[:type] == "outage"
      report_outage
    else
      report_working
    end

    if log_data[:exception].present?
      service_status_log = ServiceStatusLog.new
      service_status_log.service_status_id = self.id
      service_status_log.exception = log_data[:exception]
      service_status_log.exception_details = log_data[:exception_details] if log_data[:excepton_details].present?
      service_status_log.save
    end
  end

end
