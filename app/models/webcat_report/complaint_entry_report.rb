class WebcatReport::ComplaintEntryReport

  attr_reader :date_from, :date_to, :customer_name

  def initialize(date_from:, date_to:, customer_name:)
    @date_from = Date.iso8601(date_from)
    @date_to = Date.iso8601(date_to)
    @customer_name = customer_name
  end

  def each_entry
    entries = ComplaintEntry.where(created_at: (@date_from..@date_to))

    if @customer_name.present?
      entries =
          entries.joins(complaint: {customer: :company})
              .where("customers.name like :pattern or companies.name like :pattern", pattern: "%#{@customer_name}%")
    end

    entries.each do |entry|
      yield entry
    end
  end
end
