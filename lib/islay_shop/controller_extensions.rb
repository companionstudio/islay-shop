module IslayShop
  module ControllerExtensions
    module Public
      def self.included(klass)
        klass.send(
          :helper_method,
          :retrieve_order, :create_order, :order, :checkout_promotions,
          :checkout_promotions?, :promotion_summary
        )
      end

      # An accessor which lazily constructs them memoizes the order. The order
      # itself might come from session or it might be a new instance.
      #
      # In the case where it is being pulled from session, it has promotions
      # applied to it.
      #
      # @return OrderBasket
      def order
        @order ||= if session['order']
          OrderBasket.load(session['order']).tap(&:apply_promotions!)
        else
          OrderBasket.new
        end
      end

      # This is the same as #order, except that it does not automatically apply
      # promotions to an order loaded from session.
      #
      # @return OrderBasket
      def unpromoted_order
        @unpromoted_order ||= if session['order']
          OrderBasket.load(session['order'])
        else
          OrderBasket.new
        end
      end

      # Uses the Promotions::Decorator to generate a summary for a promotion.
      #
      # @param Promotion promotion
      # @return String
      def promotion_summary(promotion)
        Promotions::Decorator.new(promotion).summary_text
      end

      # A predicate which checks to see if there are any checkout promotions
      # available.
      #
      # @return [true, false]
      def checkout_promotions?
        !checkout_promotions.empty?
      end

      # A simple accessor which looks up and caches promotions that should be
      # displayed at checkout.
      #
      # @return Array<Promotion>
      def checkout_promotions
        @checkout_promotions ||= Promotion.active.code_based
      end

      def retrieve_order
        order_from_session
      end

      def retrieve_order_without_promotions
        order_from_session(false)
      end

      def order_from_session(apply = true)
        order_from_source(session, apply)
      end

      def order_from_flash(apply = true)
        order_from_source(flash, apply)
      end

      def order_from_source(source, apply)
        if source['order']
          @order = OrderBasket.load(source['order'])

          if member_signed_in? and @order.member_order.blank?
            @order.member_order = MemberOrder.find_or_initialize_by(order: @order, member: current_member)
          end

          @order.apply_promotions! if apply

          source['order'] = @order.dump if @order.new_promotions?

        else
          create_order
        end
      end

      def create_order
        @order = OrderBasket.new
      end

    end
  end
end
