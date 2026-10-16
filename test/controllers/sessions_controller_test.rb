require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "login page renders the Inertia page and Vite entrypoint" do
    get new_session_path

    diagnostic = response.body
      .gsub(/<style.*?<\/style>/m, " ")
      .gsub(/<script.*?<\/script>/m, " ")
      .gsub(/<[^>]+>/, " ")
      .gsub(/&(?:nbsp|quot|lt|gt|amp);/, " ")
      .gsub(/\s+/, " ")
    assert_response :success, diagnostic.first(2_000)
    assert_includes response.body, "Auth/Login"
    assert_includes response.body, "/vite-test/"
    assert_includes response.body, "id=\"app\""
  end
end
