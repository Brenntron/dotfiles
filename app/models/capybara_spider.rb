require 'capybara'
require 'capybara/poltergeist'

class CapybaraSpider < Capybara::Session
  cattr_accessor :file, :filename

  def self.build_session
    self.build_configuration
    self.new_session
  end

  def self.build_configuration
    Capybara.register_driver :poltergeist do |app|
      Capybara::Poltergeist::Driver.new( app, { is_errors: false, js_errors: false } )
    end
  end

  def self.new_session
    new(:poltergeist)
  end

  def self.tmpfilename
    Dir::Tmpname.make_tmpname(['webcapture_', '.png'], nil)
  end

  def self.low_capture(url, filepath)
    `phantomjs /extras/capture_site_image.js #{url} #{filepath}/#{tmpfilename}`.strip()
  end

  def self.capture(url)
    begin
      session = CapybaraSpider.build_session
      session.visit(url)
      session.filename = "#{Rails.root}/tmp/#{tmpfilename}"
      session.save_screenshot(session.filename, full: false)

      if block_given?
        File.open(session.filename, 'r') do |file|
          session.file = file
          yield session
        end

        File.delete(session.filename)

        nil
      else
        filename
      end
    rescue Exception => e
      Rails.logger.error("there was a problem using Capybara. #{e.message}")
    end
  end

  def read(*args)
    file.read(*args)
  end
end


#THIS IS A PROTOTYPE FOR NICK HERBERT
#this actually currently works on my macbook pro as is *yay*
#so maybe no configuration tweaking and library installation is required
#might be worth checking to see if it also works on staging somehow

#in the ticket origination code in dispute.rb, would go something like:
#in initiation or at top of method or something:
#
#session = CapybaraSpider.build_session
#
#somewhere in the actual ticket origination code when you've saved data
#to columns and you're ready to store a screenshot (note: the screenshot filename
#that you feed to save_screenshot has to be the FULL PATH, so by default
#would most likely need to be something like /tmp/some-screenshot-file-name.jpg)
#then later in the code do a File.open so the actual file can safely be saved in the bugzilla
#bug that's linked to each complaint and dispute (specifically for the purpose of storing files).
#
#filename = generate_some_unique_file_name_here

#then navigate to the URI provided
#session.visit("http://www.google.com")

#if you do a session.body and the value is
#<html><head></head><body></body></html>   
#then the page did not successfully load, either because the capybara
#library isn't functioning or a network error of some sort or the URI you provided is garbage

#appropriate spot in the origination code to save screenshot
#session.save_screenshot(filename, :full => true)


# example:
# session = CapybaraSpider.build_session
# session.visit("http://stackoverflow.com/")
# session.save_screenshot("~/pictures/stackoverlog.png", full: true)
