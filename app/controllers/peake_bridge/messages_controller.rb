module PeakeBridge
  class MessagesController < ApplicationController
    def create
      Rails.logger.debug("PeakeBridge message recieved, on channel #{params[:channel_id].inspect}")
      Rails.logger.debug("PeakeBridge message head = #{params[:head].inspect}")
      Rails.logger.debug("PeakeBridge message body = #{params[:body].inspect}")
    end
  end
end
