class Sku
  module PricePoints
    def self.included(klass)
      klass.class_eval do
        has_many :price_points,           :class_name => 'SkuPricePoint', :order => 'volume ASC, valid_from', :extend => [AssociationMethods]
        has_many :historic_price_points,  :class_name => 'SkuPricePoint', :conditions => {:current => false}, :extend => [AssociationMethods]
        has_many :current_price_points,   :class_name => 'SkuPricePoint', :conditions => {:current => true},  :extend => [AssociationMethods]

        validates_associated :price_points
        validate :validate_boxed_and_bracketed_overlap
        validate :validate_price_point_volme_uniqueness
        validate :validate_single_price_point_presence
        after_validation :retire_price_points

        # All editing of price points is done via the SKU
        accepts_nested_attributes_for :price_points
        attr_accessible :price_points_attributes

        # Use an alias chain to swap in our own attributes= method
        alias_method :original_price_points_attributes=, :price_points_attributes=
        alias_method :price_points_attributes=, :specialised_price_points_attributes= 
      end
    end

    # A module containing some helpers which is mixed into the price points 
    # associations.
    module AssociationMethods
      # Returns the current price points with a specified mode, and optionally volume
      #
      # @param String mode
      # @param Integer volume
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
      # @return [SkuPricePoint, nil]
      def by_id(id)
        id = id.to_i
        select {|p| p.id == id}.first
      end

      # Creates a collection that makes readable summaries of the price points.
      #
      # @return Array<Hash>
      def summary
        map do |point|
          mode_desc = case point.mode
          when 'single'     then 'each'
          when 'bracketed'  then "for #{point.volume} or more"
          when 'boxed'      then "for every #{point.volume}"
          end

          {
            :price => point.price,
            :mode => point.mode,
            :mode_desc => mode_desc
          }
        end
      end
    end

    # This exploits the ::nested_attributes_for declaration to make it easy for
    # us to update multiple price points and perform validation across them in 
    # one hit.
    #
    # @param Hash incoming
    # 
    # @return Hash
    def specialised_price_points_attributes=(incoming)
      incoming.each_pair do |i, attrs|
        if !attrs['id'].blank?
          current = price_points.by_id(attrs['id'])
          current.attributes = if attrs['expire'] == '1'
            {:current => false, :valid_to => Time.now}
          else
            attrs.except('id', 'expire')
          end
        elsif acceptable_price_point?(attrs)
          price_points.build(attrs.merge(:valid_from => Time.now, :current => true))
        end
      end

      {}
    end

    private

    # Checks to see if the hash of values is for an acceptable price point.
    # That is, it should not be rejected
    #
    # @param Hash point
    # @return [true, false]
    def acceptable_price_point?(point)
      !(point['id'].blank? and point['volume'].blank? and point['display_price'].to_i == 0)
    end

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
        errors.add(:price_points, "There must be a only one 'single' price")
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
