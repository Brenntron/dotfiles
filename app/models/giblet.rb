class Giblet < ApplicationRecord
  belongs_to :bug
  belongs_to :gib, polymorphic: true
  #a giblet is either a tag, a stripped summary, a reference, or a sid/sidlist

  def display_name
    displ = ""
    if gib_type == "Tag" || gib_type == "Whiteboard"
      displ = gib.name
    end
    if gib_type == "Reference"
      if gib.reference_type.name == "cve"
        displ = "CVE-#{gib.reference_data}"
      elsif gib.reference_type.name == "bugtraq"
        displ = "BT#{gib.reference_data}"
      else
        displ = gib.reference_data
      end
    end

    displ
  end

end