# 69f3e339c070720906cf40499be79247dbb02758fbf08c72407f81645695c69e

class FileReputationApi::Detection
  include ActiveModel::Model
  include ApiRequester::ApiRequester
  set_api_requester_config Rails.configuration.amp_poke
  set_default_request_type :json
  #set_default_headers({})

  attr_accessor :score, :disposition, :got, :score_tg, :samples_disp, :state, :name, :samples_name
  # {"score"=>4,
  # "disposition"=>"unknown",
  # "got"=>"69f3e339c070720906cf40499be79247dbb02758fbf08c72407f81645695c69e",
  # "score_tg"=>nil,
  # "samples_disp"=>"unknown",
  # "state"=>"local",
  # "name"=>"Test.69F3E339C0.rgh.tht.Talos",
  # "samples_name"=>"Test.69F3E339C0.rgh.tht.Talos"}

  DISPOSITION_UNSEEN        = 'unseen'
  DISPOSITION_UNKNOWN       = 'unknown'
  DISPOSITION_MALICIOUS     = 'malicious'
  DISPOSITION_COMMON        = 'common'
  DISPOSITION_CLEAN         = 'clean'

  def sha256_hash
    self.got
  end

  def malicious?
    self.disposition.casecmp?(DISPOSITION_MALICIOUS)
  end

  def clean?
    self.disposition.casecmp?(DISPOSITION_CLEAN) || self.disposition.casecmp?(DISPOSITION_COMMON)
  end

  def clean_to_malicious?(disposition)
    clean? && disposition.casecmp?(DISPOSITION_MALICIOUS)
  end

  def same_name?(detection_name)
    if self.name.present?
      self.name.casecmp?(detection_name)
    else
      detection_name.blank?
    end
  end

  def same_disposition?(disposition)
    self.disposition.casecmp?(disposition)
  end

  def self.get_bulk(sha256_hash)
    response_struct = call_request_parsed(:get, "/v0/bulk/sha256/#{sha256_hash}")
    new(response_struct)
  end

  def put_bulk
    data = {
        "name" => self.name,
        "disposition" => self.disposition,
        "force" => 0
    }
    self.class.call_request_parsed(:put, "/v0/bulk/sha256/#{self.sha256_hash}", input: data)
  end

  def put_vrt
    data = {
        "score" => self.score,
        "state" => self.state,
        "disposition" => self.disposition,
        "force" => 0
    }
    self.class.call_request_parsed(:put, "/v0/vrt/sha256/#{self.sha256_hash}", input: data)
  end

  def put_tg
    data = {
        "score" => self.score_tg,
        "state" => self.state,
        "disposition" => self.disposition,
        "force" => 0
    }
    self.class.call_request_parsed(:put, "/v0/tg/sha256/#{self.sha256_hash}", input: data)
  end

  def change_detection_name(detection_name)
    self.name = detection_name
    put_bulk
  end

  def update(disposition:, detection_name: nil)

    if same_disposition?(disposition)
      unless detection_name.present?
        return { success: true, message: 'No change.' }
      end

      if same_name?(detection_name)
        return { success: true, message: 'No change.' }
      end

      unless malicious?
        return { success: false, error: 'Detection name cannot be changed unless sample is malicious.' }
      end
    end

    if clean_to_malicious?(disposition)
      return { success: false,
               error: 'Changing a sample from clean to malicious is prohibited.  You may change it to unknown first.' }
    end

    if malicious? && detection_name.present? && !same_name?(detection_name)
      self.name = detection_name
      put_bulk
    end

    if same_disposition?(disposition)
      return { success: true }
    end

    self.disposition = disposition
    self.name = detection_name if detection_name.present?
    put_bulk

    if self.score.present?
      put_vrt
    elsif self.score_tg.present?
      put_tg
    end

    { success: true, message: 'Change completed.' }
  end

  def self.update_detection(sha256_hash:, disposition:, detection_name: nil)
    detection = get_bulk(sha256_hash)
    result = detection.update(disposition: disposition, detection_name: detection_name)
    if result[:success]
      FileReputationDispute.where(sha256_hash: sha256_hash).update_all(disposition: detection.disposition,
                                                                       detection_name: detection.name)
    end
    result
  end

  def self.create_action(sha256_hashes:, disposition:, detection_name: nil)
    sha256_hashes.map do |sha256_hash|
      update_detection(sha256_hash: sha256_hash,
                       disposition: disposition,
                       detection_name: detection_name)
    end
  end
end
