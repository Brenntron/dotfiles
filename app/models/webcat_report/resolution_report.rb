class WebcatReport::ResolutionReport
  class ResolutionCount
    include ActiveModel::Model
    attr_accessor :username, :internal, :pending, :fixed, :invalid, :unchanged, :duplicate,
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

    cached_resolution_count = JSON.parse(Rails.cache.read("total_resolution_count_#{@date_from.to_s}-#{@date_to.to_s}") || "{}")
    if cached_resolution_count.present?
      res_count = ResolutionCount.new(username: 'TOTAL',
                                      internal: cached_resolution_count['internal'],
                                      pending: cached_resolution_count['pending'],
                                      fixed: cached_resolution_count['fixed'],
                                      invalid: cached_resolution_count['invalid'],
                                      unchanged: cached_resolution_count['unchanged'],
                                      duplicate: cached_resolution_count['duplicate'],
                                      eng_avg: cached_resolution_count['eng_avg'], eng_max: cached_resolution_count['eng_max'],
                                      dept_avg: cached_resolution_count['dept_avg'], dept_max: cached_resolution_count['dept_max'])
    else
      counts = WebcatCredit.where(created_at: (@date_from..@date_to+1)).group(:credit).count

      times =
          ComplaintEntry.where.not(resolution: nil)
              .where(case_resolved_at: (@date_from..@date_to+1))
              .select(times_select_phrase).first



      res_count = ResolutionCount.new(username: 'TOTAL',
                                      internal: counts[WebcatCredit::INTERNAL],
                                      pending: counts[WebcatCredit::PENDING],
                                      fixed: counts[WebcatCredit::FIXED],
                                      invalid: counts[WebcatCredit::INVALID],
                                      unchanged: counts[WebcatCredit::UNCHANGED],
                                      duplicate: counts[WebcatCredit::DUPLICATE],
                                      eng_avg: times.eng_avg, eng_max: times.eng_max,
                                      dept_avg: times.dept_avg, dept_max: times.dept_max)

      if @date_to < Date.today
        Rails.cache.write("total_resolution_count_#{@date_from.to_s}-#{@date_to.to_s}", res_count.to_json)
      else
        Rails.cache.write("total_resolution_count_#{@date_from.to_s}-#{@date_to.to_s}", res_count.to_json, expires_in: 1.hour)
      end
    end

    yield res_count

    User.joins(:webcat_credits)
        .where(webcat_credits: {created_at: (@date_from..@date_to+1)})
        .group(:id).order(:cvs_username).each do |user|

      cached_resolution_count = JSON.parse(Rails.cache.read("#{user.cvs_username}_resolution_count_#{@date_from.to_s}-#{@date_to.to_s}") || "{}")
      if cached_resolution_count.present?
        res_count = ResolutionCount.new(username: cached_resolution_count['username'],
                                        internal: cached_resolution_count['internal'],
                                        pending: cached_resolution_count['pending'],
                                        fixed: cached_resolution_count['fixed'],
                                        invalid: cached_resolution_count['invalid'],
                                        unchanged: cached_resolution_count['unchanged'],
                                        duplicate: cached_resolution_count['duplicate'],
                                        eng_avg: cached_resolution_count['eng_avg'], eng_max: cached_resolution_count['eng_max'],
                                        dept_avg: cached_resolution_count['dept_avg'], dept_max: cached_resolution_count['dept_max'])
      else

        counts =
            WebcatCredit.where(user_id: user.id, created_at: (@date_from..@date_to+1)).group(:credit).count

        times =
            ComplaintEntry.where.not(resolution: nil)
            .where(user_id: user.id, case_resolved_at: (@date_from..@date_to+1))
            .select(times_select_phrase).first

        res_count = ResolutionCount.new(username: user.cvs_username,
                                  internal: counts[WebcatCredit::INTERNAL],
                                  pending: counts[WebcatCredit::PENDING],
                                  fixed: counts[WebcatCredit::FIXED],
                                  invalid: counts[WebcatCredit::INVALID],
                                  unchanged: counts[WebcatCredit::UNCHANGED],
                                  duplicate: counts[WebcatCredit::DUPLICATE],
                                  eng_avg: times.eng_avg, eng_max: times.eng_max,
                                  dept_avg: times.dept_avg, dept_max: times.dept_max)

        if @date_to < Date.today
          Rails.cache.write("#{user.cvs_username}_resolution_count_#{@date_from.to_s}-#{@date_to.to_s}", res_count.to_json)
        else
          Rails.cache.write("#{user.cvs_username}_resolution_count_#{@date_from.to_s}-#{@date_to.to_s}", res_count.to_json, expires_in: 1.hour)
        end
      end

      yield res_count
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
