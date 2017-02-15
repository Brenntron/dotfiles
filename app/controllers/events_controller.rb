class EventsController < ApplicationController
  include ActionController::Live
  extend ActiveSupport::Concern

  def send_event
    data = 'something'
    event = 'import'
    response.headers["Content-Type"] = "text/event-stream"
    response.stream.write("event: #{event}\n")
    response.stream.write("data: #{data}\n\n")
  rescue IOError
    logger.info "Stream was closed"
  ensure
    response.stream.close
  end

end