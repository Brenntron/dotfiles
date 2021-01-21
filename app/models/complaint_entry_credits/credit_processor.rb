class ComplaintEntryCredits::CreditProcessor
  attr_reader :user, :complaint_entry, :status

  def initialize(user, complaint_entry, status)
    @user = user
    @complaint_entry = complaint_entry
    @status = status.downcase
  end

  def process
    credit_handler = ComplaintEntryCredits::CreditHandler.new(user, complaint_entry)

    case status
    when 'fixed'
      credit_handler.handle_pending_credit
    when 'created'
      credit_handler.handle_pending_credit
    when 'unchanged'
      credit_handler.handle_unchanged_credit
    when 'commit'
      credit_handler.handle_fixed_credit
    when 'decline'
      credit_handler.handle_unchanged_credit
    when 'invalid'
      credit_handler.handle_invalid_credit
    when 'duplicate'
      credit_handler.handle_duplicate_credit
    end
  end
end
