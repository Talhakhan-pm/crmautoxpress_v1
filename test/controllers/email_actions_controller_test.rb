require "test_helper"

class EmailActionsControllerTest < ActionDispatch::IntegrationTest
  test "should get send_order_email" do
    get email_actions_send_order_email_url
    assert_response :success
  end
end
