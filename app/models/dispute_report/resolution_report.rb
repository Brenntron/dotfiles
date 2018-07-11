class DisputeReport::ResolutionReport
  class PerResolution
    attr_reader :date
    def initialize(date)
      @date = date
    end

    def each_resolution
      %w{UNCHANGED FIXED\ FN FIXED\ FD}.each do |resolution|
        yield resolution, 43.21, 22
      end
    end

    def total
      66
    end
  end

  class PerEngineer
    attr_reader :date
    def initialize(date)
      @date = date
    end

    def each_resolution
      %w{matfeket obaig aheo auto_vtu}.each do |resolution|
        yield resolution, 43.21, 22
      end
    end

    def engineer_count
      4
    end

    def total
      66
    end
  end

  attr_reader :date_from, :date_to

  def initialize(date_from:, date_to:)
    @date_from = Date.iso8601(date_from)
    @date_to = Date.iso8601(date_to)
  end

  def each_per_resolution
    (date_from..date_to).each do |date|
      yield PerResolution.new(date)
    end
  end

  def each_per_engineer
    (date_from..date_to).each do |date|
      yield PerEngineer.new(date)
    end
  end
end
