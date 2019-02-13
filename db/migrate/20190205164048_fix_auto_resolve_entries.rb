class FixAutoResolveEntries < ActiveRecord::Migration[5.2]
  def change
    entries = DisputeEntry.joins(:dispute).where(disputes: {resolution: "All Auto Resolved"})
    entries.each do |e|
      e.status = "RESOLVED_CLOSED"
      e.save!
    end
  end
end
