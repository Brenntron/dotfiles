include ActionView::Helpers::DateHelper

class ComplaintEntry < ApplicationRecord
  belongs_to :complaint
  belongs_to :user, optional: true

  scope :assigned_count , -> {where(status:"ASSIGNED").count}
  scope :pending_count , -> {where(status:"PENDING").count}
  scope :new_count , -> {where(status:"NEW").count}
  scope :overdue_count , -> {where("created_at < ?",Time.now - 24.hours).where.not(status:"COMPLETED").count}

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

  def is_high_telemetry?
    #put code here that determines high telemetry
    # maybe this could have been determined when we create the complaint
    true
  end
  def is_pending?
    "PENDING" == status
  end

  def change_category(prefix, categories_string, entry_status, comment,current_user,importance, commit_pending)
    categories = categories_string&.split(',')
    ActiveRecord::Base.transaction do
      # If the prefix is a high telemetry value then the status needs to be set to PENDING
      if importance
        if commit_pending == "commit"
          current_status = "COMPLETED"
          #this is where we should send off the category to the API
          update(resolution:entry_status,category:categories_string,status:current_status,resolution_comment: comment,user:current_user, is_important: importance)
          complaint.set_status(current_status)
        else
          current_status = "ASSIGNED"
          update(status:current_status, is_important: false)
        end
      else
        if self.is_high_telemetry?
          current_status = "PENDING"
          update(resolution:entry_status,category:categories_string,status:current_status,resolution_comment: comment,user:current_user,status:current_status, is_important: true)
        else
          current_status = "COMPLETED"
          update(resolution:entry_status,category:categories_string,status:current_status,resolution_comment: comment,user:current_user, is_important: importance)
          complaint.set_status(current_status)
          #this is where we should send off the category to the API
        end
      end
    end

  end
end
