require File.expand_path(File.dirname(__FILE__)) +  '/../spec_helper'

describe Order::Promotions do
  mock_shipping

  before(:each) do
    create(:shipping_service)

    @purchase       = create(:volume_discounted_product)
    @purchase_sku   = @purchase.skus.first
    @bonus          = create(:volume_discounted_product)
    @bonus_sku      = @bonus.skus.first
    @exclusive_sku  = create(:volume_discounted_product).skus.first
  end

  # A helper for generating new promotions.
  #
  # @param Proc blk
  # @return Promotion
  def create_promotion(&blk)
    promotion = Promotion.new(
      :name => Faker::Lorem.sentence, 
      :start_at => Time.now.ago(2.days), 
      :active => true
    )
    promotion.tap do |p|
      blk.call(p)
      p.conditions.each {|c| c.active = true}
      p.effects.each {|c| c.active = true}
      p.save
    end
  end

  # Creates a dud order, and makes sure no promotions have been applied.
  #
  # @return CustomerOrder
  def expect_no_misapplication
    order = build(:order)
    order.set_quantity(@exclusive_sku, rand(5) + 1)
    order.apply_promotions!

    expect(order.applied_promotions.map(&:promotion).empty?).to eq(true)
  end

  it "should give fixed shipping discount to orders with code" do
    promotion = create_promotion do |p|
      p.conditions << PromotionCodeCondition.new(:code => 'DERP')
      p.conditions << PromotionShippingCondition.new
      p.effects    << PromotionShippingEffect.new(:amount => 0, :mode => 'set')
    end

    order = build(:order)
    order.set_quantity(@purchase_sku, 1)
    order.promo_code = 'DERP'
    order.apply_promotions!

    expect(order.service_items.total).to eq(money('0'))
    expect(order.applied_promotions.map(&:promotion)).to include(promotion)

    expect_no_misapplication
  end

  it "should give free sku to orders over $50" do
    promotion = create_promotion do |p|
      p.conditions << PromotionSpendCondition.new(:amount => 50)
      p.effects << PromotionBonusEffect.new(:sku_id => @bonus_sku.id, :quantity => 2)
    end

    order = build(:order)
    order.set_quantity(@purchase_sku, 36)
    order.apply_promotions!

    expect(order.applied_promotions.map(&:promotion)).to include(promotion)
    bonus = order.find_item(@bonus_sku)
    expect(bonus).to_not eq(nil)
    expect(bonus.quantity).to eq(2)

    expect_no_misapplication
  end

  it "should give a free product when a code is entered" do
    promotion = create_promotion do |p|
      p.conditions << PromotionCodeCondition.new(:code => 'HERPDERP')
      p.effects << PromotionBonusEffect.new(:sku_id => @bonus_sku.id, :quantity => 4)
    end

    order = build(:order)
    order.set_quantity(@purchase_sku, 2)
    order.promo_code = 'HERPDERP'
    order.apply_promotions!

    expect(order.applied_promotions.map(&:promotion)).to include(promotion)
    bonus = order.find_item(@bonus_sku)
    expect(bonus).to_not eq(nil)
    expect(bonus.quantity).to eq(4)

    expect_no_misapplication
  end

  it "should give a $10 discount when a code is entered" do
    promotion = create_promotion do |p|
      p.conditions << PromotionCodeCondition.new(:code => 'WHATWHAT')
      p.effects << PromotionDiscountEffect.new(:amount => '10', :mode => 'dollar')
    end

    order = build(:order)
    order.set_quantity(@purchase_sku, 6) # $25.95
    order.promo_code = 'WHATWHAT'
    order.apply_promotions!

    expect(order.applied_promotions.map(&:promotion)).to include(promotion)
    expect(order.original_total).to eq(money('40.95'))
    expect(order.total).to eq(money('30.95'))

    expect_no_misapplication
  end

  it "should give a $15 discount to orders over $70" do
    promotion = create_promotion do |p|
      p.conditions << PromotionSpendCondition.new(:amount => 70)
      p.effects << PromotionDiscountEffect.new(:amount => '15', :mode => 'dollar')
    end

    order = build(:order)
    order.set_quantity(@purchase_sku, 100)
    order.apply_promotions!

    expect(order.applied_promotions.map(&:promotion)).to include(promotion)
    expect(order.original_total).to eq(money('410.00'))
    expect(order.total).to eq(money('395.00'))

    expect_no_misapplication
  end

  it "should give free shipping and 15% discount when a code is entered" do
    promotion = create_promotion do |p|
      p.conditions << PromotionCodeCondition.new(:code => 'GETINLINE')
      p.conditions << PromotionShippingCondition.new
      p.effects << PromotionDiscountEffect.new(:amount => '15', :mode => 'percentage')
      p.effects << PromotionShippingEffect.new(:amount => 0, :mode => 'set')
    end

    order = build(:order)
    order.set_quantity(@purchase_sku, 100)

    expect(order.total).to eq(money('410.00'))

    order.promo_code = 'GETINLINE'
    order.apply_promotions!

    expect(order.applied_promotions.map(&:promotion)).to include(promotion)
    expect(order.original_total).to eq(money('410.00'))
    expect(order.total).to eq(money('335.75'))

    expect_no_misapplication
  end

  it "should give 15% and free shipping to members who spend over $100" do
    promotion = create_promotion do |p|
      p.conditions << PromotionSpendCondition.new(:amount => 100)
      p.conditions << PromotionShippingCondition.new
      p.effects << PromotionDiscountEffect.new(:amount => '15', :mode => 'percentage')
      p.effects << PromotionShippingEffect.new(:amount => 0, :mode => 'set')
    end

    order = build(:order)
    order.set_quantity(@purchase_sku, 100)
    order.apply_promotions!

    expect(order.applied_promotions.map(&:promotion)).to include(promotion)
    expect(order.original_total).to eq(money('410.00'))
    expect(order.total).to eq(money('335.75'))

    expect_no_misapplication
  end

  it "should give a free product when a code is entered" do
    promotion = create_promotion do |p|
      p.conditions << PromotionCodeCondition.new(:code => 'GETFREE')
      p.effects << PromotionBonusEffect.new(:sku_id => @bonus_sku.id, :quantity => 1)
    end

    order = build(:order)
    order.set_quantity(@purchase_sku, 1)
    order.promo_code = 'GETFREE'
    order.apply_promotions!

    expect(order.applied_promotions.map(&:promotion)).to include(promotion)
    bonus = order.find_item(@bonus_sku)
    expect(bonus).to_not eq(nil)
    expect(bonus.quantity).to eq(1)

    expect_no_misapplication
  end

  it "should give a $5 discount when order contains product" do
    promotion = create_promotion do |p|
      p.conditions << PromotionProductQuantityCondition.new(:product_id => @purchase.id, :quantity => 2)
      p.effects << PromotionDiscountEffect.new(:amount => '5', :mode => 'dollar')
    end

    order = build(:order)
    order.set_quantity(@purchase_sku, 2)
    order.apply_promotions!

    expect(order.applied_promotions.map(&:promotion)).to include(promotion)
    expect(order.original_total).to eq(money('24.9'))
    expect(order.total).to eq(money('19.9'))

    expect_no_misapplication
  end

  it "should give a $7 discount when order contains products from category" do
    promotion = create_promotion do |p|
      p.conditions << PromotionCategoryQuantityCondition.new(:product_category_id => @purchase.product_category_id, :quantity => 4)
      p.effects << PromotionDiscountEffect.new(:amount => '7', :mode => 'dollar')
    end

    order = build(:order)
    order.set_quantity(@purchase_sku, 6)
    order.apply_promotions!

    expect(order.applied_promotions.map(&:promotion)).to include(promotion)
    expect(order.original_total).to eq(money('40.95'))
    expect(order.total).to eq(money('33.95'))

    expect_no_misapplication
  end

  it "should give a $10 discount when order contains sku" do
    promotion = create_promotion do |p|
      p.conditions << PromotionSkuQuantityCondition.new(:sku_id => @purchase_sku.id, :quantity => 2)
      p.effects << PromotionDiscountEffect.new(:amount => '10', :mode => 'dollar')
    end

    order = build(:order)
    order.set_quantity(@purchase_sku, 3)
    order.apply_promotions!

    expect(order.applied_promotions.map(&:promotion)).to include(promotion)
    expect(order.original_total).to eq(money('29.85'))
    expect(order.total).to eq(money('19.85'))

    expect_no_misapplication
  end

  it "should give free for every qualification" do
    promotion = create_promotion do |p|
      p.conditions << PromotionSkuQuantityCondition.new(:sku_id => @purchase_sku.id, :quantity => 1)
      p.effects << PromotionGetNFreeEffect.new(:quantity => 1)
    end

    order = build(:order)
    order.set_quantity(@purchase_sku, 2)
    order.apply_promotions!

    expect(order.applied_promotions.map(&:promotion)).to include(promotion)
    item = order.find_item(@purchase_sku)
    expect(item.quantity).to eq(3)

    expect_no_misapplication
  end

  describe "compatibility check" do
    it "should reject incompatible pairings" do
      promotion = create_promotion do |p|
        p.conditions << PromotionSpendCondition.new(:amount => 100)
        p.effects << PromotionGetNFreeEffect.new(:quantity => 1)
      end

      expect(promotion.valid?).to eq(false)
      expect(promotion.effects.first.errors.get(:base).nil?).to eq(false)
    end

    it "should allow exact scope matches" do
      promotion = create_promotion do |p|
        p.conditions << PromotionSkuQuantityCondition.new(:sku_id => @purchase_sku.id, :quantity => 2)
        p.effects << PromotionGetNFreeEffect.new(:quantity => 1)
      end

      expect(promotion.valid?).to eq(true)
    end

    it "should allow compatible sub-scopes" do
      promotion = create_promotion do |p|
        p.conditions << PromotionSkuQuantityCondition.new(:sku_id => @purchase_sku.id, :quantity => 2)
        p.effects << PromotionDiscountEffect.new(:amount => '10', :mode => 'dollar')
      end

      expect(promotion.valid?).to eq(true)
    end
  end
end
