class CreateBugsUsers < ActiveRecord::Migration
  def change
    create_table :bugs_users, id: false do |t|
      t.belongs_to :bug, index: true
      t.belongs_to :user, index: true
    end
  end
end
