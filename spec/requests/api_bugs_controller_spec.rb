RSpec.describe API::V1::Bugs do
  describe 'POST /api/v1/bugs' do
    it 'creates a bug'
    it 'handles errors creating a bug'
  end

  describe 'PUT /api/v1/bugs/:bug_id' do
    it 'updates a bug'
    it 'handles errors updating a bug'
  end

  describe 'POST /api/v1/bugs/:bug_id/attachments' do
    it 'adds attachment to a bug'
    it 'handles errors adding attachment to a bug'
  end

  describe 'POST /api/v1/bugs/:bug_id/notes' do
    it 'adds note to a bug'
    it 'handles errors adding note to a bug'
  end

  describe 'POST /api/v1/bugs/:bug_id/rules' do
    it 'adds rule to a bug by rule_id'
    it 'handles errors adding rule to a bug by rule_id'
  end

  describe 'POST /api/v1/bugs/:bug_id/sids' do
    it 'adds rule to a bug by sid'
    it 'handles errors adding rule to a bug by sid'
  end
end

