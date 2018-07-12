class WebcatReport::ResolutionReport
  class ResolutionCount
    include ActiveModel::Model
    attr_accessor :username, :fixed, :invalid, :unchanged, :duplicate,
                  :eng_avg, :eng_max, :dept_avg, :dept_max
  end

  attr_reader :date_from, :date_to

  def initialize(date_from:, date_to:)
    @date_from = Date.iso8601(date_from)
    @date_to = Date.iso8601(date_to)
  end

  def each_engineer

    times_select_phrase =
        'avg(time_to_sec(timediff( complaint_closed_at, complaint_assigned_at ))) as eng_avg, ' +
            'max( time_to_sec( timediff( complaint_closed_at, complaint_assigned_at ))) as eng_max, ' +
            'avg(time_to_sec(timediff( complaint_closed_at, created_at ))) as dept_avg, ' +
            'max( time_to_sec( timediff( complaint_closed_at, created_at ))) as dept_max'

    counts = Complaint.where(complaint_closed_at: (@date_from..@date_to+1)).group(:resolution).count

    times =
        Complaint.where.not(complaints: {resolution: nil})
            .where(complaints: {complaint_closed_at: (@date_from..@date_to+1)})
            .select(times_select_phrase).first

    yield ResolutionCount.new(username: 'TOTAL',
                              fixed: counts[Complaint::RESOLUTION_FIXED],
                              invalid: counts[Complaint::RESOLUTION_INVALID],
                              unchanged: counts[Complaint::RESOLUTION_UNCHANGED],
                              duplicate: counts[Complaint::RESOLUTION_DUPLICATE],
                              eng_avg: times.eng_avg, eng_max: times.eng_max,
                              dept_avg: times.dept_avg, dept_max: times.dept_max)


    User.joins(:complaints)
        .where.not(complaints: {resolution: nil})
        .where(complaints: {complaint_closed_at: (@date_from..@date_to+1)})
        .group(:id).order(:cvs_username).each do |user|

      counts =
        Complaint.where(user_id: user.id, complaint_closed_at: (@date_from..@date_to+1)).group(:resolution).count

      times =
        Complaint.where.not(complaints: {resolution: nil})
          .where(user_id: user.id, complaints: {complaint_closed_at: (@date_from..@date_to+1)})
          .select(times_select_phrase).first

      yield ResolutionCount.new(username: user.cvs_username,
                                fixed: counts[Complaint::RESOLUTION_FIXED],
                                invalid: counts[Complaint::RESOLUTION_INVALID],
                                unchanged: counts[Complaint::RESOLUTION_UNCHANGED],
                                duplicate: counts[Complaint::RESOLUTION_DUPLICATE],
                                eng_avg: times.eng_avg, eng_max: times.eng_max,
                                dept_avg: times.dept_avg, dept_max: times.dept_max)
    end
  end
end
