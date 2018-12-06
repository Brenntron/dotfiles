class CreateAmpFalsePositiveFiles < ActiveRecord::Migration[5.1]
  def change
    create_table :amp_false_positive_files do |t|
      t.string :sha256
      t.string :name
      t.string :path
      t.string :download_url
      t.string :detection_name
      t.string :detection_count_within_org
      t.datetime :first_observed
      t.datetime :last_observed
      t.string :current_amp_disposition
      t.boolean :is_archived, default: false
    end
  end
end
