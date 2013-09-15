# IslayShop

The start of an extension to the Islay framework. Not much to see at the moment.

## Rspec

Since this is a Rails engine, testing is a little strange. It requires a dummy Rails app which is in the `./spec/dummy` directory.

### ENV

The first step is configure the env variables required by both Islay and Islay Shop. In test and dev mode we use the Fiagro gem, which allows us to define them inside a YAML file.

Within the file `./spec/dummy/config/application.yml` you will need these entries as a bare minimum:

```
IC_ISLAY_NAME: Islay Shop
IC_SHOP_BRAINTREE_MERCHANT_ID: <ID>
IC_SHOP_BRAINTREE_PUBLIC_KEY: <PUBLIC>
IC_SHOP_BRAINTREE_PRIVATE_KEY: <PRIVATE>
IC_SHOP_ALERT_LEVEL: 5
IC_SHOP_EMAIL: <EMAIL>
```

The email can be garbage, but the Braintree credentials should be for a real sandbox account.

### Database

You'll need to add a `database.yml` file to `./spec/dummy/config`. It should have both the development and test databases configured. Then ensure that you have the latest Islay migrations installed by running `bundle exec rake islay_engine:install:migrations` within the `./spec/dummy` directory; this bit is annoying, but you can't install the migrations from the engine root.

Then from the root of the engine run `bundle exec rake app:db:migrate`. Assuming all the migrations ran without a problem, next run `bundle exec rake spec`.

Yay?
