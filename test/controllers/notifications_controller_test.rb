require "test_helper"

class NotificationsControllerTest < ActionDispatch::IntegrationTest
  test "should get mark_read" do
    get notifications_mark_read_url
    assert_response :success
  end

  test "should get mark_all_read" do
    get notifications_mark_all_read_url
    assert_response :success
  end
end
