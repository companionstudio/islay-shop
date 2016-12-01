$:.push File.expand_path("../lib", __FILE__)

require "islay_shop/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "islay_shop"
  s.version     = IslayShop::VERSION
  s.authors     = ["Luke Sutton", "Ben Hull"]
  s.email       = ["luke@spookandpuff.com"]
  s.homepage    = "http://spookandpuff.com"
  s.summary     = "An extension to the Islay framework"
  s.description = "An extension to the Islay framework"

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency 'islay',                 '~> 2.0.0'
  s.add_dependency 'spook_and_pay',         '~> 1.1.1'
  s.add_dependency 'spook_and_puff_money',  '~> 1.0.0'
  s.add_dependency 'country_select',        '~> 2.5', '>= 2.5.2'

  s.add_development_dependency 'rspec-rails',         '2.14.0'
  s.add_development_dependency 'factory_girl_rails',  '4.2.1'
  s.add_development_dependency 'vcr',                 '2.5.0'
  s.add_development_dependency 'ffaker',              '~> 1.16.1'
  s.add_development_dependency 'webmock',             '~> 1.8.7'
  s.add_development_dependency 'figaro',              '0.7.0'
end
