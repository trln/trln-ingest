require 'test_helper'

class TransactionsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def ensure_redirected
    assert_redirected_to('/users/sign_in')
  end

  setup do
    @transaction = transactions(:one)
    @user = users(:one)
  end

  test "should get index (authenticated)" do
    sign_in @user
    get transactions_url
    assert_response :success
  end

  test "index should get redirected to login page (noauth)" do
    get transactions_url
    ensure_redirected
  end

  test "new should redirect to sign_in (noauth)" do
    get new_transaction_url
    ensure_redirected
  end

  # test "should show new (auth)" do
  #  sign_in @user
  #  get new_transaction_url
  #  assert_response :success
  # end

  test "should redirect from transaction (noauth)" do
    get transaction_url(@transaction)
    ensure_redirected
  end

  test "should show transaction (auth)" do
    sign_in @user
    get transaction_url(@transaction)
    assert_response :success
  end

  test "should redirect get edit (noauth)" do
    get edit_transaction_url(@transaction)
    ensure_redirected
  end

  test "should destroy transaction" do
    sign_in @user
    assert_difference('Transaction.count', -1) do
      delete transaction_url(@transaction)
    end
    assert_redirected_to transactions_url
  end

  test 'should create ingest (auth WITH TOKEN)' do
    assert_difference('Transaction.count', 1) do
      post '/ingest/ncsu', params: {}.to_json, headers: {'Content-Type' => 'application/json', 'X-User-Email' => @user.email, 'X-User-Token' => @user.authentication_token}
    end
    assert_response :success
  end
end
