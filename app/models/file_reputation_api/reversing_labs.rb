##################################################################
# example shas
# 99e432ac19e5a47d0d1ddfad9f326d5e169ab6651d844d4b800a79f4f78d410f

class FileReputationApi::ReversingLabs
  include ApiRequester::ApiRequester
  set_api_requester_config Rails.configuration.reversing_labs
  set_default_request_type :query_string
  set_basic_auth

  include ActiveModel::Model
  attr_accessor :sha256_hash, :raw_json

  def api_response
    @api_response ||= JSON.parse!(self.raw_json)
  end

  def self.cache_key(sha256_hash)
    "reversing_labs:#{sha256_hash}"
  end

  def cache_key
    @cache_key ||= self.class.cache_key(self.sha256_hash)
  end

  def entries
    @entries ||= api_response&.dig('rl','sample','xref','entries')
  end

  def scanners
    unless @scanners
      @scanners =
          if entries&.any?
            record_time = entries.map{|entry| entry['record_time']}.sort.last
            entry = entries.find{|entry| record_time == entry['record_time']}
            entry.dig('scanners')
          else
            []
          end
    end

    @scanners
  end

  def self.get_creation_data(sha256)
    api_response = call_request_parsed(:get, "api/databrowser/rldata/query/sha256/#{sha256}", input: {format: 'json'})

    {file_size: api_response['rl']['sample']['sample_size'], sample_type: api_response['rl']['sample']['xref']['sample_type']}

  rescue JSON::ParserError
    {error: 'Invalid Hash'}
  rescue
    {error: 'Data Currently Unavailable'}
  end

  def score
    reversing_labs_score = 0
    reversing_labs_count = 0
    if api_response&.dig('rl','sample','xref','entries')&.any?
      api_response&.dig('rl','sample','xref','entries')[0]&.dig('scanners').each do |scanner|
        reversing_labs_count += 1
        if scanner['result'].present?
          reversing_labs_score += 1
        end
      end
    end

    { reversing_labs_score: reversing_labs_score, reversing_labs_count: reversing_labs_count }
  end

  # Returns an array of certificates
  def self.certificates(sha256)
    api_response = call_request_parsed(:post, '/api/databrowser/rldata/bulk_query/json', request_type: :json, input: {rl: {query: {hash_type: 'sha256', hashes: [sha256] }}}, headers: {'Authorization': 'Basic dS9zb3VyY2VmaXJlOlV1djRsYWl0'})

    if api_response&.dig('rl','entries')&.any? && api_response&.dig('rl','entries')[0]&.dig('analysis','entries').present?
      certificates = api_response&.dig('rl','entries')[0]&.dig('analysis','entries')[0]&.dig('tc_report','metadata','certificate','certificates')
    else
      certificates = nil
    end

    certificates
  end

  def update_database
    score_attributes = self.score
    attributes = score_attributes.merge(reversing_labs_raw: self.raw_json)
    FileReputationDispute.where(sha256_hash: self.sha256_hash).update_all(attributes)
  end

  # Makes an immediate direct call to reversing labs and creates an object.
  # Does not read or write cache or database.
  # @param [String] sah256_hash the SHA256 hash checksum.
  # @return [FileReputationApi::ReversingLabs] object for the result.
  def self.lookup_raw(sha256_hash)
    response = call_request(:get, "api/databrowser/rldata/query/sha256/#{sha256_hash}", input: {format: 'json'})

    # raise exception if JSON is invalid
    JSON.parse!(response.body)

    new(sha256_hash: sha256_hash, raw_json: response.body)

  rescue ApiRequester::ApiRequester::ApiRequesterNotFoundError
    new(sha256_hash: sha256_hash, raw_json: "{\"error\":\"Not in RL\"}")
  end

  # Makes an immediate call to get up to date reversing labs results and stores data in cache and database.
  # @param [String] sah256_hash the SHA256 hash checksum.
  # @return [FileReputationApi::ReversingLabs] object for the result.
  def self.lookup_immediate(sha256_hash)
    rev_lab = lookup_raw(sha256_hash)

    Rails.cache.write(rev_lab.cache_key, rev_lab.raw_json)

    rev_lab
  end

  # Gets the reversing labs data.  May read cached data, so might not be immediate.
  # @param [String] sah256_hash the SHA256 hash checksum.
  # @return [FileReputationApi::ReversingLabs] object for the result.
  def self.lookup(sha256_hash)
    cached_json = Rails.cache.read(cache_key(sha256_hash))

    if cached_json.blank?
      lookup_immediate(sha256_hash)
    else
      new(sha256_hash: sha256_hash, raw_json: cached_json)
    end
  end
end