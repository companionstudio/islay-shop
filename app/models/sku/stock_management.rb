class Sku
  module StockManagement
    def self.included(klass)
      klass.class_eval do
        extend ClassMethods
        include InstanceMethods

        has_many :stock_logs, -> {order('created_at DESC')}, :class_name => 'SkuStockLog'
      end
    end

    module ClassMethods
      # Move the stock level down for the specified SKUs. Log each modification
      # as a purchase action.
      #
      # @param Hash skus
      #
      # @return Hash
      def purchase_stock!(skus)
        modify_stock_level!('purchase', skus) do |sku, amount|
          sku.stock_level - amount
        end
      end

      # Move the stock level up for the specified SKUs. Log each modification
      # as a return action; when an order is cancelled/refunded.
      #
      # @param Hash skus
      #
      # @return Hash
      def return_stock!(skus)
        modify_stock_level!('return', skus) do |sku, amount|
          sku.stock_level + amount
        end
      end

      # Updates the stock levels and flags them as restocks or adjust down as
      # appropriate.
      #
      #
      # @param Hash skus
      #
      # @return nil
      def update_stock!(skus)
        skus = skus.reduce({}) do |acc, e|
          acc[e[0].to_i] = e[1].to_i
          acc
        end

        levels = select('id, stock_level').where(:id => skus.keys).reduce({}) do |acc, e|
          acc[e.id] = e.stock_level
          acc
        end

        restocks  = skus.select {|id, level| level > levels[id]}
        adjusts   = skus.select {|id, level| level < levels[id]}

        unless restocks.empty?
          modify_stock_level!('restock', restocks) {|sku, amount| amount}
        end

        unless adjusts.empty?
          modify_stock_level!('adjust_down', adjusts) {|sku, amount| amount}
        end

        nil
      end

      # Move the stock level up for the specified SKUs. Log each modification
      # as a restock.
      #
      # @param Hash skus
      #
      # @return Hash
      def increment_stock!(skus)
        modify_stock_level!('restock', skus) do |sku, amount|
          sku.stock_level + amount
        end
      end

      # Move the stock level adjustment for the specified SKUs. Log each modification
      # as a adjust_down.
      #
      # @param Hash skus
      #
      # @return Hash
      def increment_stock!(skus)
        modify_stock_level!('adjust_down', skus) do |sku, amount|
          sku.stock_level - amount
        end
      end

      # Modifies the stock level for the specified SKUs and logs the modification
      # with the action. The block is run for each SKU identified and the result
      # is used as the new stock level.
      #
      # @param String action
      # @param Hash skus
      # @param Block blk
      #
      # @return Hash
      def modify_stock_level!(action, skus, &blk)
        skus.each_pair do |id, amount|
          sku     = find(id)
          result  = blk.call(sku, amount)

          raise InsufficientStock.new(sku) if result < 0

          sku.stock_logs.build(:before => sku.stock_level || 0, :after => result, :action => action)
          sku.stock_level = result
          sku.save(:validate => false)
        end

        skus
      end
    end # ClassMethods

    module InstanceMethods
      # Indicates if the SKU has any stock.
      #
      # @return [Boolean]
      def in_stock?
        stock_level > 0
      end

      # Indicates if the SKU is out of stock.
      #
      # @return [Boolean]
      def out_of_stock?
        stock_level < 1
      end

      # Indicates if the SKU's stock level is getting low; on or below the
      # configured threshold.
      #
      # The threshold is set in the Settings class.
      #
      # @return Boolean
      def low_stock?
        stock_level <= Settings.for(:shop, :alert_level)
      end

      # Indicates if there is a stock warning for the SKU. The warning is only true
      # if the stock is for sale, published and low.
      #
      # @return Boolean
      def stock_warning?
        normalized_published? and normalized_for_sale? and low_stock?
      end
    end # InstanceMethods
  end # StockManagement
end # Sku
