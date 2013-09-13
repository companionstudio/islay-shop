module Promotions
  # Base collection which has predicates for checking success/failure and 
  # filters for grabbing entries based on thier predicates e.g. successful
  # entries.
  class CollectionBase < Array
    # Checks to see if all the results are successful.
    #
    # @return [true, false]
    def successful?
      length > 0 and successful.length == length
    end

    # Checks to see if there are any partial results, all failures or a 
    # mixture of successful and failed results.
    #
    # @return [true, false]
    def partial?
      partial.length > 0 or (successful.length > 0 and successful.length < length)
    end

    # Simply, not successful.
    #
    # @return [true, false]
    def failed?
      !successful?
    end

    # Returns the promotions result for which an order qualifies.
    #
    # @return ResultCollection
    def successful
      @successful ||= select(&:successful?)
    end

    # Returns the promotions result for which an order partially qualifies.
    #
    # @return ResultCollection
    def partial
      @partial ||= select(&:partial?)
    end

    # Returns the promotion results for which an order does not qualify.
    #
    # @return ResultCollection
    def failed
      @failed ||= select(&:failed?)
    end
  end
end
