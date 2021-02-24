class AddPublicEngineDescriptionToAmpNamingConventions < ActiveRecord::Migration[5.2]
  def change
    add_column :amp_naming_conventions, :public_engine_description, :text
  end
end
