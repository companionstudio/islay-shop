class PromotionMembershipCondition < PromotionCondition
  desc  "Membership"
  condition_scope :order
  exclusivity_scope :none
  position 7

  def check(order)
    if order.member_order.present?
      success
    else
      failure(:not_a_member, "You need to sign in to the club")
    end
  end
end
