class AbuseRecord < ApplicationRecord

  belongs_to :complaint_entry

  IWF = "IWF"
  NCMEC = "NCMEC"

  def self.build_and_save_record(url, report_submitted = nil, response = nil, report_ident = nil, report_source = nil, user = nil, complaint_entry = nil)

    abuse_record = AbuseRecord.new
    abuse_record.submitter = user.email
    abuse_record.complaint_entry_id = complaint_entry.id
    abuse_record.source = report_source
    abuse_record.result = response.to_s
    abuse_record.report_submitted = report_submitted
    abuse_record.report_ident = report_ident
    abuse_record.url = url
    abuse_record.save

    abuse_record
  end

end
