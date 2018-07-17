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
      if status!="COMPLETED"
        self.update(user:current_user, status:"ASSIGNED")
        complaint.set_status("ASSIGNED")
      else
        raise("Cannot take a completed complaint. How did this happen.")
      end
    else
      raise("Cannot take someone elses complaint.")
    end
  end
  def return_complaint(current_user)
    if self.user == current_user
      if !self.is_important
        if status!="COMPLETED"
          self.update(user:nil, status:"NEW")
          complaint.set_status("NEW")
        else
          raise("Cannot return complaint that has been completed.")
        end
      else
        raise("Cannot return complaint when status is pending.")
      end
    else
      if self.user.nil?
        raise("Cannot return a complaint that is not assigned")
      else
        raise("Cannot return someone elses complaint.")
      end
    end
  end
  def change_category(prefix, categories_string, entry_status, comment,current_user)
    categories = categories_string.split(',')
    ActiveRecord::Base.transaction do
      #this is where we should send off the category to the API
      update(resolution:entry_status,category:categories_string,status:"COMPLETED",resolution_comment: comment,user:current_user)
      complaint.set_status("COMPLETED")
    end

  end
end
