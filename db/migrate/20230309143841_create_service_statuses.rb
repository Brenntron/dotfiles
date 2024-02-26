class CreateServiceStatuses < ActiveRecord::Migration[5.2]
  def change
    create_table :service_statuses do |t|
      t.string             :name
      t.string             :model
      t.integer            :exception_count
      t.timestamps
    end
  end
end
