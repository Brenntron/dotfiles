class UpdateResolutionMessageTemplatesAndDisputes < ActiveRecord::Migration[6.1]
  def change
    # Update resolution_message_templates table
    ResolutionMessageTemplate.resolved.where(description: 'Fixed - FP').update_all(description: 'FIXED_FP')
    ResolutionMessageTemplate.resolved.where(description: 'Fixed - FN').update_all(description: 'FIXED_FN')
    ResolutionMessageTemplate.resolved.where(description: 'Unchanged').update_all(description: 'UNCHANGED')
    ResolutionMessageTemplate.resolved.where(description: 'Invalid / Junk Mail').update_all(description: 'INVALID')
    ResolutionMessageTemplate.resolved.where(description: 'Test / Training').update_all(description: 'TEST_TRAINING')
    ResolutionMessageTemplate.resolved.where(description: 'Other').update_all(description: 'OTHER')

    # Update disputes table
    Dispute.where(resolution: 'Fixed - FP').update_all(resolution: 'FIXED_FP')
    Dispute.where(resolution: 'Fixed - FN').update_all(resolution: 'FIXED_FN')
    Dispute.where(resolution: 'Invalid / Junk Mail').update_all(resolution: 'INVALID')
    Dispute.where(resolution: 'Test / Training').update_all(resolution: 'TEST_TRAINING')

    # MySql search is not case sensitive, so no need to update all old records, for that we need to use 'BINARY' option
    Dispute.where("BINARY resolution = 'Other'").update_all(resolution: 'OTHER')
    Dispute.where("BINARY resolution = 'Unchanged'").update_all(resolution: 'UNCHANGED')
  end
end
