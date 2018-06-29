class ComplaintMarkedCommit < ApplicationRecord
  belongs_to :user
  belongs_to :complaint_entry

  def self.mark_for_commit(entry_ids, category_list, user:, comment:)
    entry_ids.each do |entry_id|
      create!(user: user, complaint_entry_id: entry_id, comment: comment, category_list: category_list)
    end
  end

  def self.commit_marked(user:)
    where(user: user).each do |marked_commit|
      entry = ComplaintEntry.find(marked_commit.complaint_entry_id)
      cats = marked_commit.category_list.split(/\s*,\s*/).map{|mnem| Wbrs::Category.lookup_by_mnem(mnem)}
      category_ids = cats.map{|cat| cat.category_id}

      Wbrs::Prefix.create_from_url(url: entry.location_url, category_ids: category_ids, user: user,
                                   description: marked_commit.comment)
    end
  end
end
