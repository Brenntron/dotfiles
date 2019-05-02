namespace :complaints do
  task :kill_complaints, [:complaint_list] => :environment do |t, args|
    puts "Checking argument list.....\n"
    if args[:complaint_list].present?
      complaints_file = args[:complaint_list]
      puts "Checking file.....\n"
      if File.exists?(complaints_file)
        complaint_ids = File.readlines(complaints_file)
        puts "setting everything up.....\n"
        if complaint_ids.empty?
          puts "That file is empty.....\n"
        else
          complaint_errors = []
          complaint_entry_errors = []
          complaint_screenshot_errors = []
          complaint_entry_preload_errors = []
          complaint_ids.each do |id|
            begin
              complaint = Complaint.find(id)
              complaint.complaint_entries.each do |complaint_entry|
                begin
                  puts "deleting screenshot id: #{complaint_entry.complaint_entry_screenshot.id}"
                  complaint_entry.complaint_entry_screenshot.delete
                rescue
                  complaint_screenshot_errors << complaint_entry.complaint_entry_screenshot.id
                end
                begin
                  puts "deleting entry preload id: #{complaint_entry.complaint_entry_preload.id}"
                  complaint_entry.complaint_entry_preload.delete
                rescue
                  complaint_entry_preload_errors << complaint_entry.complaint_entry_preload.id
                end
                begin
                  puts "deleting entry id: #{complaint_entry.id}"
                  complaint_entry.delete
                rescue
                  complaint_entry_errors << complaint_entry.id
                end
              end
              begin
                puts "deleting Complaint id: #{complaint.id}"
                complaint.delete
              rescue
                complaint_errors << complaint.id
              end
            rescue
              complaint_errors << id
            end
          end
          if complaint_errors.any?
            puts "cant delete Complaint ids: #{complaint_errors.to_sentence}"
          end
          if complaint_entry_errors.any?
            puts "cant delete entry ids: #{complaint_entry_errors.to_sentence}"
          end
          if complaint_screenshot_errors.any?
            puts "cant delete screenshot ids: #{complaint_screenshot_errors.to_sentence}"
          end
          if complaint_entry_preload_errors.any?
            puts "cant delete preload ids: #{complaint_entry_preload_errors.to_sentence}"
          end
        end
      else
        puts "The file (#{complaints_file}) does not exist."
      end
    end
  end
end
