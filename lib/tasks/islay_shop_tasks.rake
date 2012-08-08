namespace :islay_shop do
  namespace :db do
    desc "Loads in seed data for bootstrapping a fresh Islay app."
    task :seed => :environment do
      require 'islay/spec'
      ProductCategory.make!(15)
      OrderProcess.make(80).map {|o| o.run!(:add)}
    end
  end
end