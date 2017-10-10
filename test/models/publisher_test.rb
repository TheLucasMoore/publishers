require "test_helper"
require "shared/mailer_test_helper"

class PublisherTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper
  include MailerTestHelper

  test "uphold_code is only valid without uphold_access_parameters and before uphold_verified" do
    publisher = publishers(:verified)
    publisher.uphold_code = "foo"
    publisher.uphold_access_parameters = nil
    assert publisher.valid?

    publisher.uphold_access_parameters = "bar"
    refute publisher.valid?
    assert_equal [:uphold_code], publisher.errors.keys

    publisher.uphold_access_parameters = nil
    publisher.uphold_verified = true
    refute publisher.valid?
    assert_equal [:uphold_code], publisher.errors.keys
  end

  test "uphold_access_parameters can not be set when uphold_verified" do
    publisher = publishers(:verified)
    publisher.uphold_code = nil
    publisher.uphold_access_parameters = nil
    publisher.uphold_verified = true
    assert publisher.valid?

    publisher.uphold_access_parameters = "bar"
    refute publisher.valid?
    assert_equal [:uphold_access_parameters], publisher.errors.keys
  end

  test "prepare_uphold_state_token generates a new uphold_state_token if one does not already exist" do
    publisher = publishers(:verified)
    publisher.uphold_state_token = nil
    publisher.prepare_uphold_state_token

    assert publisher.uphold_state_token
    assert publisher.valid?

    uphold_state_token = publisher.uphold_state_token
    publisher.prepare_uphold_state_token
    assert_equal uphold_state_token, publisher.uphold_state_token, 'uphold_state_token is not regenerated if it already exists'
  end

  test "receive_uphold_code sets uphold_code and clears other uphold fields" do
    publisher = publishers(:verified)
    publisher.uphold_state_token = "abc123"
    publisher.uphold_code = nil
    publisher.uphold_access_parameters = "bar"
    publisher.uphold_verified = false
    publisher.receive_uphold_code('secret!')

    assert_equal 'secret!', publisher.uphold_code
    assert_nil publisher.uphold_state_token
    assert_nil publisher.uphold_access_parameters
    assert publisher.valid?
    assert_equal :code_acquired, publisher.uphold_status
  end

  test "verify_uphold sets uphold_verified to true and clears uphold_code and uphold_access_parameters" do
    publisher = publishers(:verified)
    publisher.uphold_code = "foo"
    publisher.uphold_access_parameters = "bar"
    publisher.uphold_verified = false
    publisher.verify_uphold

    assert publisher.uphold_verified?
    assert publisher.valid?
  end

  test "verify_uphold_status correctly calculated" do
    publisher = publishers(:verified)

    # unconnected
    publisher.uphold_code = nil
    publisher.uphold_access_parameters = nil
    publisher.uphold_verified = false
    assert publisher.valid?
    assert_equal :unconnected, publisher.uphold_status

    # code_acquired
    publisher.uphold_code = "foo"
    publisher.uphold_access_parameters = nil
    publisher.uphold_verified = false
    assert publisher.valid?
    assert_equal :code_acquired, publisher.uphold_status

    # access_parameters_acquired
    publisher.uphold_code = nil
    publisher.uphold_access_parameters = "bar"
    publisher.uphold_verified = false
    assert publisher.valid?
    assert_equal :access_parameters_acquired, publisher.uphold_status

    # verified
    publisher.uphold_code = nil
    publisher.uphold_access_parameters = nil
    publisher.uphold_verified = true
    assert publisher.valid?
    assert_equal :verified, publisher.uphold_status
  end
end
