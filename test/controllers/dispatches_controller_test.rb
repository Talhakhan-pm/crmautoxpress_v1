require "test_helper"

class DispatchesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get dispatches_index_url
    assert_response :success
  end

  test "should get show" do
    get dispatches_show_url
    assert_response :success
  end

  test "should get new" do
    get dispatches_new_url
    assert_response :success
  end

  test "should get edit" do
    get dispatches_edit_url
    assert_response :success
  end

  test "should get create" do
    get dispatches_create_url
    assert_response :success
  end

  test "should get update" do
    get dispatches_update_url
    assert_response :success
  end

  test "should get destroy" do
    get dispatches_destroy_url
    assert_response :success
  end
end
