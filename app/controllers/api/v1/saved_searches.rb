module API
  module V1
    class SavedSearches < Grape::API
      include API::V1::Defaults

      resource :saved_searches do

        desc "Delete a saved search"
        params do
          requires :id, type: Integer, desc: "saved search id"
        end
        delete '/:id' do
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
      end
    end
  end
end