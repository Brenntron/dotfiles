class EscalationBug < Bug

  validates :product, inclusion: { in: %w(Escalations), message: "EscalationBug must be 'Escalations' not %{value}" }

  # Test for this class.
  # Bugs are indicated as an escalation bug by product field, type field or class, and this method.
  # At the risk of creating inconsistencies, using this method may be preferred over kind_of?
  # because we can manipulate this method.  For instance determining what we want it to be for ClamAV bugs.
  # @return [Boolean] true iff kind_of?(EscalationBug)
  def escalation_bug?
    true #self.kind_of(EscalationBug)
  end
end
