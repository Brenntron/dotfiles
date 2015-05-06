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
            optional :classType, type: String, desc: "The type of rule"
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
              :summary => permitted_params[:rule][:summary],
              :version => permitted_params[:rule][:version],
              :description => permitted_params[:rule][:description],
              :state => permitted_params[:rule][:state],
              :creator => permitted_params[:rule][:creator],
              :opsys => permitted_params[:rule][:opsys],
              :platform => permitted_params[:rule][:platform],
              :priority => permitted_params[:rule][:priority],
              :severity => permitted_params[:rule][:severity],
              :classification => permitted_params[:rule][:classification]
          }.reject() { |k, v| v.nil? || v.empty? } #remove any nil or empty values in the hash(bugzilla doesnt like them)
          # new_bug = Bugzilla::Bug.new(bugzilla_session).create(options) #the bugzilla session is where we authenticate
          # new_bug_id = new_bug["id"]
          Rule.create(
              # :id => new_bug_id,
              # :bugzilla_id => new_bug_id,
              :connection => permitted_params[:rule][:connection],
              :message => permitted_params[:rule][:message],
              :summary => permitted_params[:bug][:summary],
              :version => permitted_params[:bug][:version],
              :description => permitted_params[:bug][:description],
              :state => permitted_params[:bug][:state] || 'OPEN',
              :creator => permitted_params[:bug][:creator],
              :opsys => permitted_params[:bug][:opsys],
              :platform => permitted_params[:bug][:platform],
              :priority => permitted_params[:bug][:priority],
              :severity => permitted_params[:bug][:severity],
              :classification => permitted_params[:bug][:classification] || 0 #api won't get bugs with classification of nil
          )
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