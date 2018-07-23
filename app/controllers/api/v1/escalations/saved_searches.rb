module API
  module V1
    module Escalations
      class SavedSearches < Grape::API
        include API::V1::Defaults

        resource :saved_searches do

          desc "Delete a saved search"
          params do
            requires :id, type: Integer, desc: "saved search id"
          end
          delete '/:id' do
            # TODO determine access control policy on saved searches
            begin
              saved_search = SavedSearch.where(:id => params[:id], :user_id => current_user.id).first
              if saved_search.present?
                saved_search.destroy
              end
              {:status => "success"}.to_json
            rescue
              Rails.logger.error "Saved Search filed to delete"
              Rails.logger.error $!
              Rails.logger.error $!.backtrace.join("\n")
              progress_bar.update_attribute("progress", -1)
              error = "There was an error when attempting to delete this saved search."
              {:error => error}.to_json
            end
          end

          desc "Create a saved search"
          params do
            optional :giblets, type: String, desc: "Giblet based saved search"
          end
          post "" do
            # TODO determine access control policy on saved searches
            begin

              if params[:giblets].present?

                giblet_ids = params[:giblets].split(',')

                giblets = Giblet.where(:id => giblet_ids)
                name = giblets.map {|g| g.display_name}.join(" ")
                session_query = "advance-search"
                session_search = {:giblets => giblet_ids}

                SavedSearch.create({:user_id => current_user.id, :name => name, :session_query => session_query, :session_search => session_search.to_json})

              end
              {:status => "success", :message => "saved search created."}.to_json

            rescue Exception => e
              Rails.logger.error "Bug failed to upload, backing out all DB changes."
              Rails.logger.error $!
              Rails.logger.error $!.backtrace.join("\n")
              error = "There was an error when attempting to save this search."
              {:error => error}.to_json
            end
          end

        end
      end
    end
  end
end