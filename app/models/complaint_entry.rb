include ActionView::Helpers::DateHelper

class ComplaintEntry < ApplicationRecord
  belongs_to :complaint
  belongs_to :user, optional: true

  def self.what_time_is_it(value)
    distance_of_time_in_words(value)
  end

  def location_url
    "http://#{subdomain+'.' if subdomain.present?}#{domain}#{path}"
  end

  def take_complaint(current_user)
    if user.nil?
      self.update(user:current_user)
    end
  end
  def return_complaint(current_user)
    if self.user == current_user
      self.update(user:nil)
    end
  end
end
