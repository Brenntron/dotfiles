class CreateJoinTableComplaintsComplaintTags < ActiveRecord::Migration[5.1]
  def change
    create_join_table :complaints, :complaint_tags do |t|
      t.index [:complaint_id, :complaint_tag_id], name: :idx_comp_comp_tag
      t.index [:complaint_tag_id, :complaint_id], name: :idx_comp_tag_comp
    end
  end
end
