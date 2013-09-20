module Promotions
  # Represents the result of checking multiple promotions against an order.
  class CheckResultCollection < Promotions::CollectionBase
    # Filters the results down to any that have a code within it's conditions.
    #
    # @return CheckResultCollection
    def code_based
      self.class.new(select {|r| r.promotion.code_based?})
    end
  end
end
