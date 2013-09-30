require File.expand_path(File.dirname(__FILE__)) +  '/../spec_helper'

describe Order::Purchasing do
  mock_shipping

  describe "SKUs" do
    before(:each) do
      category = create(:product_category)
      @product = create(:volume_discounted_product, :category => category)
      @sku     = @product.skus.first

      @single_price_point     = @sku.price_points.by_mode('single').first
      @by_six_price_point     = @sku.price_points.by_mode('boxed', 6).first
      @by_twelve_price_point  = @sku.price_points.by_mode('boxed', 12).first
      @bracketed_price_point  = @sku.price_points.by_mode('bracketed').first

      @order = Order.new
    end

    it "should add new item" do
      @order.set_quantity(@sku, 1)
      expect(@order.sku_items.empty?).to be(false)

      item = @order.sku_items.first
      expect(item.sku_id).to eq(@sku.id)
      expect(item.quantity).to eq(1)
    end

    it "should increment existing item" do
      @order.set_quantity(@sku, 1)
      @order.increment_quantity(@sku, 2)
      
      expect(@order.find_item(@sku).quantity).to eq(3)
    end

    it "should increment a new item" do
      item = @order.increment_quantity(@sku, 2)
      
      expect(item.quantity).to eq(2)
      expect(item.paid_quantity).to eq(2)
    end

    it "should decrement existing item" do
      @order.set_quantity(@sku, 4)
      @order.decrement_quantity(@sku, 2)
      
      expect(@order.find_item(@sku).quantity).to eq(2)
    end

    it "should remove item when decremented to or below zero" do
      @order.set_quantity(@sku, 4)
      @order.decrement_quantity(@sku, 5)
      
      expect(@order.find_item(@sku)).to be_nil
    end

    it "should error when decrementing missing item" do
      expect { @order.decrement_quantity(@sku, 1) }.to raise_error(OrderItem::Purchasing::OrderItemMissingError)
    end

    it "should remove item" do
      @order.set_quantity(@sku, 4)
      @order.remove(@sku)
      
      expect(@order.find_item(@sku)).to be_nil
    end

    it "should choose single price point" do
      @order.set_quantity(@sku, 5)

      item = @order.find_item(@sku)
      expect(item.components.length).to eq(1)

      expect(item.components.first.price).to eq(@single_price_point.price)
    end

    it "should choose boxed price point" do
      @order.set_quantity(@sku, 6)

      item = @order.find_item(@sku)
      expect(item.components.length).to eq(1)

      component = item.components.first
      expect(component.quantity).to eq(6)
      expect(component.price).to eq(@by_six_price_point.price)
    end

    it "should choose bracketed price point" do
      @order.set_quantity(@sku, 100)

      item = @order.find_item(@sku)
      expect(item.components.length).to eq(1)

      component = item.components.first
      expect(component.quantity).to eq(100)
      expect(component.price).to eq(@bracketed_price_point.price)
    end

    it "should choose mixture of single and boxed prices" do
      item = @order.set_quantity(@sku, 7)
      expect(item.components.length).to eq(2)

      expect(item.components.by_price(@single_price_point.price).quantity).to eq(1)
      expect(item.components.by_price(@by_six_price_point.price).quantity).to eq(6)
    end

    it "should adjust from single to boxed prices" do
      item = @order.set_quantity(@sku, 5)
      expect(item.components.length).to eq(1)
      expect(item.components.by_price(@single_price_point.price).quantity).to eq(5)

      @order.increment_quantity(@sku, 1)
      expect(item.components.length).to eq(1)
      expect(item.components.by_price(@by_six_price_point.price).quantity).to eq(6)
    end

    it "should adjust from boxed to single prices" do
      item = @order.set_quantity(@sku, 6)
      expect(item.components.length).to eq(1)
      expect(item.components.by_price(@by_six_price_point.price).quantity).to eq(6)

      @order.decrement_quantity(@sku, 1)
      expect(item.components.length).to eq(1)
      expect(item.components.by_price(@single_price_point.price).quantity).to eq(5)
    end

    it "should use multiple boxed prices" do
      item = @order.set_quantity(@sku, 18)
      expect(item.components.length).to eq(2)

      by_six    = item.components.by_price(@by_six_price_point.price)
      by_twelve = item.components.by_price(@by_twelve_price_point.price)

      expect(by_six).to_not be_nil
      expect(by_six.quantity).to eq(6)

      expect(by_twelve).to_not be_nil
      expect(by_twelve.quantity).to eq(12)
    end

    it "should adjust from single to bracketed price" do
      item = @order.set_quantity(@sku, 5)

      expect(item.components.length).to eq(1)
      expect(item.components.first.price).to eq(@single_price_point.price)

      @order.increment_quantity(@sku, 105)

      expect(item.components.length).to eq(1)
      expect(item.components.first.price).to eq(@bracketed_price_point.price)
    end

    it "should adjust from bracketed to single price" do
      item = @order.set_quantity(@sku, 100)

      expect(item.components.length).to eq(1)
      expect(item.components.first.price).to eq(@bracketed_price_point.price)

      @order.decrement_quantity(@sku, 96)

      expect(item.components.length).to eq(1)
      expect(item.components.first.price).to eq(@single_price_point.price)
    end

    it "should adjust from bracketed to boxed price" do
      item = @order.set_quantity(@sku, 100)

      expect(item.components.length).to eq(1)
      expect(item.components.first.price).to eq(@bracketed_price_point.price)

      @order.set_quantity(@sku, 24)

      expect(item.components.length).to eq(1)
      expect(item.components.first.price).to eq(@by_twelve_price_point.price)
    end

    it "should allow manual adjustment of price" do
      item = @order.set_quantity(@sku, 100)
      @order.set_quantity_and_price(@sku, 50, money("4.00"))

      expect(item.quantity).to eq(50)
      expect(item.components.first.price).to eq(money("4.00"))
      expect(item.total).to eq(money("200"))
    end

    it "should allow manual adjustment of price, while respecting order-level discounts" do
      item = @order.set_quantity_and_price(@sku, 10, money("4.00"))

      expect(item.quantity).to eq(10)
      expect(item.components.first.price).to eq(money("4.00"))
      expect(item.total).to eq(money("40"))

      @order.enqueue_adjustment(:fixed_discount, money("10"), 'manual')
      @order.apply_adjustments!

      expect(@order.total).to eq(money("45"))
      expect(item.total).to eq(money("32.73"))
    end

    it "should calculate order total" do
      @order.set_quantity(@sku, 2)
      expect(@order.product_total).to eq(money('9.9'))
      expect(@order.total).to eq(money('24.9'))
    end
  end
end
