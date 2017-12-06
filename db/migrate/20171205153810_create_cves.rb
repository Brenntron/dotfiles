class CreateCves < ActiveRecord::Migration[5.1]
  def change
    create_table :cves do |t|
      t.timestamps
      t.string :year, null: false
      t.string :cve_key, null: false
      t.text :description
      t.string :severity
      t.float :base_score
      t.float :impact_score
      t.float :exploit_score
      t.string :confidentiality_impact
      t.string :integrity_impact
      t.string :availability_impact
      t.string :vector_string
      t.string :access_vector
      t.string :access_complexity
      t.string :authentication
      t.longtext :affected_systems
    end
    add_index :cves, :reference_id, unique: true
    add_index :cves, :cve_key, unique: true
  end
end
