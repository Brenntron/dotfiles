module API
  module V1
    class References < Grape::API
      include API::V1::Defaults

      resource :references do

        desc "Create a reference"
        params do
          requires :reference, type: Hash do
            requires :reference_data, type: String, desc: "the reference data"
            requires :type, type: String, desc: "what kind of reference this is"
            optional :bug_id, type: Integer, desc: "The id of a bug to which this reference can be assigned."
            optional :rule_id, type: Integer, desc: "The id of a rule to which this reference can be assigned."
          end
        end
        post "", root: "reference" do

          ref = Reference.create(
              :reference_data => permitted_params[:reference][:reference_data],
              :reference_type_id => ReferenceType.find_by_name(permitted_params[:reference][:type]).id
          )

          Bug.find(permitted_params[:reference][:bug_id]).references << ref if permitted_params[:reference][:bug_id]
          Rule.find(permitted_params[:reference][:rule_id]).references << ref if permitted_params[:reference][:rule_id]
          ref
        end

        desc "Update a reference"
        params do
          requires :reference, type: Hash do
            requires :reference_data, type: String, desc: "the reference data"
            requires :type, type: String, desc: "what kind of reference this is"
            optional :bug_id, type: Integer, desc: "The id of a bug to which this reference can be assigned."
            optional :rule_id, type: Integer, desc: "The id of a rule to which this reference can be assigned."
          end
        end
        put ":id", root: "reference" do
          puts "updating reference"
        end

        desc "Delete a reference"
        params do
          requires :id, type: Integer, desc: "The ID of the reference to be deleted."
        end
        delete ":id", root: "reference" do
          Reference.find(permitted_params[:id]).destroy
        end

      end
    end
  end
end
