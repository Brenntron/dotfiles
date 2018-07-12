class DisputeReport::ResolutionReport
  class PerResolution
    attr_reader :date, :distribution
    def initialize(date)
      @date = date
      @distribution = DisputeEntry.where(case_resolved_at: (date..date+1)).group(:resolution).count
    end

    def total
      distribution.values.sum
    end

    def each_resolution
      %w{UNCHANGED FIXED\ FN FIXED\ FD}.each do |resolution|
        count = distribution[resolution]
        percent = (0 < total && count) ? 100.0 * count / total : nil
        yield resolution, percent && '%.2f' % percent, count
      end
    end
  end

  class PerEngineer
    attr_reader :date, :distribution
    def initialize(date)
      @date = date
      @distribution =
        DisputeEntry.joins(:dispute).joins(dispute: :user)
                    .where(case_resolved_at: (date..date+1))
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

  attr_reader :date_from, :date_to

  def initialize(date_from:, date_to:)
    @date_from = Date.iso8601(date_from)
    @date_to = Date.iso8601(date_to)
  end

  def each_per_resolution
    (date_from..date_to).reverse_each do |date|
      yield PerResolution.new(date)
    end
  end

  def each_per_engineer
    (date_from..date_to).reverse_each do |date|
      yield PerEngineer.new(date)
    end
  end
end
