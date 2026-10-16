require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "login page renders the Inertia page and Vite entrypoint" do
    get new_session_path

    assert_response :success
    assert_includes response.body, "Auth/Login"
    assert_includes response.body, "/vite-test/"
  end
end
