module Promotions
  # A nice class for wrapping the individual results generated when a 
  # collection checks an order against each of it's conditions.
  class ConditionResultCollection < Promotions::CollectionBase
    # Filters the results to just those with the specified scope.
    #
    # @return ResultCollection
    def scope(name)
      select {|r| r.scope == name}
    end

    # Returns a map of the order items which in some way 'qualify' for the 
    # conditions. Generally only meaningful when the result is successful, 
    # but useful when an order partially qualifies.
    #
    # Hash is keyed by OrderItem, with the value being the number of 
    # qualifications.
    #
    # Can optionally by filtered down by providing a scope.
    #
    # @param Symbol name
    # @return Hash<OrderItem, Numeric>
    def merged_targets(name = nil)
      @targets ||= (name ? scope(name) : self).reduce({}) do |h, result|
        result.targets.each do |target, q|
          if h.has_key?(target)
            h[target] + q
          else
            h[target] = q
          end
        end

        h
      end
    end

    # A sum of all the qualifications e.g. across 'target' OrderItem, sum up 
    # the number of qualifications.
    #
    # @return Numeric
    def targets_sum
      merged_targets.values.sum
    end
  end
end
