class ComplaintMarkedCommit < ApplicationRecord
  belongs_to :user
  belongs_to :complaint_entry

  def self.mark_for_commit(entry_ids, threat_category_list, user:, comment:)
    byebug
    entry_ids.each do |entry_id|
      create!(user: user, complaint_entry_id: entry_id, comment: comment, threat_category_list: threat_category_list)
    end
  end
end
