require File.expand_path(File.dirname(__FILE__)) +  '/../spec_helper'

describe Sku do
  describe 'when updating price points' do

    before(:each) do
      @product = create(:volume_discounted_product)
      @sku = @product.skus.first

      @single_price_point     = @sku.price_points.by_mode('single').first
      @by_six_price_point     = @sku.price_points.by_mode('boxed', 6).first
      @by_twelve_price_point  = @sku.price_points.by_mode('boxed', 12).first
      @bracketed_price_point  = @sku.price_points.by_mode('bracketed').first
    end

    def single_point(attrs)
      {"0" => attrs}
    end

    def multiple_points(*attrs)
      flat = attrs.each_with_index.map {|a, i| [i.to_s, a]}.flatten
      Hash[*flat]
    end

    it "should add a new price point" do
      @sku.price_points_attributes = single_point(
        "volume"  => "24", 
        "mode"    => "boxed", 
        "price"   => "$300.00"
      )

      expect(@sku.save).to eq(true)
      @sku.reload
      expect(@sku.price_points.length).to eq(5)
      expect(@sku.price_points.by_mode('boxed', 24).length).to eq(1)
    end

    it 'should only allow one current single price' do
      @sku.price_points_attributes = single_point(
        "volume"  => "1", 
        "mode"    => "single", 
        "price"   => "$10.50"
      )

      expect(@sku.save).to eq(false)
      expect(@sku.errors.has_key?(:price_points)).to eq(true)
    end
    
    it 'should require a current single price' do
      sku = @product.skus.build

      expect(sku.save).to eq(false)
      expect(sku.errors.has_key?(:price_points)).to eq(true)
    end

    it 'should expire prices' do
      @sku.price_points_attributes = single_point(
        "id"     => @by_six_price_point.id.to_s,
        "expire" => '1'
      )

      expect(@sku.save).to eq(true)

      @by_six_price_point.reload
      expect(@by_six_price_point.current).to eq(false)
    end

    it 'should not allow single prices to be expired' do
      @sku.price_points_attributes = single_point(
        "id" => @single_price_point.id.to_s,
        "expire" => '1'
      )

      expect(@sku.save).to eq(false)
      expect(@sku.errors.has_key?(:price_points)).to eq(true)
      
      @single_price_point.reload
      expect(@single_price_point.current).to eq(true)
    end

    it 'should replace single prices when price changes' do
      @sku.price_points_attributes = single_point(
        "id"      => @single_price_point.id.to_s,
        "volume"  => "1",
        "mode"    => "single",
        "price"   => "3.95"
      )

      expect(@sku.save).to eq(true)
      expect(@sku.current_price_points.by_mode('single').first.price).to eq(money('3.95'))

      @single_price_point.reload
      expect(@single_price_point.current).to eq(false)
    end

    it 'should replace boxed prices' do
      @sku.price_points_attributes = single_point(
        "id"      => @by_six_price_point.id.to_s,
        "volume"  => "6",
        "mode"    => "boxed",
        "price"   => "4.00"
      )

      expect(@sku.save).to eq(true)
      expect(@sku.current_price_points.by_mode('boxed', 6).first.price).to eq(money('4.00'))

      @by_six_price_point.reload
      expect(@by_six_price_point.current).to eq(false)
    end

    it 'should replace bracketed prices' do
      @sku.price_points_attributes = single_point(
        "id"      => @bracketed_price_point.id.to_s,
        "volume"  => "120",
        "mode"    => "bracketed",
        "price"   => "4.00"
      )

      expect(@sku.save).to eq(true)
      expect(@sku.current_price_points.by_mode('bracketed', 120).first.price).to eq(money('4.00'))

      @bracketed_price_point.reload
      expect(@bracketed_price_point.current).to eq(false)
    end

    it 'should not allow prices to have the same volume' do
      @sku.price_points_attributes = single_point(
        "volume"  => "100",
        "mode"    => "bracketed",
        "price"   => "8.00"
      )

      expect(@sku.save).to eq(false)
      expect(@sku.errors.has_key?(:price_points)).to eq(true)
    end

    it "should not allow batched prices to overlap with boxed prices" do
      @sku.price_points_attributes = single_point(
        "volume"  => "11",
        "mode"    => "bracketed",
        "price"   => "3.20"
      )

      expect(@sku.save).to eq(false)

      batch = @sku.price_points.by_mode('bracketed', 11).first
      expect(batch.errors.has_key?(:volume)).to eq(true)
    end

    it "should retire and replace points in a single step" do
      @sku.price_points_attributes = multiple_points(
        # Update single price
        {"id" => @single_price_point.id.to_s, "price" => "4.20"},
        # Expire/retire a boxed price
        {"id" => @by_six_price_point.id.to_s, "expire" => "1"},
        # Add a new price point
        {"mode" => "bracketed", "volume" => "200", "price" => "3.00"}
      )

      expect(@sku.save).to eq(true)

      @sku.reload

      # Check single price point replacement
      @single_price_point.reload
      expect(@single_price_point.current).to eq(false)
      single = @sku.current_price_points.by_mode('single').first
      expect(single.price).to eq(money('4.20'))

      # Check by six is retired
      @by_six_price_point.reload
      expect(@by_six_price_point.current).to eq(false)
      expect(@sku.current_price_points.by_mode('boxed', 6).empty?).to eq(true)

      # Check there is a new bracketed price
      expect(@sku.current_price_points.by_mode('bracketed').length).to eq(2)
      bracketed = @sku.current_price_points.by_mode('bracketed', 200).first
      expect(bracketed.price).to eq(money('3.00'))
    end
  end
end
