class Sku
  module PricePoints
    def self.included(klass)
      klass.class_eval do
        has_many :price_points, :class_name => 'SkuPricePoint', :order => 'volume ASC, valid_from' do
          # Returns the current price points with a specified mode, and optionally volume
          #
          # @param String mode
          # @param Integer volume
          #
          # @return Array<ActiveRecord::Base>
          def by_mode(mode, volume = nil)
            if volume
              select {|c| c.mode == mode and c.volume == volume}
            else
              select {|c| c.mode == mode}
            end
          end

          # A convenience method which grabs a price point by id.
          #
          # @param [String, Numeric] id
          #
          # @return [SkuPricePoint, nil]
          def by_id(id)
            id = id.to_i
            select {|p| p.id == id}.first
          end
        end

        has_many :historic_price_points,  :class_name => 'SkuPricePoint', :conditions => {:current => false}

        has_many :current_price_points,  :class_name => 'SkuPricePoint', :conditions => {:current => true}  do
          # Returns the current price points with a specified mode, and optionally volume
          #
          # @param String mode
          # @param Integer volume
          #
          # @return Array<ActiveRecord::Base>
          def by_mode(mode, volume = nil)
            if volume
              select {|c| c.mode == mode and c.volume == volume}
            else
              select {|c| c.mode == mode}
            end
          end
        end

        validates_associated :price_points
        validate :validate_boxed_and_bracketed_overlap
        validate :validate_price_point_volme_uniqueness
        validate :validate_single_price_point_presence
        after_validation :retire_price_points
      end
    end

    private

    # Price points with a mode of either 'boxed' or 'bracketed' must not overlap.
    # Simply; bracketed prices must always be greater than the boxed.
    #
    # @return nil
    def validate_boxed_and_bracketed_overlap
      point = price_points.select {|p| p.mode != 'bracketed'}.sort_by(&:volume).reverse.first

      if point
        violations = price_points.by_mode('bracketed').select {|p| p.volume < point.volume}
        unless violations.empty?
          errors.add(:price_points, 'Bracketed prices must not be lower than single or boxed prices')
          violations.each {|p| p.errors.add(:volume, "must be greater than #{point.volume}")}
        end
      end

      nil
    end

    # Ensure all the price points have unique volumes
    #
    # @return nil
    def validate_price_point_volme_uniqueness
      grouped = price_points.select(&:current).group_by(&:volume)

      grouped.each_pair do |volume, group|
        if group.length > 1
          errors.add(:price_points, "There must be only one price point for a volume")
          group.each {|point| point.errors.add(:volume, "Must be unique")}
        end
      end

      nil
    end

    # Ensure there's a single, current price point.
    #
    # @return nil
    def validate_single_price_point_presence
      single = price_points.select {|p| p.current == true and p.mode == 'single'}

      if single.length > 1
        errors.add(:price_points, "There must be a 'single' price")
      elsif single.length == 0
        errors.add(:price_points, "There must be at least one 'single' price")
      end

      nil
    end

    # Checks to see if any of the existing price points need to be replaced with
    # newer instances.
    #
    # @return nil
    def retire_price_points
      retiring = price_points.select {|s| !s.new_record? and s.changed? and s.current}

      retiring.each do |point|
        replacement = price_points.build(
          :current => true,
          :valid_from => Time.now,
          :mode => point.mode,
          :price => point.price,
          :volume => point.volume
        )

        raise "Replacement for price point #{point.id} is invalid" unless replacement.valid?

        point.reload
        point.attributes = {:valid_to => Time.now, :current => false}
      end

      nil
    end
  end # PricePoints
end # Sku
