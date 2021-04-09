class ComplaintEntryCredits::CreditHandler
  attr_reader :user, :complaint_entry

  def initialize(user, complaint_entry)
    @user = user
    @complaint_entry = complaint_entry
  end

  def handle_pending_credit
    clear_previous_user_credits
    create_credit_for(ComplaintEntryCredit::PENDING)
  end

  def handle_unchanged_credit
    clear_previous_user_credits
    create_credit_for(ComplaintEntryCredit::UNCHANGED)
  end

  def handle_fixed_credit
    clear_previous_user_credits
    create_credit_for(ComplaintEntryCredit::FIXED)
  end

  def handle_invalid_credit
    clear_previous_user_credits
    create_credit_for(ComplaintEntryCredit::INVALID)
  end

  def handle_duplicate_credit
    clear_previous_user_credits
    create_credit_for(ComplaintEntryCredit::DUPLICATE)
  end

  private

  def clear_previous_user_credits
    ComplaintEntryCredit.where(user: user, complaint_entry: complaint_entry).destroy_all
  end

  def create_credit_for(credit_type)
    ComplaintEntryCredit.create(
      user: user,
      complaint_entry: complaint_entry,
      credit: credit_type
    )
  end
end
