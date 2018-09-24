class WebcatReport::ComplaintEntryReport

  attr_reader :date_from, :date_to

  def initialize(date_from:, date_to:)
    @date_from = Date.iso8601(date_from)
    @date_to = Date.iso8601(date_to)
  end

  def each_entry
    ComplaintEntry.all.each do |entry|
      yield entry
    end
  end
end
