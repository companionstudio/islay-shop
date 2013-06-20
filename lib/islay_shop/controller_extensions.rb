module IslayShop
  module ControllerExtensions
    module Public
      def self.included(klass)
        klass.send :helper_method, :retrieve_order, :create_order
      end
      
      def retrieve_order
        order_from_session
      end

      def retrieve_order_without_promotions
        order_from_session(false)
      end
      
      def order_from_session(apply = true)
        if session['order']
          @order = OrderBasket.load(session['order'])

          if apply
            @order.apply_promotions! 
          end

          if @order.new_promotions?
            session['order'] = @order.dump
          end
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