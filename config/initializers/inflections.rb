ActiveSupport::Inflector.inflections do |inflect|
  inflect.singular /(bonus)$/i, '\1'
  inflect.irregular 'bonus', 'bonuses'
end


