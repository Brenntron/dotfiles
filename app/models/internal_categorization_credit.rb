class InternalCategorizationCredit < WebcatCredit
  # this credit is for cases when URL/ip is categoizing without
  # creation of the Complaint
  validates :domain, presence: true
end
