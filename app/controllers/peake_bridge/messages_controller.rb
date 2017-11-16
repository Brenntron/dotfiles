module PeakeBridge
  class MessagesController < ApplicationController
    def create
      channel = params[:channel_id]
      Rails.logger.debug("PeakeBridge message recieved, on channel #{channel.inspect}")

      envelope = params[:envelope]
      Rails.logger.debug("PeakeBridge envelope = #{envelope.inspect}")

      addressee = envelope && envelope[:addressee]
      Rails.logger.debug("PeakeBridge addressee = #{addressee.inspect}")

      Rails.logger.debug("PeakeBridge message = #{params[:message].inspect}")

      render plain: "Analyst Console recieved message, on channel #{channel.inspect} to addressee #{addressee.inspect}"
    end
  end
end
