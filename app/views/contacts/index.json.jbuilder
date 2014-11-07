json.hash do
 json.array!(@contacts) do |contact|
    json.extract! contact, :name, :about, :avatar
    json.url contact_url(contact, format: :json)
  end
end