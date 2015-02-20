class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string "cvs_username"
      t.boolean "committer", :default => false
      t.boolean "confirmed", :default => false

      ## Database authenticatable
      t.string :email,              :null => false, :default => ""
      t.string :encrypted_password, :null => false, :default => ""

      ## Recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      ## Rememberable
      t.datetime :remember_created_at

      ## Trackable
      t.integer  :sign_in_count, :default => 0, :null => false
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string   :current_sign_in_ip
      t.string   :last_sign_in_ip

      t.string   :role
      t.integer   :class_level

      t.string   :authentication_token
      t.string   :bugzilla_token

      t.timestamps
    end
    add_index :users, :email,                :unique => true
    add_index :users, :reset_password_token, :unique => true
    add_reference :users, :bug, index: true
  end
end