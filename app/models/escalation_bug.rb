class EscalationBug < Bug
  def escalation_bug?
    true #self.kind_of(EscalationBug)
  end
end
