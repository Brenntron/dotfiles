class WebcatReport::ResolutionReport
  class ResolutionCount
    include ActiveModel::Model
    attr_accessor :username, :fixed, :invalid, :unchanged, :duplicate
  end

  attr_reader :date_from, :date_to

  def initialize(date_from:, date_to:)
    @date_from = Date.iso8601(date_from)
    @date_to = Date.iso8601(date_to)
  end

  def each_engineer
    User.joins(:complaints)
        .where.not(complaints: {resolution: nil})
        .where(complaints: {complaint_closed_at: (@date_from..@date_to+1)})
        .group(:id).order(:cvs_username).each do |user|
      counts = Complaint.where(user_id: user.id, complaint_closed_at: (@date_from..@date_to+1)).group(:resolution).count
      yield ResolutionCount.new(username: user.cvs_username,
                                fixed: counts['FIXED'],
                                invalid: counts['INVALID'],
                                unchanged: counts['UNCHANGED'],
                                duplicate: counts['DUPLICATE'])
    end
  end
end
