class WebcatCredits::ComplaintEntries::CreditHandler
  attr_reader :user, :complaint_entry

  def initialize(user, complaint_entry)
    @user = user
    @complaint_entry = complaint_entry
  end

  def handle_pending_credit
    create_credit_for(WebcatCredit::PENDING)
  end

  def handle_unchanged_credit
    create_credit_for(WebcatCredit::UNCHANGED)
  end

  def handle_fixed_credit
    create_credit_for(WebcatCredit::FIXED)
  end

  def handle_invalid_credit
    create_credit_for(WebcatCredit::INVALID)
  end

  def handle_duplicate_credit
    create_credit_for(WebcatCredit::DUPLICATE)
  end

  private

  def create_credit_for(credit_type)
    ComplaintEntryCredit.create(
      user: user,
      complaint_entry: complaint_entry,
      credit: credit_type
    )
  end
end
