include ActionView::Helpers::DateHelper

class ComplaintEntry < ApplicationRecord
  belongs_to :complaint
  belongs_to :user, optional: true

  scope :assigned_count , -> {where(status:"ASSIGNED").count}
  scope :pending_count , -> {where(status:"PENDING").count}
  scope :new_count , -> {where(status:"NEW").count}
  scope :overdue_count , -> {where("created_at < ?",Time.now - 24.hours).count}

  def self.what_time_is_it(value)
    distance_of_time_in_words(value)
  end

  def location_url
    "http://#{subdomain+'.' if subdomain.present?}#{domain}#{path}"
  end

  def take_complaint(current_user)
    if user.nil?
      self.update(user:current_user, status:"ASSIGNED")
      complaint.set_status("ASSIGNED")
    end
  end
  def return_complaint(current_user)
    if self.user == current_user
      self.update(user:nil, status:"NEW")
      complaint.set_status("NEW")
    end
  end
  def change_category(prefix, categories_string, entry_status, comment)
    categories = categories_string.split(',')
    ActiveRecord::Base.transaction do
      #this is where we should send off the category to the API
      update(resolution:entry_status,category:categories_string,status:"COMPLETED",resolution_comment: comment)
      complaint.set_status("COMPLETED")
    end

  end
end
