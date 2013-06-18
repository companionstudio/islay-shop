module IslayShop::Public::PromotionDisplayHelper
  def promo_code_response(result, form_builder = nil)
    response = []
    case result
    when :invalid_code
      response << content_tag(:label, 'That wasn\'t a valid promotion code. Try again?', :for => 'promo_code')
      response << text_field_tag(:promo_code)
      response << content_tag(:button, 'Apply code', {:type => 'submit'})
    when :membership_required
      response << content_tag(:label, "That promotion is for members only - please #{link_to('log in', public_food_club_login_url)} or #{link_to('join the club', public_food_club_sign_up_url)}, then re-enter your code.".html_safe, :for => 'promo_code')
    when :did_not_qualify
      response << content_tag(:label, 'Sorry, your order doesn\'t qualify for that promotion.', :for => 'promo_code')
    else
      if result 
        response << content_tag(:div, result, :class => 'new-promotion-applied')
      elsif form_builder and form_builder.object.promo_code.blank?
        response << form_builder.input(:promo_code, :label => 'Do you have an offer code?', :input_html => {:class => 'code', :placeholder => 'Offer Code' })
        response << content_tag(:button, 'Apply code', {:type => 'submit'})
      end
      
    end
    response.join.html_safe
  end
end