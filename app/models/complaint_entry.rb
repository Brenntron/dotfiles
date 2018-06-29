class ComplaintEntry < ApplicationRecord
  belongs_to :complaint

  def self.mark_for_commit(entry_ids)
    byebug
    where(id: entry_ids).update_all(marked_for_commit: true)
  end
end
