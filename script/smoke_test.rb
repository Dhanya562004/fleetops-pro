require "net/http"
require "uri"

base_url = ENV.fetch("FLEETOPS_BASE_URL").sub(%r{/$}, "")
password = ENV.fetch("FLEETOPS_DEMO_PASSWORD", ENV.fetch("DEMO_PASSWORD", "FleetOpsDemo2026!"))
uri = URI("#{base_url}/session/new")
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = uri.scheme == "https"
http.open_timeout = 10
http.read_timeout = 30

cookie_jar = {}
def request(http, uri, method:, cookie_jar:, form: nil, headers: {})
  request = method == :post ? Net::HTTP::Post.new(uri) : Net::HTTP::Get.new(uri)
  request["Cookie"] = cookie_jar.map { |key, value| "#{key}=#{value}" }.join("; ") unless cookie_jar.empty?
  headers.each { |key, value| request[key] = value }
  request.set_form_data(form) if form
  response = http.request(request)
  response.get_fields("set-cookie")&.each do |cookie|
    key, value = cookie.split(";", 2).first.split("=", 2)
    cookie_jar[key] = value
  end
  response
end

login_page = request(http, uri, method: :get, cookie_jar:)
raise "Login page returned #{login_page.code}" unless login_page.is_a?(Net::HTTPSuccess)
csrf = login_page.body[/name="csrf-token" content="([^"]+)"/, 1]
raise "Login page did not include a CSRF token" unless csrf

login = URI("#{base_url}/session")
response = request(http, login, method: :post, cookie_jar:, form: { email: "ops@fleetops.local", password: }, headers: { "X-CSRF-Token" => csrf })
raise "Login failed with HTTP #{response.code}" unless response.is_a?(Net::HTTPRedirection)

screens = {
  "/" => "Dashboard/Show",
  "/vehicles" => "Vehicles/Index",
  "/lots" => "Lots/Index",
  "/parts/shortages" => "Parts/Shortages",
  "/technicians" => "Technicians/Index",
  "/maintenance_tickets" => "Tickets/Index",
  "/analytics" => "Analytics/Show"
}

screens.each do |path, component|
  page_uri = URI("#{base_url}#{path}")
  page = request(http, page_uri, method: :get, cookie_jar:)
  raise "#{path} returned HTTP #{page.code}" unless page.is_a?(Net::HTTPSuccess)
  raise "#{path} did not render Inertia component #{component}" unless page.body.include?(component)
  puts "PASS #{path} -> #{component} (HTTP #{page.code})"
end
puts "PASS login as ops@fleetops.local"
