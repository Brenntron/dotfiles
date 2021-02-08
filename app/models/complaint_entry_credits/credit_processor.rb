class ComplaintEntryCredits::CreditProcessor
  attr_reader :user, :complaint_entry

  def initialize(user, complaint_entry)
    @user = user
    @complaint_entry = complaint_entry
  end

  def process
    credit_handler = ComplaintEntryCredits::CreditHandler.new(user, complaint_entry)

    case complaint_entry.status
    when 'PENDING'
      credit_handler.handle_pending_credit
    when 'ASSIGNED'
      credit_handler.handle_unchanged_credit
    when 'COMPLETED'
      process_completed_status(credit_handler)
    end
  end

  private

  def process_completed_status(credit_handler)
    case complaint_entry.resolution
    when "FIXED"
      credit_handler.handle_fixed_credit
    when "UNCHANGED"
      credit_handler.handle_unchanged_credit
    when "INVALID"
      credit_handler.handle_invalid_credit
    when "DUPLICATE"
      credit_handler.handle_duplicate_credit
    else
      credit_handler.handle_fixed_credit
    end
  end
end
