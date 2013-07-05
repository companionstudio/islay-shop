class PromotionCompetitionEntryEffect < PromotionEffect
  desc "General purpose / competition entry"

  metadata(:config) do
    string :name, :required => true
  end

  def apply!(order, qualifications)
    nil
  end
end
