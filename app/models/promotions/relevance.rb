module Promotions
  # A module used to determine a set of promotions relevancy to portions of the
  # shop. For example, it allows for easy look up of all active promotions 
  # somehow related to a SKU.
  module Relevance
    # Encapsulates the promotions returned by any of the #to_* methods in this
    # module. It provides some conveniences for checking which promotions are
    # directly related to the query target — product, sku etc.
    class Results < Array
      # The object for which the resulting promotions are considered relevant.
      #
      # @attr_reader [Product, Sku, ProductCategory]
      attr_reader :candidate

      # Construct a new collection of results.
      # 
      # @param [Sku, Product, ProductCategory] candidate
      # @param Array<Promotion> promotions
      # @todo Extend to wrap each promotion in a decorator.
      # @api private
      def initialize(candidate, promotions)
        @for_sku = {}
        @candidate = candidate
        super(promotions.map {|p| Promotions::Decorator.new(p)})
      end

      # Returns a collection of promotions that are directly related to the
      # candidate object.
      #
      # @return Results<Promotion>
      def direct
        @direct ||= select(&direct_predicate)
      end

      # Returns a collection of promotions that are not directly related to the
      # candidate object.
      #
      # @return Results<Promotion>
      def indirect
        @indirect ||= reject(&direct_predicate)
      end

      # Checks to see if there are any promotions directly related to the 
      # candidate object.
      #
      # @return [true, false]
      def direct?
        !direct.empty?
      end

      # Checks to see if there are any promotions that are not directly related 
      # to the candidate object.
      #
      # @return [true, false]
      def indirect?
        !indirect.empty?
      end

      # Finds any promotions which are directly related to the specified SKU.
      # Directly is defined as:
      #
      # - Condition refers to Sku
      # - Effect refers to Sku
      #
      # @param Sku sku
      # @return Results<Promotion>
      def for_sku(sku)
        @for_sku[sku] ||= begin
          id = sku.id.to_s
          select do |p|
            cs = p.conditions.map {|c| c.config['sku_id']}
            es = p.effects.map {|e| e.config['sku_id']}
            (cs + es).compact.include?(id)
          end
        end
      end

      # Checks to see if there are any promotions within these results that are
      # directly related to the specified Sku.
      #
      # @param Sku sku
      # @return [true, false]
      def for_sku?(sku)
        !for_sku(sku).empty?
      end

      private

      # Generates the block used by the #direct method. It is specialised based
      # on the type of @candidate.
      #
      # @return Proc
      def direct_predicate
        @direct_predicate ||= begin
          field = case candidate
          when Sku then 'sku_id'
          when Product then 'product_id'
          when ProductCategory then 'product_category_id'
          end

          id = candidate.id.to_s

          proc do |p|
            cs = p.conditions.map {|c| c.config[field]}
            es = p.effects.map {|e| e.config[field]}
            (cs + es).compact.include?(id)
          end
        end
      end
    end

    # Finds any promotions that are relevant to the specified SKU. Relevance is
    # determined by the following:
    #
    # - Effect or Condition directly relates to SKU
    # - Condition relates to SKU's product
    # - Condition relates to SKU's category; via product
    #
    # @param Sku sku
    # @return Array<Promotion>
    def self.to_sku(sku)
      args = {
        :sku_id               => sku.id, 
        :product_id           => sku.product_id, 
        :product_category_id  => sku.product.product_category_id
      }

      query = %{
        EXISTS (
          SELECT 1 FROM promotion_conditions AS pcs
          WHERE pcs.promotion_id = promotions.id AND (
            config -> 'sku_id' = ':sku_id'
            OR
            config -> 'product_id' = ':product_id'
            OR
            config -> 'product_category_id' IN (
              SELECT id::text FROM product_categories AS pcs
              WHERE pcs.path @> (SELECT path FROM product_categories WHERE id = :product_category_id)
            )
          )
        )
        OR EXISTS (
          SELECT 1 FROM promotion_effects AS pes
          WHERE pes.promotion_id = promotions.id AND config -> 'sku_id' = ':sku_id'
        )
      }

      Results.new(sku, Promotion.active.where(query, args).includes(:conditions, :effects))
    end

    # Finds any promotions relevant to the specified Product. Relevance is 
    # determined by the following:
    #
    # - Effect or condition directly relates to any of the product's SKUs
    # - Condition relates to product
    # - Condition relates to product category or any of it's ancestors
    #
    # @param Product product
    # @return Array<Promotion>
    def self.to_product(product)
      args = {
        :product_id           => product.id,
        :sku_ids              => product.skus.pluck(:id).map(&:to_s),
        :product_category_id  => product.product_category_id
      }

      query = %{
        EXISTS (
          SELECT 1 FROM promotion_conditions AS pcs
          WHERE pcs.promotion_id = promotions.id AND (
            config -> 'sku_id' IN (:sku_ids)
            OR
            config -> 'product_id' = ':product_id'
            OR
            config -> 'product_category_id' IN (
              SELECT id::text FROM product_categories AS pcs
              WHERE pcs.path @> (SELECT path FROM product_categories WHERE id = :product_category_id)
            )
          )
        )
        OR EXISTS (
          SELECT 1 FROM promotion_effects AS pes
          WHERE pes.promotion_id = promotions.id AND config -> 'sku_id' IN (:sku_ids)
        )

      }

      Results.new(product, Promotion.active.where(query, args).includes(:conditions, :effects))
    end
  end
end
