module API
  module V1
    class Rules < Grape::API
      include API::V1::Defaults

      resource :rules do

        #get all the rules OR get a rule by sid parameter
        desc "Return all rules"
        params do
          optional :sid, type: String, desc: "SID of the rule"
        end
        get "", root: :rules do
          if permitted_params[:sid]
            Rule.where(sid: permitted_params[:sid]).first
          else
            Rule.all
          end
        end

        desc "import all existing rules"
        get 'import_all' do
          true
        end


        desc "import existing rule"
        params do
          requires :id, type: Integer, desc: "rule sid."
        end
        route_param "import/:id" do
          get do
            #grep in the extras/snort folder for the sid number that is supplied
            value = `grep -Hrn "sid:#{permitted_params[:id]}" #{Rails.root}/extras/snort`
            split_string = value.split(/:\d[\d]*:/)
            puts "filename = #{split_string[0]}"
            puts "Rule = #{split_string[1]}"
            true
          end
        end

        # get a single rule
        desc "Return a rule"
        params do
          requires :id, type: String, desc: "ID of the rule"
        end
        get ":id", root: "rule" do
          Rule.where(id: permitted_params[:id]).first
        end

        #create rule using rule text
        desc "create a rule"
        params do
          requires :rule, type: Hash do
            requires :connection, type: String, desc: "The connection string"
            requires :message, type: String, desc: "The message describing the rule"
            requires :detection, type: String, desc: "The detection for this rule"
            optional :flow, type: String, desc: "The flow"
            optional :metadata, type: String, desc: "Any meta data that goes with this"
            optional :classification, type: String, desc: "The type of rule"
            optional :references, type: String, desc: "any references this rule has"
            optional :sid, type: Integer, desc: "the sid number"
            optional :gid, type: Integer, desc: "the gid number"
            optional :rev, type: Integer, desc: "the version of the rule"
            optional :state, type: String, desc: "The state of the bug, Open, Closed, ReOpened,etc"
            optional :average_check, type: String, desc: "The person who created the bug"
            optional :average_match, type: String, desc: "The operating system that this bug affects"
            optional :average_nonmatch, type: String, desc: "What platform this bug runs on"
            optional :tested, type: String, desc: "How soon should this bug get fixed"
            optional :created_at, type: String, desc: "How terrible is this bug"
            optional :updated_at, type: Integer, desc: "Who should see this bug. Higher classification restricts more people from seeing it."
            # all the params we need to permit must to go here
          end
        end
        post "", root: "rule" do
          options = {
              :connection => permitted_params[:rule][:connection],
              :message => permitted_params[:rule][:message],
              :detection => permitted_params[:rule][:detection],
              :flow => permitted_params[:rule][:flow],
              :metadata => permitted_params[:rule][:metadata],
              :classification => permitted_params[:rule][:classification],
              :sid => permitted_params[:rule][:sid] || Time.now.to_i,
              :gid => permitted_params[:rule][:gid] || 1,
              :rev => permitted_params[:rule][:rev] || 1,
              :state => permitted_params[:rule][:state],
              :tested => permitted_params[:rule][:tested],
              :average_check => permitted_params[:rule][:average_check],
              :average_match => permitted_params[:rule][:average_match],
              :average_nonmatch => permitted_params[:rule][:average_nonmatch],
              :created_at => permitted_params[:rule][:created_at],
              :updated_at => permitted_params[:rule][:updated_at]
          }.reject() { |k, v| v.nil? } #remove any nil values in the hash
          new_rule = Rule.create(options)
          unless permitted_params[:rule][:references].empty?
            new_rule.associate_references(permitted_params[:rule][:references])
          end
          new_rule
        end

        #import rule via sid
        params do
          requires :sid, type: String, desc: "ID of the rule"
        end
        post "import/:sid", root: "rule" do
          Rule.import(permitted_params[:sid])
        end

        #import multiple rules
        params do
          group :sids, :type => Array
          requires :id, desc: "IDs of the rules you wish to import"
        end
        post "import_multiple/:sids", root: "rule" do
          Rule.import_multiple(params[:sids])
        end

        #update a rule
        params do
          requires :id, type: Integer, desc: "the id for the rule to be updated"
        end
        post "update", root: "rule" do
          Rule.update(permitted_params[:id])
        end

        #delete a rule
        params do
          requires :id, type: Integer, desc: "the id for the rule to be deleted"
        end
        delete "delete", root: "rule" do
          Rule.remove_rule(permitted_params[:id])
        end

      end
    end
  end
end