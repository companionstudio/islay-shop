module IslayShop::Admin::PromotionsHelper
  # Renders a partial for the condition attached to the provided builder. It 
  # does this by inferring the name of the condition from it's class and looks 
  # for the corresponding partial.
  #
  # @param Islay::FormBuilder builder
  # @return String
  def promotion_condition(builder)
    render(
      :partial  => "condition_#{builder.object.short_name}", 
      :locals   => {:f => builder, :condition => builder.object}
    )
  end

  # Generates the options for a condition fieldset.
  #
  # @param PromotionCondition condition
  # @return Hash
  def condition_opts(condition)
    {
      "class"                   => "#{condition.short_name}-condition", 
      "data-compatible-effects" => condition.compatible_effects.join(', '),
      "data-exclusivity-scope"  => condition.exclusivity_scope
    }
  end

  # Renders a partial for the effect attached to the provided builder. It does
  # this by inferring the name of the effect from it's class and looks for the
  # corresponding partial.
  #
  # @param Islay::FormBuilder builder
  # @return String
  def promotion_effect(builder)
    render(
      :partial  => "effect_#{builder.object.short_name}", 
      :locals   => {:f => builder, :effect => builder.object}
    )
  end
end

