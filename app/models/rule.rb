class Rule < ActiveRecord::Base
  has_and_belongs_to_many :bugs
  has_and_belongs_to_many :references, dependent: :destroy

  def self.create_a_rule(content)
    begin
      raise Exception.new("No rules to add") if content.blank?
      text_rules = content.each_line.to_a.sort.uniq.map { |t| t.chomp }.compact.reject { |e| e.empty? }
      raise Exception.new("No rules to add") if text_rules.empty?
      # Loop through all of the rules
      text_rules.each do |text_rule|
        begin
          if text_rule =~ / sid:(\d+);/ #if this rule has a sid then we can attempt to create it
            @record = Rule.update_generate_rule($1)
            @record.state = "New"
            @record.rev = 1
            @record.save
          end
        rescue Exception => e
          raise Exception.new("{rule_error: {content: #{text_rule},error:#{e.to_s}}}")
        end
      end
    rescue Exception => e
      raise Exception.new("{rule_error: {content: 'Error creating rule.', error:#{e.to_s}}}")
    end
  end

  def self.import_rule(sid)
    if sid
      value = `grep -Hrn "sid:#{sid}" #{Rails.root}/extras/snort`
      split_string = value.split(/:\d[\d]*:/)
      rule_text = split_string[1].strip!
      new_rule = Rule.create(Rule.parse_and_create_rule(rule_text))
      new_rule.associate_references(rule_text)
      new_rule
    else
      raise "No rule sid provided"
    end
  end

  def extract_rule
    begin
      if not self.content.nil?

        # Make sure we don't have multiple rules in one
        if self.content =~ /[\r\n]/
          raise "Only create one rule at a time"
        end

        # First make sure we can parse it
        parsed = Rule.parse_rule(self.content)


        if parsed.nil?
          raise "Failed to parse rule"
        end

        if not parsed['sid'].nil? and not self.sid.nil?
          raise "Mismatched sid in updated rule. Expected #{self.sid} not #{parsed['sid']}" if parsed['sid'] != self.sid
        end

        self.message = parsed['name']
        self.gid = 1
        self.sid = parsed['sid']
        self.rev = parsed['revision']
        self.content = parsed['optomized']

        unless parsed['references'].nil?
          parsed['references'].each do |type, ref|
            begin
              reference_type = ReferenceType.find_by_name(type)

              unless reference_type.nil?
                reference = Reference.find_or_create_by_reference_type_id_and_data(reference_type.id, ref.keys.first)

                if not self.references.empty?
                  if not self.references.includes?(reference)
                    self.references << reference
                  end
                end
              end
            rescue ActiveRecord::RecordNotUnique => e
              # Ignore
            rescue SQLite3::ConstraintException => e
              # Ignore
            rescue Exception => e
              raise
            end
          end
        end
      elsif gid.nil?
        raise "Neither gid nor sid content is set"
      end
      return true
    rescue Exception => e
      self.errors.add(:base, e.to_s)
      e.backtrace.each do |l|
        self.errors.add(:base, l)
      end
      return false
    end
  end

  def self.parse_rule(rule)
    begin
      raise Exception.new("Rule has no content") if rule.nil?
      # Cache this output as well to speed up any changes
      message = Rails.cache.fetch("rules.content.#{Digest::MD5::hexdigest(rule)}") do
        data ={}
        # parse the rule
        split_rule = rule.scan(/(\w+:)([^\;]*)/)
        split_rule.each do |key, value|
          data[key.gsub(":", "")] = value
        end
        return data
      end
      return message
    rescue Exception => e
      raise Exception.new("{rule_parse_error: {content: #{rule},error:#{e.to_s}}}")
    end
  end

  def associate_references(rule_text)
    references = []
    rule_text.split(';').each {|r| references << r.strip.gsub!('reference:', '') if r.include? "reference" }
    references.each do |r|
      r = r.split(',')
      unless r[1].empty?
        new_reference = Reference.create(reference_type:ReferenceType.where(name:r[0]).first,reference_data:r[1])
        self.references << new_reference
      end
    end
  end

  def self.parse_and_create_rule(rule)
    rule_sid = /sid:\s*(\d+)\s*;/.match(rule) ? /sid:\s*(\d+)\s*;/.match(rule)[1].to_i : nil
    options = {
        :id            => rule_sid,
        :sid           => rule_sid,
        :rule_content  => rule,
        :gid           => 1,
        :rev           => /rev:(\S*?);/.match(rule) ? /rev:(\S*?);/.match(rule)[1].strip.to_i : 1,
        :connection    => /(.*?)\(/.match(rule)[1].strip,
        :message       => /msg:"(.*?)"/.match(rule)[1].strip,
        :detection     => /flow:.*?;(.*?)(metadata|reference):/.match(rule)[1].strip,
        :flow          => /flow:(.*?);/.match(rule)[1].strip,
        :metadata      => /metadata:(.*?);/.match(rule) ? /metadata:(.*?);/.match(rule)[1].strip : nil ,
        :class_type    => /classtype:*(.*?);/.match(rule) ? /classtype:*(.*?);/.match(rule)[1].strip : nil,
        :committed     => true,
        :state         => rule_sid ? 'UNCHANGED' : 'NEW'
    }.reject() { |k, v| v.nil? }
  end

  def update_rule
    begin
      rule = Rule.find_rule(Rule.find(params[:id]).sid) # This will update if found
      rule.rule_state = RuleState.Unchanged
      rule.attachments.clear
      rule.save(:validate => false)

    rescue Exception => e
      log_error(e)
    rescue RuleError => e
      add_error("#{rule.sid}: #{e.to_s}")
    end

    redirect_to request.referer
  end

  def remove_rule
    begin
      remove_rule_from_bug(Bug.find(active_scaffold_session_storage[:constraints][:bugs]), Rule.find(params[:id]))
    rescue Exception => e
      log_error(e)
    end

    redirect_to request.referer
  end

  def remove_rule_from_bug(bug, rule)
    # Remove any new alerts from the attachments
    if rule.rule_state == RuleState.New
      bug.attachments.each do |attachment|
        attachment.rules.delete(rule)
      end
    end

    # Remove the rule reference
    bug.rules.delete(rule)

    # Remove this rule if it is no longer needed
    rule.destroy if rule.bugs.empty? and rule.attachments.empty?
  end

  def self.create_or_update_rule(body)
    begin
      parsed = Rule.parse_rule(body)
      rule = Rule.where("sid = ?", parsed['sid']).first
      if rule.empty?
        rule = Rule.create(:content => body)
        rule.gid = 1
        rule.message = parsed['msg'].gsub("\"", "")
        rule.sid = parsed['sid']
        rule.rev = parsed['revision']
        rule.state = "Unchanged"
      else
        rule.content = body
        rule.message = parsed['msg'].gsub("\"", "")
        rule.gid = 1
        rule.sid = parsed['sid']
        rule.rev = parsed['revision']
        rule.state = "Unchanged"
      end
      rule.save
      return rule
    rescue Exception => e
      raise Exception.new(e)
    end
  end

  def self.find_current_rule(sid)
    Dir.entries(Rails.configuration.snort_rule_path).each do |f|

      # Don't include .stub.rules hidden rule files
      if f =~ /^[^\.]/ and f =~ /\.rules$/
        File.read("#{Rails.configuration.snort_rule_path}/#{f}").each_line do |line|
          line = line.chomp.gsub(/^# /, '')

          if line =~ /sid:#{sid};/
            return line
          end
        end
      end
    end

    raise RuleError.new("Unable to find sid #{sid}")
  end

  def self.update_generate_rule(sid)
    begin
      return Rule.create_or_update_rule(Rule.find_current_rule(sid))
    rescue Exception => e
      raise Exception.new(e)
    end
  end

  def self.update_rules(rules)
    ActiveRecord::Base.transaction do
      rules.each do |rule|
        rule.save
      end
    end
  end

end