class Rule < ActiveRecord::Base
  has_and_belongs_to_many :bugs
  has_and_belongs_to_many :references
  has_and_belongs_to_many :attachments


  def create(content)
      begin
        raise Exception.new("No rules to add") if content.blank?
        text_rules = content.each_line.to_a.sort.uniq.map {|t| t.chomp}.compact.reject {|e| e.empty?}
        raise Exception.new("No rules to add") if text_rules.empty?


        # Loop through all of the rules
        text_rules.each do |text_rule|
          begin
            unless text_rule =~ / sid:(\d+);/ #if we find the rule then we dont need to create it
              #otherwise we need to create the rule
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

        if not parsed['references'].nil?
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
      raise RuleError.new("Rule has no content") if rule.nil?

      # Cache this output as well to speed up any changes
      message = Rails.cache.fetch("rules.content.#{Digest::MD5::hexdigest(rule)}") do
        Open3.popen3("#{Rails.configuration.rule2yaml_path}") do |i,o,e|
          i.puts rule
          i.close
          # response = o.read.encode(Encoding.find('ASCII'), {:invalid => :replace, :undef => :replace, :replace => '', :universal_newline => true}).gsub(/[\x7f-\xff]/, '')
          data = YAML.load(response)

          if data.nil? or data == false
            raise RuleError.new('Unable to load yaml output from rule2yaml')
          end

          unless data['failed'].nil?
            raise RuleError.new(data['failed'])
          end

          # Looks like it parsed it so just return the data
          data
        end
      end

    rescue Psych::SyntaxError => e
      raise RuleError.new("Can't parse invalid yaml data: #{rule}")
    end

    return message
  end

  def self.parse_and_create_rule(rule)
    r = Rule.new(:content => rule)
    return r.extract_rule ? r : nil
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
      remove_rule_from_bug(Bug.find(active_scaffold_session_storage[:constraints][:bugs]), Rule.find(params[:id]) )
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
    rule = Rule.where("sid = ?",(Rule.parse_rule(body)['sid']))

    if rule.nil?
      rule = Rule.create(:content => body)
      rule.rule_state = RuleState.Unchanged
    else
      rule.content = body
      rule.rule_state = RuleState.Unchanged
    end

    rule.save

    return rule
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
  def self.rule_exist?(sid)
    return Rule.find_current_rule(sid).blank? ? true : false
  end
  def self.update_generate_rule(sid)
    return Rule.create_or_update_rule(Rule.find_current_rule(sid))
  end

  def self.update_rules(rules)
    ActiveRecord::Base.transaction do
      rules.each do |rule|
        rule.save
      end
    end
  end

end