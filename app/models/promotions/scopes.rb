module Promotions
  # This module acts as a singleton which encapsulates the configuration of 
  # promotion condition scopes. Scopes are related in a hierarchy. This module
  # simplifies compiles the scopes into data structures ready for querying and
  # provides helper predicates for checking where provided scopes fall within
  # the hierarchy.
  module Scopes
    # A predicate which checks to see if the scope provided by a condition 
    # meets the needs of an effect. In other words; are a condition and effect
    # compatible?
    #
    # @param Symbol provides
    # @param Symbol needs
    # @return [true, false]
    def self.acceptable?(provides, needs)
      provides == needs or (LOOKUP.has_key?(needs) and LOOKUP[needs].include?(provides))
    end

    # Inspects the PromotionEffect Subclasses and collects the names of those
    # that have scopes compatible with the provided PromotionCondition.
    #
    # @param PromotionCondition condition
    # @return Array<Symbol>
    def self.compatible_effects(condition)
      scope = condition.promo_config[:condition_scope]
      
      PromotionEffect.effect_classes.reduce([]) do |compatible, effect|
        if acceptable?(scope, effect.promo_config[:condition_scope])
          compatible << effect.short_name 
        end
        compatible
      end
    end

    private

    # Takes a nested Hash and compiles it into an array of arrays, where each
    # value is a path or sub-path within the nested hash.
    #
    # @param Hash hash
    # @param Array<Symbol> path
    # @return Array<Array<Symbol>>
    def self.compile(hash, path = [])
      output = []

      hash.each do |k, v|
        case v 
        when Hash
          output.concat(compile(v, path + [k]))
          v.each do |vk, vv| 
            output.concat(compile(vv, [vk]))
            output.concat(compile(vv))
          end
        when Array
          output << (path + [k] + v)
        end
      end

      output
    end

    # Defines the heirarchy of scopes. Never used directly, but provides a 
    # convenient way of documenting and modifying scopes. It is compiled into
    # a more convenient data structure for lookup below.
    HIERARCHY = {
      :order => {
        :items => {
          :sku_items => [
            :manufacturer,
            :product_category,
            :product,
            :sku
          ],
          :service_items => [:shipping_item]
        }
      }
    }.freeze

    # This Hash is a simple structure, where the key is a scope and the value 
    # is and an Array consisting of the decendents of the scope.
    #
    # The HEIRARCHY is first compiled into an array of arrays. Each value is
    # all the possible paths and sub-paths in the tree. This is then reduced
    # into a Hash, which the value being a set. Paths with a duplicate start
    # entry are merged.
    LOOKUP = compile(HIERARCHY).reduce({}) do |h, v|
      key = v.shift
      if h.has_key?(key)
        h[key].merge(v)
      else
        h[key] = Set.new(v)
      end

      h
    end
  end
end
