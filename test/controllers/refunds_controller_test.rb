require "test_helper"

class RefundsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get refunds_index_url
    assert_response :success
  end

  test "should get show" do
    get refunds_show_url
    assert_response :success
  end
end
