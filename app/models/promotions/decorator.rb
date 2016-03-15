module Promotions
  # A decorator which wraps a Promotion in order to provide functionality for
  # summarising and rendering a Promotion to HTML.
  class Decorator < Draper::Decorator
    # Generates a summary for the encapsulated Promotion.
    #
    # @param Hash opts
    # @option opts Array<Symbol> :exclude_conditions
    # @option opts Array<Symbol> :exclude_effects
    # @option opts [:their, :your] :possessive
    # @option opts [true, false] :preamble
    # @return String
    # @todo Order conditions/effects before mapping.
    def summary(opts = {})
      _opts = {
        :mode       => :general,
        :format     => :html,
        :possessive => :their
      }.merge(opts)

      what  = generate_summary(condition_configs, model.conditions, _opts, opts[:exclude_conditions])
      to    = generate_summary(effect_configs, model.effects, _opts, opts[:exclude_effects])
      start = preamble(what, to, _opts)
      join  = join_text(what, to, _opts)

      # When interpolating, any of these calls might return an empty string, so
      # we squeeze successive spaces within the resulting string.
      output = "#{start} #{what} #{join} #{to}".squeeze(" ")

      case _opts[:format]
      when :html
        nf = Nokogiri::HTML.fragment(output)
        nf.traverse do |c|
          if c.text? and !c.text.blank?
            c.replace(c.text.sub(/\w/, &:capitalize))
            break
          end
        end
        nf.to_xhtml.gsub(%r{\s+}, ' ').html_safe
      when :text
        output.sub(/\w/, &:capitalize)
      end
    end

    # Generate a text summary for the encapsulated Promotion.
    #
    # @param Hash opts
    # @return String
    def summary_text(opts = {})
      summary(opts.merge(:format => :text))
    end

    # Generate a HTML summary for the encapsulated Promotion.
    #
    # @param Hash opts
    # @return String
    def summary_html(opts = {})
      summary(opts.merge(:format => :html))
    end

    private

    # A simple class representing the current context for the promotion summary.
    class Context
      # The promotion currently being summarised.
      #
      # @attr_reader Promotion
      attr_reader :promotion

      # The format for the current generation context.
      #
      # @attr_reader [:html, :text]
      attr_reader :format

      # The mode for the current generation context.
      #
      # @attr_reader [:general, :specific]
      attr_reader :mode

      # The possessive to be used in generated fragments.
      #
      # @attr_reader [:your, :their]
      attr_reader :possessive

      # Constructs a new context.
      #
      # @param Promotion promotion
      # @param Hash opts
      def initialize(promotion, opts)
        @promotion = promotion
        @mode = opts[:mode]
        @format = opts[:format]
        @possessive = opts[:possessive]
      end

      # A concatenation of mode and format. Intended to be used in case
      # statements when deciding how to render a component.
      #
      # @return [:general_text, :general_html, :specifc_text, :specific_html]
      def requested
        @requested ||= :"#{mode}_#{format}"
      end

      # Checks to see if the format is HTML.
      #
      # @return [true, false]
      def html?
        format == :html
      end

      # Checks to see if the format is plain text.
      #
      # @return [true, false]
      def text?
        format == :text
      end

      # Checks to see if the mode is set to specific.
      #
      # @return [true, false]
      def specific?
        mode == :specific
      end

      # Checks to see if the mode is set to general.
      #
      # @return [true, false]
      def general?
        mode == :general
      end
    end

    # A simple class that is used by #generate_summary to encapsulate the
    # context required by the condition and effect helpers.
    class SummaryContext < Context
      # The current condition/effect being addressed while generating the
      # summary.
      attr_accessor :part
    end

    # Generates a string from the provided configuration and collection of
    # promotion components.
    #
    # @param Hash<Symbol, SummaryConfig> configs
    # @param Array<[PromotionCondition, PromotionEffect] parts
    # @param Hash opts
    # @param [Array<Symbol>, nil] exclude
    # @return String
    # @todo Sort the parts using the order within the configs.
    # @todo Account for suffixes
    def generate_summary(configs, parts, opts, exclude = nil)
      _parts = exclude.nil? ? parts : parts.reject {|p| exclude.include?(p.short_name)}
      context = SummaryContext.new(model, opts)
      summaries = _parts.map do |part|
        context.part = part
        instance_exec(context, &configs[part.short_name][:logic])
      end.compact

      case summaries.length
      when 0
        ""
      when 1
        summaries.first
      when 2
        summaries.join(' and ')
      else
        last = summaries.pop
        "#{summaries.join(', ')} and #{last}"
      end
    end

    # Generates a preamble/statement to be appended to the front of the
    # summary.
    #
    # @param String condition_summary
    # @param String effect_summary
    # @param Hash opts
    # @option opts [true, false] :preamble
    # @return String
    # @todo Actually implement this
    # @todo Handle limited applications
    def preamble(condition_summary, effect_summary, opts = {})
      if opts[:preamble] == false
        ""
      elsif condition_summary.blank?
        "Customers"
      else
        "Customers who"
      end
    end

    # Determines the text to be interpolated between the condition and effect
    # summaries by enumerating over the join rules and choosing the first one
    # that succeeds.
    #
    # Where the condition summary is black, it will skip evaluating the join
    # rules and return "receive".
    #
    # @param String condition_summary
    # @param String effect_summary
    # @param Hash opts
    # @return String
    def join_text(condition_summary, effect_summary, opts)
      if condition_summary.blank?
        "receive"
      else
        context = Context.new(model, opts)
        join_rules.each do |r|
          result = r.call(context)
          return result unless result.nil?
        end
      end
    end

    # A convenient shortcut for generating a link.
    #
    # @param [String, Numeric, Boolean] text
    # @param Class obj
    # @return String
    def link_to(text, obj)
      h.link_to(text, h.polymorphic_url([:public, obj]))
    end

    # Refer to 'a something', or 'an something' as appropriate.
    #
    # @param String word
    # @return String
    def indefinite_article(word)
      %w(a e i o u).include?(word[0].downcase) ? 'an' : 'a'
    end

    class_attribute :condition_configs, :effect_configs, :join_rules
    self.condition_configs = {}
    self.effect_configs = {}
    self.join_rules = []

    # If a condition is configured to be skipped, then this is the
    # lambda used in place of one otherwise provided. See ::condition
    NOOP = lambda {|c| nil}

    # Defines the configuration for turning a condition into a textual
    # description.
    #
    # @param Symbol name
    # @param Hash opts
    # @option opts [true, false] :skip
    # @param Proc blk
    # @return Hash
    def self.condition(name, opts = {}, &blk)
      condition_configs[name] = {
        :opts => opts,
        :logic => opts[:skip] ? NOOP : blk
      }
    end

    # Defines the configuration for turning an effect into a textual
    # description.
    #
    # @param Symbol name
    # @param Hash opts
    # @option opts [true, false] :skip
    # @param Proc blk
    # @return Hash
    def self.effect(name, opts = {}, &blk)
      effect_configs[name] = {
        :opts => opts,
        :logic => opts[:skip] ? NOOP : blk
      }
    end

    # Defines a rule used to determine how conditions and effect summaries
    # should be joined together.
    #
    # @param Symbol name
    # @param Proc blk
    # @return Proc
    def self.join_rule(name, &blk)
      join_rules << blk
    end

    condition(:shipping, :skip => true)
    condition(:all, :skip => true)

    condition(:code) do |c|
      code = if c.html?
        h.content_tag(:span, c.part.code, :class => 'condition-code')
      else
        c.part.code
      end

      "enter the code #{code} at checkout"
    end

    condition(:order_item_quantity) do |c|
      "buy at least #{h.pluralize(c.part.quantity, "item")}"
    end

    condition(:for_every_n_items) do |c|
      "buy #{c.part.quantity}"
    end

    condition(:category_quantity) do |c|
      if c.html?
        quantity = h.content_tag(:span, c.part.quantity, :class => 'condition-quantity')
        name = link_to(c.part.category.name, c.part.category)
        if c.part.quantity == 1
          "buy anything from #{name}"
        else
          "buy any #{quantity} from #{name}"
        end
      else
        if c.part.quantity == 1
          "buy anything from #{c.part.category.name}"
        else
          "buy any #{c.part.quantity} from #{c.part.category.name}"
        end

      end
    end

    condition(:product_quantity) do |c|
      quantity = if c.html?
        h.content_tag(:span, c.part.quantity, :class => 'condition-quantity')
      else
        c.part.quantity
      end

      case c.requested
      when :general_text
        "buy #{quantity} #{c.part.product.name}"
      when :general_html
        name = link_to(c.part.product.name, c.part.product)
        "buy #{quantity} #{name}"
      when :specific_text, :specific_html
        "buy #{quantity}"
      end
    end

    condition(:sku_quantity) do |c|
      quantity = if c.html?
        h.content_tag(:span, c.part.quantity, :class => 'condition-quantity')
      else
        c.part.quantity
      end

      case c.requested
      when :general_text
        "buy #{quantity} #{c.part.sku.short_desc}"
      when :general_html
        name = link_to(c.part.sku.short_desc, c.part.sku.product)
        "buy #{quantity} #{name}"
      when :specific_text, :specific_html
        "buy #{quantity}"
      end
    end

    condition(:for_every_quantity) do |c|
      quantity = if c.html?
        h.content_tag(:span, c.part.quantity, :class => 'condition-quantity')
      else
        c.part.quantity
      end

      case c.requested
      when :general_text, :general_html
        "buy #{quantity} items"
      when :specific_text, :specific_html
        "buy #{quantity} items"
      end
    end


    condition(:spend) do |c|
      amount = if c.html?
        h.content_tag(:span, c.part.amount_and_kind, :class => 'condition-amount')
      else
        c.part.amount_and_kind
      end

      "spend #{amount} or more"
    end

    condition(:unique_code) do |c|
      "enter #{c.possessive} unique code"
    end

    effect(:bonus) do |c|
      name = if c.html?
        h.content_tag(:span, c.part.sku.long_desc, :class => 'effect-bonus')
      else
        c.part.sku.long_desc
      end

      # Should go looking for an image to inline in for html
      "a bonus #{name}"
    end

    effect(:discount) do |c|
      amount = if c.html?
        h.content_tag(:span, c.part.amount_and_mode, :class => 'effect-amount')
      else
        c.part.amount_and_mode
      end

      "a #{amount} discount on #{c.possessive} order"
    end

    effect(:product_discount) do |c|
      amount = if c.html?
        h.content_tag(:span, c.part.amount_and_mode, :class => 'effect-amount')
      else
        c.part.amount_and_mode
      end

      postfix = c.specific? ? "on each" : "on qualifying items"

      "a #{amount} discount #{postfix}"
    end

    effect(:competition_entry) do |c|
      "entry into #{c.part.name}"
    end

    effect(:get_n_free) do |c|
      quantity = if c.html?
        h.content_tag(:span, c.part.quantity, :class => 'effect-quantity')
      else
        c.part.quantity
      end

      "#{quantity} free"
    end

    effect(:get_n_cheapest_free) do |c|
      quantity = if c.html?
        h.content_tag(:span, c.part.quantity, :class => 'effect-quantity')
      else
        c.part.quantity
      end

      "#{quantity} of the lowest priced item free"
    end

    effect(:get_cheapest_item_free) do |c|
      "the lowest priced item free"
    end

    effect(:shipping) do |c|
      if c.part.amount.zero?
        "free shipping"
      else
        case c.part.mode
        when 'set' then "shipping for #{c.part.amount}"
        when 'fixed' then "#{c.part.amount} off shipping"
        when 'percentage' then "#{c.part.amount}% off shipping"
        end
      end
    end

    join_rule :generic do |c|
      '' if c.promotion.has_effect?(:generic)
    end

    join_rule :get_cheapest_item_free do |c|
      'receive' if c.promotion.has_effect?(:get_cheapest_item_free)
    end

    join_rule :customer_limit do |c|
      'receive' if c.promotion.limited?
    end

    join_rule :competition_entry do |c|
      if c.promotion.effects.length == 1 and c.promotion.has_effect?(:competition_entry)
        "will"
      end
    end

    join_rule :to_receive do |c|
      'will receive'
    end
  end
end
