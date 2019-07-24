Given(/^the following FileRep dispute comments exist:$/) do |dispute_comments|
  dispute_comments.hashes.each do |dispute_comment|
    FactoryBot.create(:file_rep_comment, dispute_comment)
  end
end