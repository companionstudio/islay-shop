namespace :islay_shop do
  namespace :db do
    desc "Loads in seed data for bootstrapping a fresh Islay app."
    task :seed => :environment do
      require 'islay/spec'
      ProductCategory.make!(15)
      OrderProcess.make(80).map do |o|
        begin
          o.run!(:add)
        rescue Sku::InsufficientStock
          # Just ignore this guy
        end
      end
    end
  end
end