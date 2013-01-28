module IslayShop::Admin::PromotionsHelper
  # Conditionally renders a partial if it exists.
  #
  # @param ActiveRecord::Base obj
  # @param Hash locals
  #
  # @return [String, nil]
  def render_component(obj, locals = {})
    render(:partial => obj.type.underscore, :locals => locals)
  rescue ActionView::MissingTemplate
    nil
  end
end

