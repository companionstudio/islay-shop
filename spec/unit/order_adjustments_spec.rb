require File.expand_path(File.dirname(__FILE__)) +  '/../spec_helper'

describe Order::Adjustments do
  mock_shipping

  before(:all) do
    shipping    = create(:shipping_service)
    category    = create(:product_category)
    @product    = create(:volume_discounted_product, :category => category)
    @sku        = @product.skus.first
    @bonus_sku  = create(:volume_discounted_product, :category => category).skus.first
  end

  before(:each) do
    @order = build(:order)
  end

  it "should discount an item" do
    item = @order.set_quantity(@sku, 4)

    expect(item.total).to eq(money('19.8'))

    @order.enqueue_adjustment(:discount_quantity, @sku, 2, money('4'), 'promotion')
    @order.apply_adjustments!

    expect(item.pre_discount_total).to eq(money('19.8'))
    expect(item.total).to eq(money('11.8'))

    # Check order total
  end

  it "should set a bonus quantity" do
    @order.enqueue_adjustment(:bonus_quantity, @sku, 2, 'promotion')
    @order.apply_adjustments!

    item = @order.find_item(@sku)

    expect(item.quantity).to eq(2)
    expect(item.pre_discount_total).to eq(money('9.9'))
    expect(item.total).to eq(money('0'))
  end

  it "should adjust order total down and distribute adjustment" do
    @order.enqueue_adjustment(:bonus_quantity, @bonus_sku, 2, 'promotion')
    @order.apply_adjustments!

    bonus_item = @order.find_item(@bonus_sku)
    regular_item  = @order.set_quantity(@sku, 2)

    expect(bonus_item.total).to eq(money('0'))
    expect(regular_item.total).to eq(money('9.9'))
    expect(@order.total).to eq(money('24.9'))

    @order.enqueue_adjustment(:fixed_discount, money('12.45'), 'manual')
    @order.apply_adjustments!

    expect(@order.total).to eq(money('12.45'))
    expect(bonus_item.total).to eq(money('0'))
    expect(bonus_item.adjustments.length).to eq(1)

    # Discount of 50%
    expect(regular_item.total).to eq(money('4.95'))
    expect(regular_item.adjustments.length).to eq(1)

    expect(@order.shipping_service.total).to eq(money('7.50'))
    expect(@order.shipping_service.adjustments.length).to eq(1)
  end

  it "should adjust order total up and distribute adjustment" do
    item = @order.set_quantity(@sku, 100) # 100 * 3.95
    expect(@order.total).to eq(money("410"))

    @order.enqueue_adjustment(:fixed_increase, money("41"), 'manual')
    @order.apply_adjustments!

    expect(@order.discount).to eq(money("0"))
    expect(@order.increase).to eq(money("41"))
    expect(@order.total).to eq(money("451"))
    expect(@order.original_total).to eq(money("410"))

    # Increase of 10%
    expect(item.total).to eq(money("434.5"))
    expect(@order.shipping_service.total).to eq(money("16.5"))
  end

  it "should raise an error if order discount is too deep" do
    item = @order.set_quantity(@sku, 4)

    expect(item.total).to eq(money('19.8'))
    expect(@order.total).to eq(money('34.8'))
    expect do 
      @order.enqueue_adjustment(:fixed_discount, money('60'), 'manual')
      @order.apply_adjustments!
    end.to raise_error(Order::Adjustments::ExcessiveDiscountError)
  end

  it "should track manual adjustments at the order level" do
    item = @order.set_quantity(@sku, 4)
    @order.enqueue_adjustment(:fixed_increase, money("20"), 'manual')
    @order.apply_adjustments!

    expect(@order.adjustments.manual.nil?).to eq(false)
  end

  it "should track promotional adjustments at the order level" do

  end

  it "should remove manual adjustments" do
    item = @order.set_quantity(@sku, 4)
    @order.enqueue_adjustment(:fixed_increase, money("20"), 'manual')
    @order.apply_adjustments!

    expect(@order.adjustments.manual.nil?).to eq(false)
    @order.remove_adjustments('manual')

    item_adjustments = @order.sku_items.map(&:adjustments).flatten

    expect(item_adjustments.empty?).to eq(true)
    expect(@order.adjustments.manual.nil?).to eq(true)
  end

  it "should allow only one manual adjustment" do
    item = @order.set_quantity(@sku, 4)
    @order.enqueue_adjustment(:fixed_increase, money("20"), 'manual')
    @order.apply_adjustments!

    expect(@order.adjustments.length).to eq(1)

    @order.enqueue_adjustment(:fixed_increase, money("10"), 'manual')
    @order.apply_adjustments!

    expect(@order.adjustments.length).to eq(1)
  end

  it "should recalculate manual adjustments against order items" do
    item = @order.set_quantity(@sku, 4)
    @order.enqueue_adjustment(:fixed_increase, money("34.8"), 'manual')
    @order.apply_adjustments!
    expect(@order.total).to eq(money("69.6"))

    adjustment = item.adjustments.first

    expect(adjustment.adjustment.round).to eq(money("19.8"))

    @order.enqueue_adjustment(:fixed_increase, money("17.4"), 'manual')
    @order.apply_adjustments!

    expect(adjustment.adjustment.round).to eq(money("9.9"))
    expect(item.adjustments.length).to eq(1)
  end

  it "should remove promotional adjustments"
  it "should adjust order total down using a percentage discount"

  it "should remove manual adjustments" do
    item = @order.set_quantity(@sku, 4)
    @order.enqueue_adjustment(:fixed_increase, money("20"), 'manual')
    @order.apply_adjustments!

    expect(@order.total).to eq(money("54.8"))
    expect(@order.save).to eq(true)

    @order.enqueue_adjustment(:manual_to_zero)
    @order.apply_adjustments!

    expect(@order.save).to eq(true)

    @order.reload
    expect(@order.total).to eq(money("34.8"))
    expect(@order.increase).to eq(money("0"))
  end

  it "should sum total correctly after discount" do
    item = @order.set_quantity(@sku, 4)
    @order.enqueue_adjustment(:fixed_increase, money("20"), 'manual')
    @order.apply_adjustments!

    expect(@order.total).to eq(money("54.8"))
    expect(@order.save).to eq(true)

    @order.enqueue_adjustment(:fixed_increase, money("40"), 'manual')
    
    @order.apply_adjustments!
    expect(@order.save).to eq(true)

    @order.reload
    expect(@order.total).to eq(money("74.8"))
  end

  it "should apply successive promotion adjustments" do
    item = @order.set_quantity(@sku, 4)
    @order.enqueue_adjustment(:fixed_discount, money("5"), 'promotion')
    @order.enqueue_adjustment(:fixed_discount, money("2.50"), 'promotion')
    @order.apply_adjustments!

    expect(@order.discount).to eq(money("7.50"))
    expect(@order.save).to eq(true)
  end
end
