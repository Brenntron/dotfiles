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
      Rails.logger.error ("Screenshotting url:#{url}")
      driver.navigate.to url

      #set the size to something respectable
      driver.manage.window.resize_to(800, 800)

      #save the screenshot hopefully in the database so we dont have to worry about disk usage
      self.update(screenshot: driver.screenshot_as(:png), error_message: "")
      Rails.logger.error ("done with #{url}")
    rescue Net::ReadTimeout => ex
      Rails.logger.error ("Hey! There was a Net Read Timeout error")
      file_data = File.open("app/assets/images/timeout_screenshot.jpg").read()
      self.update(screenshot: file_data, error_message: ex.message)
    rescue Exception => ex
      unless driver.nil?
        driver.close()
      end
      Rails.logger.error ("oops there was a screen capture error")
      Rails.logger.error ("#{ex.class}: #{ex.message}")
      file_data = File.open("app/assets/images/failed_screenshot.jpg").read()
      self.update(screenshot: file_data, error_message: ex.message.truncate(1000000))

    ensure # this is a good practice to get into so that the driver will always exit, even if there is an error
      unless driver.nil?
        driver.quit()
      end
    end
  end


  handle_asynchronously :grab_screenshot, :queue => "screen_grab", :priority => 20
end
