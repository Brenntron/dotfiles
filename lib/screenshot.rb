


require 'httpi'
require 'curl'
require 'open3'
require 'stomp'
require 'json'
require 'tmpdir'
require 'tempfile'
require 'base64'
require 'pry'
require 'selenium-webdriver'


# Make sure we run from the application root
Dir.chdir Rails.root


HTTPI.log = false

req = HTTPI::Request.new
req.auth.gssnegotiate

req.auth.ssl.ca_cert_file = Rails.configuration.cert_file


# General options
local_cache_path = File.expand_path("#{Rails.root}/tmp/pcaps")

if Rails.env =="development"
  OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
end

# Make sure our pcaps cache exists
unless File.exists?(local_cache_path)
  Dir.mkdir(local_cache_path)
end

max_wait_for_job = 120 #seconds

stomp_options = {}
stomp_options = {
    :hosts => [{:login => "guest", :passcode => "guest", :host => Rails.configuration.amq_host, :port => 61613, :ssl => false}],
    :reliable => true, :closed_check => false
}

Rails.logger.info("#{Time.now} -> create stomp client and subscribe to amq")
# Create our stomp client
client = Stomp::Connection.new(stomp_options)
# This queue should only have work jobs for All rule runs
client.subscribe Rails.configuration.subscribe_all_work, {:ack => :client}

driver_firefox = Selenium::WebDriver.for :firefox
driver_chrome =  Selenium::WebDriver.for :chrome

def self.low_capture(url)
  Rails.logger.info("captureing screenshot...")
  output, errors, status = Open3.capture3("phantomjs --ssl-protocol=any --ignore-ssl-errors=true /extras/capture_site_image.js #{url}")
  Rails.logger.info("Screenshot capture status:#{status.exitstatus} - [#{status.pid}] #{status} ")
  Rails.logger.info("Errors were: ->#{errors}<-")
  output
end



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

    driver.get host_lookup

    #save the screenshot hopefully in the database so we dont have to worry about disk usage

    data = driver.save_screenshot("./screen.png")

    screenshot_entry.screenshot = Base64.decode64(data)



  rescue
  end




end

driver_firefox.quit
driver_chrome.quit