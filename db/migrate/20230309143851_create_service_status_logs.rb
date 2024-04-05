class CreateServiceStatusLogs < ActiveRecord::Migration[5.2]
  def change
    create_table :service_status_logs do |t|
      t.integer         :service_status_id
      t.mediumtext     :exception
      t.mediumtext     :exception_details
      t.timestamps
    end
  end
end
