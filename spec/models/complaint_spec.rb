describe Complaint do
  let(:complaint_message_payload) do
    ActionController::Parameters.new({
        'source_key' => 49,
        'source_type' => "Complaint",
        'payload' => {
            'name' => "Marlin Pierce",
            'email' => "marlpier@cisco.com",
            'domain' => "cisco.com",
            'problem' => "New category",
            'details' => '',
            'user_ip' => "::1",
            'ticket_time' => "September 03, 2018 12:05",
            'investigate_ips' => {},
            'investigate_urls' => {
                'www.spanx.com' => {
                    'WBRS_SCORE' => '1.58',
                    'WBRS_Rule_Hits' => "alx_cln, vsvd",
                    'Hostname_ips' => '',
                    'current_cat' => "Shopping",
                    'cat_sugg' => [
                        "Lingerie and Swimsuits"
                    ],
                }
            },
            'user_company' => "Cisco Systems, Inc.",
            'submission_type' => "w"
        }
    })
  end

  before(:example) do
    FactoryBot.create(:vrt_incoming_user)
    FactoryBot.create(:guest_company)
  end

  it 'processes bridge payload' do

    Complaint.process_bridge_payload(complaint_message_payload)
  end
end
