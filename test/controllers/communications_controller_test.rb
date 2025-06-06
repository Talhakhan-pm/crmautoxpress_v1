require "test_helper"

class CommunicationsControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get communications_create_url
    assert_response :success
  end

  test "should get destroy" do
    get communications_destroy_url
    assert_response :success
  end
end
