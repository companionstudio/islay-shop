module IslayShop
  module Admin
    module ApplicationHelper
      # Generates markup for indicating the movement of a value up or down.
      #
      # @param String name
      # @param String before
      # @param String after
      # @param String dir
      #
      # @return String
      def movement(before, after, dir, opts = {})
        dir_span = content_tag(:span, content_tag(:span, dir), :class => "dir #{dir}")

        buff = []
        buff << "#{opts[:name]}" if opts[:name]
        buff << "#{before} #{dir_span} #{after}"

        content_tag(:span, buff.join(' ').html_safe, :class => 'indicator movement')
      end
    end
  end
end
