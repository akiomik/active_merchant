module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class FastpayGateway < StripeGateway
      self.live_url = 'https://fastpay.yahooapis.jp/v1/'

      self.supported_countries = %w(JP)
      self.default_currency = 'JPY'
      self.supported_cardtypes = [:visa, :master]

      self.homepage_url = 'https://fastpay.yahoo.co.jp/'
      self.display_name = 'FastPay'
    end
  end
end
