require 'test_helper'

class AdminSectionsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
  end

  test "should get list_users" do
    get :list_users
    assert_response :success
  end

  test "should get edit_user" do
    get :edit_user
    assert_response :success
  end

end
