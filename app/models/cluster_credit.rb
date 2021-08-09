class ClusterCredit < WebcatCredit
  validates :domain, presence: true
end
