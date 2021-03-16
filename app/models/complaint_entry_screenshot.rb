class ComplaintEntryScreenshot < ApplicationRecord
  belongs_to :complaint_entry

  def grab_screenshot
    begin
      # ces = self
      # options = Selenium::WebDriver::Chrome::Options.new
      # options.add_argument('--ignore-certificate-errors')
      # options.add_argument('--disable-popup-blocking')
      # options.add_argument('--disable-translate')
      # options.add_argument('--disable-crash-reporter')
      # options.add_argument('--headless')
      # # options.add_argument('--cast-initial-screen-width=800')
      # # options.add_argument('--cast-initial-screen-height=600')
      # options.add_argument("--window-size=800,600")
      # # options to consider
      # # --user-data-dir     Directory where the browser stores the user profile.
      # # --profile-directory Selects directory of profile to associate with the first browser launched.
      # # more are here https://peter.sh/experiments/chromium-command-line-switches/
      # driver = Selenium::WebDriver.for :chrome, options: options
      #
      # raise Exception.new('Cant start Selenium driver') if driver.nil?
      #
      # #go to the url provided (it needs http or https on it.)
      # host_lookup = ces.complaint_entry.hostlookup
      # url = host_lookup.match(/^(http|https):\/\//) ? host_lookup : "http://#{host_lookup}"
      # Rails.logger.error ("Screenshotting url:#{url}")
      # driver.navigate.to "http://#{ces.complaint_entry.domain}"
      #
      #
      # #save the screenshot hopefully in the database so we dont have to worry about disk usage
      # ces.update(screenshot: driver.screenshot_as(:png), error_message: "")
      # Rails.logger.error ("done with #{url}")

      #TEMPorarially shut down screenshots
      file_data = File.open("app/assets/images/failed_screenshot.jpg").read()
      self.update(screenshot: file_data, error_message: ex.message.truncate(1000000))

    rescue Net::ReadTimeout => ex
      Rails.logger.error ("Hey! There was a Net Read Timeout error")
      file_data = File.open("app/assets/images/timeout_screenshot.jpg").read()
      self.update(screenshot: file_data, error_message: ex.message)
    rescue Exception => ex
      driver.close unless driver.nil?
      puts ("oops there was a screen capture error")
      puts ("#{ex.class}: #{ex.message}")
      Rails.logger.error ("oops there was a screen capture error")
      Rails.logger.error ("#{ex.class}: #{ex.message}")
      file_data = File.open("app/assets/images/failed_screenshot.jpg").read()
      self.update(screenshot: file_data, error_message: ex.message.truncate(1000000))

    # ensure # this is a good practice to get into so that the driver will always exit, even if there is an error
    #   unless driver.nil?
    #     driver.quit()
    #   end
    end
  end


  handle_asynchronously :grab_screenshot, :queue => "screen_grab", :priority => 99
end
