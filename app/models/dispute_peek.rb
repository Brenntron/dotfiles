class DisputePeek < ApplicationRecord
  belongs_to :user
  belongs_to :dispute

  def self.count_excess_query(user:)
    joins('cross join dispute_peeks count_peeks')
        .where(user_id: user.id).where('count_peeks.user_id = :user_id', user_id: user.id)
        .where('dispute_peeks.updated_at <= count_peeks.updated_at')
        .group(:id).having('20 < count(count_peeks.id)')
  end

  def self.delete_excess(user:)
    where(id: count_excess_query(user: user).pluck(:id)).delete_all
  end
end
