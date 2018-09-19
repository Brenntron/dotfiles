class ComplaintEntryPreload < ApplicationRecord
  belongs_to :complaint_entry
  TRIES = 5

  def self.generate_preload_from_complaint_entry(complaint_entry)

    current_category_information = nil
    historic_category_information = nil
    counter = 0
    while counter < TRIES
      begin
        current_category_information ||= complaint_entry.current_category_data
        break
      rescue
        counter = counter + 1
      end
    end
    counter = 0

    # TODO: historic info repeats the query above to get the prefix id.  Use previous results to short cut this check.
    while counter < TRIES
      begin
        historic_category_information ||= complaint_entry.historic_category_data
        break
      rescue
        counter = counter + 1
      end
    end
    counter = 0

    previous_preload = ComplaintEntryPreload.where(:complaint_entry_id => complaint_entry.id).first
    if previous_preload.present?
      previous_preload.destroy
    end

    if current_category_information.present?
      current_category_information = current_category_information.to_json
    else
      current_category_information = "DATA ERROR"
    end

    if historic_category_information.present?
      historic_category_information = historic_category_information.to_json
    else
      historic_category_information = "DATA ERROR"
    end

    data = ComplaintEntryPreload.new do |d|
      d.complaint_entry_id = complaint_entry.id
      d.current_category_information = current_category_information
      d.historic_category_information = historic_category_information
    end

    data.save!


  end

end
