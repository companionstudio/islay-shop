class PromotionCompetitionEntryEffect < PromotionEffect
  desc "General purpose / competition entry"
  condition_scope :order

  metadata(:config) do
    string :name, :required => true
  end

  def apply!(order, results)
    result("Qualified for #{name}")
  end
end
