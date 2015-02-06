module API
  module V1
    class Rules < Grape::API
      include API::V1::Defaults

      resource :rules do
        desc "Return all rules"
        get "", root: :rules do
          Rule.all
        end

        desc "Return a rule"
        params do
          requires :id, type: String, desc: "ID of the rule"
        end
        get ":id", root: "rule" do
          Rule.where(id: permitted_params[:id])
        end


        #create a rule via sid
        def create
          begin
            raise Exception.new("No rules to add") if params[:record].nil?
            raise Exception.new("No rules to add") if params[:record][:content].nil?
            raise Exception.new("No rules to add") if params[:record][:content] == ""
            text_rules = params[:record][:content].each_line.to_a.sort.uniq.map {|t| t.chomp}.compact.reject {|e| e.empty?}
            raise Exception.new("No rules to add") if text_rules.empty?
            @bug = Bug.find(active_scaffold_session_storage[:constraints][:bugs])

            # Loop through all of the rules
            text_rules.each do |text_rule|
              begin
                params[:record][:content] = text_rule

                if text_rule =~ / sid:(\d+);/
                  @record = Rule.find_rule($1)
                  @record.bugs << @bug
                  update_save

                  if @record.errors.size > 0
                    rule.content << "#{text_rule}\n"

                    @record.errors.each do |s, e|
                      rule.errors.add(:base, e)
                    end
                  end
                else
                  do_create
                  if successful?
                    @record.reload
                    @record.rule_state = RuleState.New
                    @record.save
                  else
                    if @record.errors.size > 0
                      rule.content << "#{text_rule}\n"

                      @record.errors.each do |s, e|
                        rule.errors.add(:base, e)
                      end
                    end
                  end
                end
              rescue Exception => e
                rule.content << "#{text_rule}\n"
                rule.errors.add(:base, e.to_s)
              end
            end

          rescue Exception => e
            rule.errors.add(:base, e.to_s)
          end

          # We may need to set the form back
          if rule.errors.size > 0
            params[:record][:content] = rule.content
            @record = rule
            self.successful = false
          end

          respond_to_action(:create)

        end
        #import a rule

        #create multiple rules

        #edit a rule

        #update a rule
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

        #delete a rule
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



      end
    end
  end
end