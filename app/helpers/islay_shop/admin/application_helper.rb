module IslayShop
  module Admin
    module ApplicationHelper
      # Uses the Promotions::Decorator to generate a summary for a promotion.
      #
      # @param Promotion promotion
      # @return String
      def promotion_summary(promotion)
        Promotions::Decorator.new(promotion).summary_text
      end

      # Generates markup for indicating the movement of a value up or down.
      #
      # @param String name
      # @param String before
      # @param String after
      # @param String dir
      # @return String
      def movement(before, after, dir, opts = {})
        change = after - before
        dir_span = content_tag(:span, content_tag(:span, "#{dir} #{change.abs}"), :class => "indicator dir #{dir}")
        change_span = content_tag(:span, "#{change > 0 ? '+' : '-'} #{change.abs}", :class => "indicator")

        def label_span(text)
          content_tag(:span, text, :class => 'label')
        end

        buff = []
        
        buff << " #{opts[:name]}" if opts[:name]
        buff << "#{dir_span} #{label_span('From')} #{before} #{label_span('to')} #{after}"

        content_tag(:span, buff.join(' ').html_safe, :class => 'movement numeric')
      end
    end
  end
end
