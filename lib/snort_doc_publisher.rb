require 'nvd_cve_item'

# Utility class to manage publishing snort rule doc data to snort.org.
# Object instantiations of this class handle a specific year of data.
class SnortDocPublisher
  attr_reader :year, :references, :errors

  @errors = []
  class << self
    attr_reader :errors
  end

  # Clear cached class variables to allow garbage collection
  def self.clear_instance_variables
    clear_errors
    @undoc_cve_refs = nil
  end

  # @return [ActiveRecord::Relation<Reference>] cve references with missing cves records.
  def self.undoc_cve_refs
    @undoc_cve_refs ||= Reference.cves.left_joins(:cve).where(cves: {id: nil})
  end

  # @return [Hash<String => Array<Reference>>] cve references with missing cves records grouped by year.
  def self.undoc_cve_refs_by_year
    @undoc_cve_refs_by_year ||= undoc_cve_refs.inject({}) do |result, ref|
      year = ref.reference_data.sub(/\A(\d{4})-\d+\z/, '\\1')
      if year < '2002'
        year = '2002'
      end
      year

      result[year] ||= []
      result[year] << ref
      result
    end
  end

  # @return [Array<String>] The years of the undocumented references
  def self.years
    undoc_cve_refs_by_year.keys
  end

  # @yield [SnortDocPublisher] Publishers for cve references with missing cves records.
  def self.each_publisher
    SnortDocPublisher.undoc_cve_refs_by_year.each_pair do |year, undoc_refs|
      yield SnortDocPublisher.new(year: year, references: undoc_refs)
    end
  end

  # Clear cached errors attribute to allow garbage collection
  def self.clear_errors
    @errors = []
  end

  # Clear cached errors attribute to allow garbage collection
  def clear_errors
    @errors = []
  end

  # @params [String] year the given year for the CVEs to be updated
  # @params [Array<Reference>] The Reference objects to publish (those missing cves records)
  def initialize(year:, references: [])
    @year = year
    @references = references
    clear_errors
  end

  # @return [String] NIST NVD file name for the year
  def filename
    "nvdcve-1.0-#{@year}.json"
  end

  # @return [String] Diretory for downloaded NVD files
  def self.basepath
    'lib/data/nvd'
  end

  # Converts a given file name to a path where the downloaded NVD files are stored
  # @param [String|Pathname] filename
  # @return [Pathname] filepath to store NVD file from NIST
  def self.filepath(filename)
    Rails.root.join(basepath, filename)
  end

  # @return [Pathname] filepath to store NVD file from NIST
  def filepath
    self.class.filepath(filename)
  end

  # @return [Integer] this year right now
  def self.current_year
    @current_year ||= Time.now.year.to_i
  end

  # @return [Integer] this month right now
  def self.current_month
    @current_month ||= Time.now.month.to_i
  end

  # @return true if NVD data file for the year needs to be downloaded
  def download?
    case
      when year.to_i >= self.class.current_year
        true
      when (year.to_i == self.class.current_year - 1) && (1 == current_month)
        true
      when File.exist?(filepath)
        false
      else
        true
    end
  end

  # Internal method to download a given file
  # @param [String] The NIST NVD filename to download
  def self.download_file(filename)
    download_path = filepath(filename)
    cmd = "curl https://static.nvd.nist.gov/feeds/json/cve/1.0/#{filename}.gz > #{download_path}"
    # puts cmd
    system(cmd)
    if /\A(?<unzip_path>.*).gz\z/ =~ download_path.to_s
      cmd = "gunzip -f #{unzip_path}.gz"
      # puts cmd
      system(cmd)
    end
  end

  # Downloads the NVD data from NIST for the year (of this object)
  def download
    if download?
      self.class.download_file("#{filename}.gz")
    end
  end

  # For all references without cves records, download the NIST NVD files
  def self.download_all
    years.each do |year|
      publisher = SnortDocPublisher.new(year: year)
      publisher.download
    end
  end

  # @yield [cve_key, ref_rec, nvd_cve_item]
  # @yieldparam [String] cve_key CVE id as CVE-<year>-<index>
  # @yieldparam [Reference] ref_rec CVE reference record
  # @yieldparam [NvdCveItem] nvd_cve_item data read from a CVE from the NVD data file.
  def each_missing(max_fails: 3)
    references.each do |ref_rec|
      next if max_fails <= ref_rec.fail_count

      cve_key = "CVE-#{ref_rec.reference_data}"
      nvd_cve_item_curr = nvd_cve_item(cve_key)
      unless nvd_cve_item_curr
        @errors << "Cannot find NVD input data for #{cve_key.inspect}."
        ref_rec.fail_count ||= 0
        ref_rec.fail_count += 1
        ref_rec.save!
        next
      end

      yield cve_key, ref_rec, nvd_cve_item_curr
    end
  end

  # @return [Array<Hash>] data read from the year of NVD data file.
  def nvd_cve_items
    @nvd_cve_items ||= File.open(filepath, 'r') do |file|
      filedata = JSON.parse(file.read)
      filedata['CVE_Items']
    end
  end

  # @return [Hash] data for one CVE from NVD data file.
  def nvd_cve_item(cve_key)
    nvd_cve_item_hash = nvd_cve_items.find {|item| cve_key == item['cve']['CVE_data_meta']['ID']}
    return nil unless nvd_cve_item_hash
    NvdCveItem.new(nvd_cve_item_hash)
  end

  # Save the given data to the cves table
  def save_cve(cve_key, ref_rec, nvd_cve_item)
    cve_rec = ref_rec.build_cve(cve_key: cve_key, year: year)
    cve_rec.assign_attributes(nvd_cve_item.attributes)
    cve_rec.affected_systems = nvd_cve_item.affected_systems.join("\n")
    cve_rec.save!
  end

  # Save the given reference data to the references table
  def save_references(ref_rec, nvd_cve_item)
    nvd_cve_item.each_reference do |ref_type_name, ref_data|
      ref_type = NvdCveItem.reference_type(ref_type_name)

      case
        when ref_type.blank?
          @errors << "Unknown reference type '#{ref_type_name}'."
        when ref_rec.references.where(reference_type: ref_type, reference_data: ref_data).exists?
          # do nothing
        when Reference.where(reference_type: ref_type, reference_data: ref_data).exists?
          ref_rec.references << Reference.where(reference_type: ref_type, reference_data: ref_data).first
        else
          ref_rec.references.create(reference_type: ref_type, reference_data: ref_data)
      end
    end
  end

  # Update the reference for this object to the database (cves and references tables)
  def update_cve_data(max_fails: 3)
    each_missing(max_fails: max_fails) do |cve_key, ref_rec, nvd_cve_item|
      save_cve(cve_key, ref_rec, nvd_cve_item)
      save_references(ref_rec, nvd_cve_item)
    end
  end

  # Update all references without CVE data in the database (cves and references tables)
  def self.update_cve_data(max_fails: 3)
    clear_errors
    each_publisher do |publisher|
      publisher.clear_errors
      publisher.update_cve_data(max_fails: max_fails)
      @errors += publisher.errors
    end

    if block_given?
      yield @errors
    end

    clear_instance_variables
  end

  # Takes the parsed structure from the rule update YAML file and iterates rule data
  # @yeild [Hash] Hash of rule data
  def self.flatten_snort_doc_status(input_hash)
    input_hash.slice(*%w{modules rules}).each do |key, diff_new_hash|
      gid =
          case key
            when 'modules'
              3
            when 'rules'
              1
            else
              next
          end

      diff_new_hash.each do |diff_new, rule_hash|
        rule_hash.each do |sid, revs_hash|
          rev = revs_hash.keys.max

          yield( { gid: gid, sid: sid, rev: rev, diff_new: diff_new, on_off: revs_hash[rev] } )
        end
      end
    end
  end

  # Sets To Be Published snort_doc_status attributes on rules from rule update YAML structure
  def self.update_snort_doc_to_be(input_hash)
    flatten_snort_doc_status(input_hash) do |rule_hash|
      rule = Rule.by_sid(rule_hash[:sid], rule_hash[:gid])
                 .where.not(snort_doc_status: Rule::SNORT_DOC_STATUS_SUPRESS).first
      if rule
        rule.update(snort_doc_status: Rule::SNORT_DOC_STATUS_TO_BE_PUB)
      end
    end
  end

  # @param [Rule] rule
  # @return [Hash] Snort Doc hash for a given rule
  def self.rule_snort_doc(rule)
    snort_doc = rule.rule_doc.attributes.slice(*%w{summary impact details affected_sys attack_scenarios
        ease_of_attack false_positives false_negatives corrective_action contributors})

    snort_doc['gid'] = rule.gid
    snort_doc['sid'] = rule.sid
    snort_doc['rev'] = rule.rev
    snort_doc['message'] = rule.message

    snort_doc['cves'] = rule.references.cves.map do |cve_ref|
      if cve_ref.cve
        cve_ref.cve.attributes.slice(*%w{cve_key description severity
          base_score impact_score exploit_score confidentiality_impact integrity_impact availability_impact
          vector_string access_vector access_complexity authentication affected_systems})
      else
        errors << "No CVE record found for refernce #{cve_ref.id.inspect} #{cve_ref.reference_data.inspect}"
      end
    end.compact

    snort_doc
  end

  # @param [Array<Rule>] rules
  # @return [Arrah<Hash>] Snort Doc hashes for a collection of rules
  def self.rules_snort_doc(rules)
    rules.map {|rule| rule_snort_doc(rule)}
  end

  # @return [Array<Hash>] Snort Doc of all rules which had been marked as TO BE
  def self.to_be_snort_doc
    rules_snort_doc(Rule.where(snort_doc_status: Rule::SNORT_DOC_STATUS_TO_BE_PUB))
  end

  # Generate Snort Doc and mark rules as have been published
  # @return [Array<Hash>] Snort Doc of all rules which had been marked as to be published
  def self.gen_snort_doc_to_be
    to_be_snort_doc.tap do |doc|
      Rule.where(snort_doc_status: Rule::SNORT_DOC_STATUS_TO_BE_PUB)
          .update_all(snort_doc_status: Rule::SNORT_DOC_STATUS_BEEN_PUB)
    end
  end

  # Generate snort rule doc structure from rule update file contents
  # 1. Marks rules as to be published from input rule update data.
  # 2. Generates Structure representation of snort rule doc of all rules to be published
  # 3. Marks rules as have been published
  # @param [String] contents YAML string from rule update file
  # @return [Array<Hash>] Structure representation of snort rule doc, ready for upload
  def self.gen_snort_doc_from_yaml(contents)
    SnortDocPublisher.update_snort_doc_to_be(YAML.load(contents))
    gen_snort_doc_to_be
  end

  # Generate snort rule doc structure from rule update file name
  # 1. Marks rules as to be published from input rule update data.
  # 2. Generates Structure representation of snort rule doc of all rules to be published
  # 3. Marks rules as have been published
  # @param [String] filename path to rule update file
  # @return [Array<Hash>] Struture representation of snort rule doc, ready for upload
  def self.gen_snort_doc(filename = nil)
    SnortDocPublisher.update_snort_doc_to_be(YAML.load_file(filename)) if filename
    gen_snort_doc_to_be
  end

  def self.publish_snort_doc_from_yaml(contents, do_download: true, do_publish: true)
    SnortDocPublisher.download_all if do_download

    SnortDocPublisher.update_snort_doc_to_be(YAML.load(contents))

    to_be_snort_doc.tap do |doc|
      if do_publish
        Rule.where(snort_doc_status: Rule::SNORT_DOC_STATUS_TO_BE_PUB)
            .update_all(snort_doc_status: Rule::SNORT_DOC_STATUS_BEEN_PUB)
      end
    end
  end
end
