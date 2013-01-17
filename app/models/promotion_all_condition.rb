class PromotionAllCondition < PromotionCondition
  desc "Any order qualifies"

  def qualifications(order)
    {:order => 1}
  end

  def qualifies?(order)
    true
  end
end