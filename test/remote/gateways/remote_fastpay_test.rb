require 'test_helper'

class RemoteFastpayTest < Test::Unit::TestCase
  def setup
    @gateway = FastpayGateway.new(fixtures(:fastpay))

    @amount = 100
    @credit_card = credit_card('4242424242424242')
    @declined_card = credit_card('4000000000000002')

    @options = {
      billing_address: address,
      description: 'fastpay@example.com'
    }
  end

  def test_successful_purchase
    response = @gateway.purchase(@amount, @credit_card, @options)
    assert_success response
    assert_equal 'Transaction approved', response.message
  end

  def test_failed_purchase
    response = @gateway.purchase(@amount, @declined_card, @options)
    assert_failure response
    assert_match 'Your card was declined.', response.message
  end

  def test_successful_authorize_and_capture
    auth = @gateway.authorize(@amount, @credit_card, @options)
    assert_success auth
    assert_equal 'Transaction approved', auth.message
    assert !auth.params['captured']

    assert capture = @gateway.capture(nil, auth.authorization)
    assert_success capture
    assert_equal 'Transaction approved', capture.message
    assert capture.params['captured']
  end

  def test_failed_authorize
    response = @gateway.authorize(@amount, @declined_card, @options)
    assert_failure response
    assert_match 'Your card was declined.', response.message
  end

  def test_failed_capture
    response = @gateway.capture(nil, 'foo')
    assert_failure response
    assert_equal 'No such charge: foo', response.message
  end

  def test_successful_refund
    purchase = @gateway.purchase(@amount, @credit_card, @options)
    assert_success purchase
    assert_equal 'Transaction approved', purchase.message
    assert !purchase.params['refunded']

    assert refund = @gateway.refund(nil, purchase.authorization)
    assert_success refund
    assert_equal 'Transaction approved', refund.message
    assert refund.params['refunded']
  end

  def test_partial_refund
    purchase = @gateway.purchase(@amount, @credit_card, @options)
    assert_success purchase
    assert_equal 'Transaction approved', purchase.message
    assert !purchase.params['refunded']
    assert purchase.params['refunds'].empty?

    assert refund = @gateway.refund(@amount - 1, purchase.authorization)
    assert_success refund
    assert_equal 'Transaction approved', refund.message
    assert refund.params['refunded']
    assert !refund.params['refunds'].empty?
    # TODO: partial refund is not implemented yet.
    # assert_equal refund.params['refunds'].first['amount'].to_i, @amount - 1
  end

  def test_failed_refund
    response = @gateway.refund(nil, 'bar')
    assert_failure response
    assert_equal 'No such charge: bar', response.message
  end

  def test_successful_void
    auth = @gateway.authorize(@amount, @credit_card, @options)
    assert_success auth
    assert_equal 'Transaction approved', auth.message
    assert !auth.params['refunded']
    assert auth.params['refunds'].empty?

    assert void = @gateway.void(auth.authorization)
    assert_success void
    assert_equal 'Transaction approved', void.message
    assert void.params['refunded']
    assert !void.params['refunds'].empty?
    assert_equal void.params['refunds'].first['amount'].to_i, @amount
  end

  def test_failed_void
    response = @gateway.void('baz')
    assert_failure response
    assert_equal 'No such charge: baz', response.message
  end

  def test_invalid_login
    gateway = FastpayGateway.new(login: '')
    response = gateway.purchase(@amount, @credit_card, @options)
    assert_failure response
    assert_equal 'Invalid API Key provided', response.message
  end
end
