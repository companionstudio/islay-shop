# IslayShop

The start of an extension to the Islay framework. Not much to see at the moment.

## Rspec

Since this is a Rails engine, testing is a little strange. It requires a dummy Rails app which is in the `./spec/dummy` directory.

You'll need to add a `database.yml` file to `./spec/dummy/config`. It should have both the development and test databases configured. Then ensure that you have the latest Islay migrations installed by running `bundle exec rake islay_engine:install:migrations` within the `./spec/dummy` directory; this bit is annoying, but you can't install the migrations from the engine root.

Then from the root of the engine run `bundle exec rake app:db:migrate`. Assuming all the migrations ran without a problem, next run `bundle exec rake spec`.

Yay?
