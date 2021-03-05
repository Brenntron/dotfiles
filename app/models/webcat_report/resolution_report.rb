class WebcatReport::ResolutionReport
  class ResolutionCount
    include ActiveModel::Model
    attr_accessor :username, :pending, :fixed, :invalid, :unchanged, :duplicate,
                  :eng_avg, :eng_max, :dept_avg, :dept_max
  end

  attr_reader :date_from, :date_to

  def initialize(date_from:, date_to:)
    @date_from = Date.iso8601(date_from)
    @date_to = Date.iso8601(date_to)
  end

  def each_engineer

    times_select_phrase =
        'avg(time_to_sec(timediff( case_resolved_at, case_assigned_at ))) as eng_avg, ' +
            'max( time_to_sec( timediff( case_resolved_at, case_assigned_at ))) as eng_max, ' +
            'avg(time_to_sec(timediff( case_resolved_at, created_at ))) as dept_avg, ' +
            'max( time_to_sec( timediff( case_resolved_at, created_at ))) as dept_max'

    counts = ComplaintEntryCredit.where(created_at: (@date_from..@date_to+1)).group(:credit).count

    times =
        ComplaintEntry.where.not(resolution: nil)
            .where(case_resolved_at: (@date_from..@date_to+1))
            .select(times_select_phrase).first

    yield ResolutionCount.new(username: 'TOTAL',
                              pending: counts[ComplaintEntryCredit::PENDING],
                              fixed: counts[ComplaintEntryCredit::FIXED],
                              invalid: counts[ComplaintEntryCredit::INVALID],
                              unchanged: counts[ComplaintEntryCredit::UNCHANGED],
                              duplicate: counts[ComplaintEntryCredit::DUPLICATE],
                              eng_avg: times.eng_avg, eng_max: times.eng_max,
                              dept_avg: times.dept_avg, dept_max: times.dept_max)


    User.joins(:complaint_entry_credits)
        .where(complaint_entry_credits: {created_at: (@date_from..@date_to+1)})
        .group(:id).order(:cvs_username).each do |user|

      counts =
          ComplaintEntryCredit.where(user_id: user.id, created_at: (@date_from..@date_to+1)).group(:credit).count

      times =
          ComplaintEntry.where.not(resolution: nil)
          .where(user_id: user.id, case_resolved_at: (@date_from..@date_to+1))
          .select(times_select_phrase).first

      yield ResolutionCount.new(username: user.cvs_username,
                                pending: counts[ComplaintEntryCredit::PENDING],
                                fixed: counts[ComplaintEntryCredit::FIXED],
                                invalid: counts[ComplaintEntryCredit::INVALID],
                                unchanged: counts[ComplaintEntryCredit::UNCHANGED],
                                duplicate: counts[ComplaintEntryCredit::DUPLICATE],
                                eng_avg: times.eng_avg, eng_max: times.eng_max,
                                dept_avg: times.dept_avg, dept_max: times.dept_max)
    end
  end

  def each_engineer_old

    times_select_phrase =
        'avg(time_to_sec(timediff( case_resolved_at, case_assigned_at ))) as eng_avg, ' +
            'max( time_to_sec( timediff( case_resolved_at, case_assigned_at ))) as eng_max, ' +
            'avg(time_to_sec(timediff( case_resolved_at, created_at ))) as dept_avg, ' +
            'max( time_to_sec( timediff( case_resolved_at, created_at ))) as dept_max'

    counts = ComplaintEntry.where(case_resolved_at: (@date_from..@date_to+1)).group(:resolution).count

    times =
        ComplaintEntry.where.not(resolution: nil)
            .where(case_resolved_at: (@date_from..@date_to+1))
            .select(times_select_phrase).first

    yield ResolutionCount.new(username: 'TOTAL',
                              fixed: counts[Complaint::RESOLUTION_FIXED],
                              invalid: counts[Complaint::RESOLUTION_INVALID],
                              unchanged: counts[Complaint::RESOLUTION_UNCHANGED],
                              duplicate: counts[Complaint::RESOLUTION_DUPLICATE],
                              eng_avg: times.eng_avg, eng_max: times.eng_max,
                              dept_avg: times.dept_avg, dept_max: times.dept_max)


    User.joins(:complaint_entries)
        .where.not(complaint_entries: {resolution: nil})
        .where(complaint_entries: {case_resolved_at: (@date_from..@date_to+1)})
        .group(:id).order(:cvs_username).each do |user|

      counts =
          ComplaintEntry.where(user_id: user.id, case_resolved_at: (@date_from..@date_to+1)).group(:resolution).count

      times =
          ComplaintEntry.where.not(resolution: nil)
          .where(user_id: user.id, case_resolved_at: (@date_from..@date_to+1))
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
