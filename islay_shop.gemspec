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
  s.test_files = Dir["test/**/*"]


  s.add_dependency 'islay',         '~> 0.5.0'
  s.add_dependency 'friendly_id',   '~> 4.0.8'
  s.add_dependency 'spook_and_pay', '0.2.0.alpha'

  s.add_development_dependency "pg"
end
