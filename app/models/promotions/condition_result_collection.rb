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
    def targets(name = nil)
      (name ? scope(name) : self).reduce({}) do |h, result|
        h.merge(result.targets)
      end
    end

    # Similar semantics to #targets, but the value is only the item 
    # count.
    #
    # @param Symbol name
    # @return Hash<OrderItem, Integer>
    def target_counts(name = nil)
      (name ? scope(name) : self).reduce({}) do |h, result|
        h.merge(result.target_counts)
      end
    end

    # Similar semantics to #targets, but the value is only the item 
    # qualifications.
    #
    # @param Symbol name
    # @return Hash<OrderItem, Integer>
    def target_qualifications(name = nil)
      (name ? scope(name) : self).reduce({}) do |h, result|
        h.merge(result.target_qualifications)
      end
    end
  end
end
