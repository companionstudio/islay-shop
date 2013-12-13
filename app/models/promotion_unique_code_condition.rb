class PromotionUniqueCodeCondition < PromotionCondition
  desc "Order has unique code"
  condition_scope :order
  exclusivity_scope :code

  metadata(:config) do
    integer :limit, :required => true
    string :code_prefix
    string :code_suffix
  end

  has_many :codes,            :class_name => 'PromotionCode', :foreign_key => 'promotion_condition_id'
  has_many :unredeemed_codes, :class_name => 'PromotionCode', :foreign_key => 'promotion_condition_id', :conditions => 'redeemed_at IS NULL',      :order => 'created_at DESC'
  has_many :redeemed_codes,   :class_name => 'PromotionCode', :foreign_key => 'promotion_condition_id', :conditions => 'redeemed_at IS NOT NULL',  :order => 'redeemed_at DESC'

  validates   :limit, :numericality => {:greater_than => 0}
  validate    :prefix_and_or_suffix_required
  validate    :count_update
  after_save  :update_codes
  before_destroy :destroy_codes


  def check(order)
    if order.promo_code and unredeemed_codes.exists?(:code => order.promo_code.upcase)
      success
    else
      if order.promo_code.blank?
        reason = :no_promo_code
        explanation = 'No code was provided'
      elsif redeemed_codes.exists?(:code => order.promo_code.upcase)
        reason = :code_already_redeemed
        explanation = "The code '#{order.promo_code.upcase}' has been redeemed already."
      elsif !codes.exists?(:code => order.promo_code.upcase)
        reason = :promo_code_mismatch
        explanation = "The code '#{order.promo_code.upcase}' isn't valid for this promotion."
      end
      failure(reason, explanation)
    end
  end

  def limited?
    true
  end

  def locking?
    false
  end

  private

  # A validate hook that ensures the count doesn't go below the number of codes
  # that have already been redeemed.
  #
  # @return nil
  def count_update
    if limit < redeemed_codes.count
      errors.add(:base, "The count can not be lower than the number of redeemed codes.")
    end
  end

  # An after_save hook which generates codes. It will generate new codes when
  # the condition is first created. When the code count is increased it will
  # create codes in addition to the existing ones.
  #
  # When the code count is decreased it will destroy any that have not been
  # redeemed.
  #
  # @return nil
  def update_codes
    if limit and limit > 0
      move = limit - codes.count
      if move != 0
        if move > 0
          move.times {codes.create!(:prefix => code_prefix, :suffix => code_suffix)}
        elsif move < 0
          codes.where(:redeemed_at => nil).limit(move.abs).destroy_all
        end
      end
    end
  end

  def destroy_codes
    codes.where(:redeemed_at => nil).destroy_all
  end

  # A validate hook that ensures the prefix and/or suffix are specified.
  #
  # @return nil
  def prefix_and_or_suffix_required
    if code_prefix.blank? and code_suffix.blank?
      errors.add(:base, "you must have a code prefix and/or a suffix.")
    end
  end
end

