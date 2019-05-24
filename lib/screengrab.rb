require 'rubygems'
require 'httpi'
require 'stomp'
require 'json'
require 'selenium-webdriver'


# Make sure we run from the application root
Dir.chdir Rails.root


HTTPI.log = false

req = HTTPI::Request.new
req.auth.gssnegotiate

req.auth.ssl.ca_cert_file = Rails.configuration.cert_file

if Rails.env =="development"
  OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
end

max_wait_for_job = 120 #seconds
puts "init stomp"
stomp_options = {}
stomp_options = {
    :hosts => [{:login => "guest", :passcode => "guest", :host => Rails.configuration.amq_host, :port => 61613, :ssl => false}],
    :reliable => true, :closed_check => false
}
Capybara.register_driver :selenium do |app|
  Capybara::Selenium::Driver.new( app, :browser => :chrome )
end

Rails.logger.info("#{Time.now} -> create stomp client and subscribe to amq")
# Create our stomp client
puts "create stomp connection"
client = Stomp::Connection.new(stomp_options)
# This queue should only have work jobs for All rule runs
client.subscribe Rails.configuration.subscribe_all_work, {:ack => :client}
puts "init selenium connection"

options = Selenium::WebDriver::Firefox::Options.new(args: ['-headless'])
driver = Selenium::WebDriver.for(:firefox, options: options)

# # navigate to a really super awesome site
# driver.navigate.to "https://talosintelligence.com"
#
# # resize the window and take a screenshot
# driver.manage.window.resize_to(800, 800)
# driver.save_screenshot "talosintelligence-screenshot.png"
#
# puts "Page title is #{driver.title}"
#

while message = client.receive
  begin
    # Start by parsing the request
    request = JSON.parse(message.body)
    Rails.logger.info("#{Time.now} -> received request")
    Rails.logger.debug(request)

    # Release the message early
    client.ack(message.headers['message-id'])

    # Save the task_id
    ces_id = request['ces_id']
    host_lookup = request['host_lookup']

    #get object that contains info about where we are taking the screenshot
    # and where to put the data once the shot is taken

    screenshot_entry = ComplaintEntryScreenshot.find(ces_id)
    #take the screenshot using the URL provided

    driver.navigate.to host_lookup

    #save the screenshot hopefully in the database so we dont have to worry about disk usage
    driver.manage.window.resize_to(800, 800)

    data = driver.save_screenshot

    screenshot_entry.screenshot = Base64.decode64(data)

  rescue Exception => ex
    puts ("#{ex.class}: #{ex.message}")
  ensure # this is a good practice to get into so that the driver will always exit, even if there is an error
    driver.quit
  end
end

driver.quit