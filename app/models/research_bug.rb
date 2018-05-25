class ResearchBug < Bug

  validates :product, inclusion: { in: %w(Research), message: "ResearchBug must be 'Research' not %{value}" }

  # Test for this class.
  # Bugs are indicated as a research bug by product field, type field or class, and this method.
  # At the risk of creating inconsistencies, using this method may be preferred over kind_of?
  # because we can manipulate this method.  For instance determining what we want it to be for ClamAV bugs.
  # @return [Boolean] true iff kind_of?(ResearchBug)
  def research_bug?
    true
  end
end

