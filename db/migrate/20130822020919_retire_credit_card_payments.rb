class RetireCreditCardPayments < ActiveRecord::Migration
  def up
    execute(%{
      INSERT INTO order_payments (
        order_id, 
        provider_name, 
        provider_token, 
        status, 
        name, 
        number, 
        expiration_month, 
        expiration_year, 
        card_type, 
        created_at, 
        updated_at
      )
      SELECT 
        order_id,
        'spreedly_core',
        gateway_id,
        CASE
          WHEN ccts.transaction_type = 'authorize' THEN 'authorized'
          WHEN ccts.transaction_type = 'capture' THEN 'settled'
          WHEN ccts.transaction_type = 'credit' THEN 'refunded'
        END,
        first_name || ' ' || last_name,
        number,
        month,
        year,
        card_type,
        ccps.created_at,
        ccps.updated_at
      FROM credit_card_payments AS ccps
      JOIN credit_card_transactions AS ccts ON ccts.id IN (
        SELECT id FROM credit_card_transactions
        WHERE credit_card_payment_id = ccps.id
        ORDER BY created_at DESC LIMIT 1
      )
    })
    rename_table(:credit_card_payments, :legacy_credit_card_payments)
    rename_table(:credit_card_transactions, :legacy_credit_card_transactions)
  end

  def down
    rename_table(:legacy_credit_card_payments, :credit_card_payments)
    rename_table(:legacy_credit_card_transactions, :credit_card_transactions)
    execute(%{
      DELETE FROM order_payments WHERE provider_token IN (
        SELECT gateway_id FROM credit_card_payments
      )
    })
  end
end
