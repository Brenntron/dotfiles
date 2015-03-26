class EventsController < ApplicationController
  protect_from_forgery except: :create

  def create
    @event = Event.new(event_params)

    respond_to do |format|
      if @event.parse_event
        format.json { render json: @event, status: :created }
      else
        format.json { render json: @event.errors, status: :unprocessable_entity }
      end
    end
  end
end