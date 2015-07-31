class AttachmentTestProcessor < ApplicationProcessor

  subscribes_to :snort_local_rules_test_result

  def on_message(message)
    result = JSON.parse(message)
    Rails.logger.info "+++++++++++++++++++++++++++"
    Rails.logger.info "RESULT IS:"
    Rails.logger.info result
    Rails.logger.info "==========================="
  end


end