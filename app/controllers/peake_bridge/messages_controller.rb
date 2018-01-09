module PeakeBridge
  class MessagesController < ApplicationController
    def fp_create

      envelope = params[:envelope]
      Rails.logger.debug("PeakeBridge envelope = #{envelope.inspect}")

      channel = envelope && envelope[:channel]
      Rails.logger.debug("PeakeBridge message recieved, on channel #{channel.inspect}")

      addressee = envelope && envelope[:addressee]
      Rails.logger.debug("PeakeBridge addressee = #{addressee.inspect}")

      sender = envelope && envelope[:sender]
      Rails.logger.debug("PeakeBridge sender = #{sender.inspect}")

      message = params[:message]
      Rails.logger.debug("PeakeBridge message = #{message.inspect}")

      false_positive = message['false_positive']
      Rails.logger.debug("PeakeBridge false_positive = #{false_positive.inspect}")

      Rails.logger.debug("Analyst Console recieved message, on channel #{channel.inspect} to addressee #{addressee.inspect} from sender #{sender.inspect}")

      source_key = false_positive['id']
      Rails.logger.debug("PeakeBridge source_key = #{source_key.inspect}")

      conn = PeakeBridge::FpCreatedEvent.new(source_authority: sender, source_key: false_positive['id'])
      response = conn.post
      Rails.logger.debug("PeakeBridge response.body = #{response.body.inspect}")

      # render plain: "Analyst Console recieved message, on channel #{channel.inspect} to addressee #{addressee.inspect}"
      raise "Analyst Console recieved message, on channel #{channel.inspect} from #{sender.inspect} to addressee #{addressee.inspect}"
    end

    # Add route for specific channels to their own action under the channels collection.
    # When there is no route, it defaults to the create action.
    def create

      channel = params[:channel_id]
      Rails.logger.debug("PeakeBridge message recieved, on channel #{channel.inspect}")

      envelope = params[:envelope]
      Rails.logger.debug("PeakeBridge envelope = #{envelope.inspect}")

      addressee = envelope && envelope[:addressee]
      Rails.logger.debug("PeakeBridge addressee = #{addressee.inspect}")

      Rails.logger.debug("PeakeBridge message = #{params[:message].inspect}")

      # render plain: "Analyst Console recieved message, on channel #{channel.inspect} to addressee #{addressee.inspect}"
      raise "Analyst Console recieved message, on channel #{channel.inspect} to addressee #{addressee.inspect}"
    end
  end
end
