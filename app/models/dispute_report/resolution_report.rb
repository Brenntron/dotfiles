class DisputeReport::ResolutionReport
  class PerResolution
    attr_reader :date_from, :date_to, :distribution
    def initialize(date_from_given, date_to_given)
      @date_from = date_from_given
      @date_to = date_to_given
      @distribution = DisputeEntry.where(case_resolved_at: (date_from..date_to+1)).group(:resolution).count
    end

    def total
      distribution.values.sum
    end

    def each_resolution
      %w{UNCHANGED FIXED\ FN FIXED\ FP}.each do |resolution|
        count = distribution[resolution]
        percent = (0 < total && count) ? 100.0 * count / total : nil
        yield resolution, percent && '%.2f' % percent, count
      end
    end
  end

  class PerEngineer
    attr_reader :date_from, :date_to, :distribution
    def initialize(date_from_given, date_to_given)
      @date_from = date_from_given
      @date_to = date_to_given
      @distribution =
        DisputeEntry.joins(dispute: :user)
                    .where(case_resolved_at: (date_from..date_to+1))
                    .group('users.cvs_username').count
    end

    def total
      distribution.values.sum
    end

    def engineer_count
      distribution.count
    end

    def each_resolution
      distribution.keys.each do |username|
        count = distribution[username]
        percent = (0 < total && count) ? 100.0 * count / total : nil
        yield username, percent && '%.2f' % percent, count
      end
    end
  end

  class PerCustomer
    attr_reader :date_from, :date_to, :distribution
    def initialize(date_from_given, date_to_given)
      @date_from = date_from_given
      @date_to = date_to_given
      @distribution =
        DisputeEntry.joins(dispute: :customer)
                    .where(case_resolved_at: (date_from..date_to+1))
                    .group('customers.id').count
    end

    def total
      distribution.values.sum
    end

    def customer_count
      distribution.count
    end

    def each_resolution
      distribution.keys.each do |customer_id|
        customer = Customer.find(customer_id)
        count = distribution[customer_id]
        percent = (0 < total && count) ? 100.0 * count / total : nil
        yield customer, percent && '%.2f' % percent, count
      end
    end
  end

  attr_reader :date_from, :date_to, :period

  def initialize(date_from:, date_to:, period:)
    @date_from = Date.iso8601(date_from)
    @date_to = Date.iso8601(date_to)
    @period = period
  end

  def each_date
    (date_from..date_to).reverse_each do |date|
      yield date, date
    end
  end

  def prior_monday(date)
    if 0 == date.wday
      date - 6
    else
      date - date.wday + 1
    end
  end

  def coming_sunday(date)
    if 0 == date.wday
      date
    else
      date - date.wday + 7
    end
  end

  def each_week
    (prior_monday(date_from)..coming_sunday(date_to)).step(7).reverse_each do |date|
      yield date, date + 6
    end
  end

  def each_month
    year_curr = date_to.year
    month_curr = date_to.month
    if 12 <= month_curr
      year_prev = year_curr + 1
      month_prev = 1
    else
      year_prev = year_curr
      month_prev = month_curr + 1
    end
    year_cutoff = date_from.year
    month_cutoff = date_from.month
    while (year_curr > year_cutoff) || (month_curr > month_cutoff)
      yield Date.civil(year_curr, month_curr, 1), Date.civil(year_prev, month_prev, 1)-1
      year_prev = year_curr
      month_prev = month_curr

      month_curr -= 1
      if 0 >= month_curr
        month_curr = 12
        year_curr -= 1
      end
    end
  end

  def each_period(&block)
    case period
      when 'Monthly'
        each_month(&block)
      when 'Weekly'
        each_week(&block)
      else
        each_date(&block)
    end
  end

  def each_per_resolution
    each_period do |date_from, date_to|
      yield PerResolution.new(date_from, date_to)
    end
  end

  def each_per_engineer
    each_period do |date_from, date_to|
      yield PerEngineer.new(date_from, date_to)
    end
  end

  def each_per_customer
    each_period do |date_from, date_to|
      yield PerCustomer.new(date_from, date_to)
    end
  end
end
