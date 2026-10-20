source "https://rubygems.org"

ruby ">= 3.4.0", "< 3.5"

gem "rails", "~> 8.0"
gem "pg", "~> 1.5"
gem "puma", ">= 6.0"
gem "inertia_rails", "~> 3.0"
gem "solid_queue", "~> 1.0"
gem "redis", "~> 5.0"
gem "bcrypt", "~> 3.1"
gem "csv", "~> 3.3"
gem "vite_rails", "~> 3.0"
gem "tzinfo-data"
gem "turbo-rails", "~> 2.0"
gem "stimulus-rails", "~> 1.3"

group :development, :test do
  gem "dotenv-rails", require: "dotenv/load"
  gem "debug", platforms: %i[mri mingw x64_mingw]
  gem "rubocop-rails-omakase", require: false
end

group :test do
  gem "simplecov", require: false
end
