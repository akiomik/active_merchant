require 'test_helper'

class FastpayTest < Test::Unit::TestCase
  include CommStub

  def setup
    @gateway = FastpayGateway.new(login: 'login')

    @credit_card = credit_card
    @amount = 100

    @options = {
      billing_address: address,
      description: 'Test Purchase'
    }
  end

  def test_successful_purchase
    @gateway.expects(:ssl_request).returns(successful_purchase_response)

    response = @gateway.purchase(@amount, @credit_card, @options)
    assert_success response

    assert_equal 'tok_G6B7NnLCAzFS9Fm8zgPqIf77', response.authorization
    assert response.test?
  end

  def test_failed_purchase
    @gateway.expects(:ssl_request).returns(failed_purchase_response)

    response = @gateway.purchase(@amount, @credit_card, @options)
    assert_failure response
  end

  def test_successful_authorize
    @gateway.expects(:ssl_request).returns(successful_authorize_response)

    response = @gateway.authorize(@amount, @credit_card, @options)
    assert_success response

    assert_equal 'tok_G6B7NnLCAzFS9Fm8zgPqIf77', response.authorization
    assert response.test?
  end

  def test_failed_authorize
    @gateway.expects(:ssl_request).returns(failed_authorize_response)

    assert response = @gateway.authorize(@amount, @credit_card, @options)
    assert_failure response
  end

  def test_successful_capture
    @gateway.expects(:ssl_request).returns(successful_capture_response)

    response = @gateway.capture(@amount, 'ch_Cfam8ouZ6UW9ElHAP3SCoyZf')
    assert_success response

    assert_equal 'ch_Cfam8ouZ6UW9ElHAP3SCoyZf', response.authorization
    assert response.test?
  end

  def test_failed_capture
    @gateway.expects(:ssl_request).returns(failed_capture_response)

    response = @gateway.capture(@amount, 'ch_Cfam8ouZ6UW9ElHAP3SCoyZf')
    assert_failure response
  end

  def test_successful_refund
    @gateway.expects(:ssl_request).returns(successful_refund_response)

    response = @gateway.refund(@refund_amount, 'ch_KrkObjDZRodDVU7oKD73CMZn')
    assert_success response

    assert_equal 'ch_KrkObjDZRodDVU7oKD73CMZn', response.authorization
    assert response.test?
  end

  def test_failed_refund
    @gateway.expects(:ssl_request).returns(failed_refund_response)

    response = @gateway.refund(@refund_amount, 'ch_KrkObjDZRodDVU7oKD73CMZn')
    assert_failure response
  end

  def test_successful_void
    @gateway.expects(:ssl_request).returns(successful_void_response)

    response = @gateway.void('tok_G6B7NnLCAzFS9Fm8zgPqIf77')
    assert_success response

    assert_equal 'tok_G6B7NnLCAzFS9Fm8zgPqIf77', response.authorization
    assert response.test?
  end

  def test_failed_void
    @gateway.expects(:ssl_request).returns(failed_void_response)

    response = @gateway.void('tok_G6B7NnLCAzFS9Fm8zgPqIf77')
    assert_failure response
  end

  private

  def successful_purchase_response(refunded = false)
    %(
      {
        "refunds": [],
        "captured": false,
        "card": {
          "fingerprint": "022e2184e3b910cd0d96b89d4ba1d9e3a97139b7",
          "exp_year": 2019,
          "exp_month": 11,
          "type": "Visa",
          "last4": "4242",
          "object": "card",
          "id": "card_j0wc4FRFX2jYbMOT1SmMCk0c"
        },
        "failure_message": null,
        "refunded": #{refunded},
        "paid": true,
        "id": "tok_G6B7NnLCAzFS9Fm8zgPqIf77",
        "object": "charge",
        "livemode": false,
        "currency": "jpy",
        "description": null,
        "amount": 400,
        "amount_refunded": null,
        "created": 1392337942
      }
    )
  end

  def failed_purchase_response
    %(
      {
        "error": {
          "type": "card_error",
          "message": "Your card number is incorrect",
          "code": "incorrect_number",
          "param": "number"
        }
      }
    )
  end

  def successful_authorize_response
    successful_purchase_response
  end

  def failed_authorize_response
    %(
      {
        "error": {
          "type": "invalid_request_error",
          "message": "Invalid API Key provided",
          "code": null,
          "param": null
        }
      }
    )
  end

  def successful_capture_response
    %(
      {
        "refunds": [],
        "captured": true,
        "card": {
          "fingerprint": "022e2184e3b910cd0d96b89d4ba1d9e3a97139b7",
          "exp_year": 2019,
          "exp_month": 11,
          "type": "Visa",
          "last4": "4242",
          "object": "card",
          "id": "card_xbeO4u8xz8Kyn4njOajjlQJ0"
        },
        "failure_message": null,
        "refunded": false,
        "paid": true,
        "id": "ch_Cfam8ouZ6UW9ElHAP3SCoyZf",
        "object": "charge",
        "livemode": false,
        "currency": "jpy",
        "description": null,
        "amount": 400,
        "amount_refunded": null,
        "created": 1392339207
      }
    )
  end

  def failed_capture_response
    failed_response
  end

  def successful_refund_response
    %(
      {
        "refunds": [
          {
              "object": "refund",
              "created": 1392339137,
              "currency": "jpy",
              "amount": "400"
          }
        ],
        "captured": false,
        "card": {
          "fingerprint": "022e2184e3b910cd0d96b89d4ba1d9e3a97139b7",
          "exp_year": 2019,
          "exp_month": 11,
          "type": "Visa",
          "last4": "4242",
          "object": "card",
          "id": "card_j0wc4FRFX2jYbMOT1SmMCk0c"
        },
        "failure_message": null,
        "refunded": true,
        "paid": true,
        "id": "ch_KrkObjDZRodDVU7oKD73CMZn",
        "object": "charge",
        "livemode": false,
        "currency": "jpy",
        "description": null,
        "amount": 400,
        "amount_refunded": null,
        "created": 1392337942
      }  
    )
  end

  def failed_refund_response
    failed_response
  end

  def successful_void_response
    successful_purchase_response(true)
  end

  def failed_void_response
    failed_response
  end

  def failed_response
    %(
      {
        "error": {
          "type": "invalid_request_error",
          "message": null,
          "code": null,
          "param": null
        }
      }
    )
  end
end
