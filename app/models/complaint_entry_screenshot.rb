class ComplaintEntryScreenshot < ApplicationRecord
  belongs_to :complaint_entry

  def grab_screenshot
    begin
      options = Selenium::WebDriver::Firefox::Options.new(args: ['-headless'])
      driver = Selenium::WebDriver.for(:firefox, options: options)

      raise Exception.new('Cant start Selenium driver') if driver.nil?

      #go to the url provided (it needs http or https on it.)
      host_lookup = self.complaint_entry.hostlookup
      url = host_lookup.match(/^(http|https):\/\//) ? host_lookup : "http://#{host_lookup}"
      driver.navigate.to url

      #set the size to something respectable
      driver.manage.window.resize_to(800, 800)

      #save the screenshot hopefully in the database so we dont have to worry about disk usage
      self.update(screenshot: driver.screenshot_as(:png), error_message: "")

    rescue Exception => ex
      puts ("oops there was a screen capture error")
      puts ("#{ex.class}: #{ex.message}")
      file_data = ""
      open("app/assets/images/failed_screenshot.jpg") do |f|
        file_data = f.read
      end
      self.update(screenshot: file_data, error_message: ex.message)
    ensure # this is a good practice to get into so that the driver will always exit, even if there is an error
      driver.quit unless driver.nil?
    end
  end


  handle_asynchronously :grab_screenshot, :queue => "screen_grab"
end
