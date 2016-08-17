require 'test_helper'

class CorrelationCollectionsControllerTest < ActionController::TestCase
  setup do
    @correlation_collection = correlation_collections(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:correlation_collections)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create correlation_collection" do
    assert_difference('CorrelationCollection.count') do
      post :create, correlation_collection: { title: @correlation_collection.title }
    end

    assert_redirected_to correlation_collection_path(assigns(:correlation_collection))
  end

  test "should show correlation_collection" do
    get :show, id: @correlation_collection
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @correlation_collection
    assert_response :success
  end

  test "should update correlation_collection" do
    patch :update, id: @correlation_collection, correlation_collection: { title: @correlation_collection.title }
    assert_redirected_to correlation_collection_path(assigns(:correlation_collection))
  end

  test "should destroy correlation_collection" do
    assert_difference('CorrelationCollection.count', -1) do
      delete :destroy, id: @correlation_collection
    end

    assert_redirected_to correlation_collections_path
  end
end
