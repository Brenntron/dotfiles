describe EscalationEmailTool do
  let(:params) do
    ActionController::Parameters.new(
        {

                'to' => "ancheng3@cisco.com",
                'from' => "test@cisco.com",
                'subject' => "cisco.com",
                'body' => "New category"
            })
  end

  let(:current_user) do
    User.new(email: 'ancheng3@cisco.com')
  end

  it 's3_url' do
    expect(EscalationEmailTool.s3_url('google.com')).to include("https://analyst-console.s3.amazonaws.com/google.com?X-Amz-Algorithm=AWS4-HMAC-SHA256&X")
  end

  it 'generate_email_info' do
    expect(EscalationEmailTool.generate_email_info(params, current_user).handler).to include("ancheng3@cisco.com", "test@cisco.com", "cisco.com", "New category")
  end

end
