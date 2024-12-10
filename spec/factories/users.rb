FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    password { Faker::Internet.password(min_length: 8) }
    active { true }
    discord_channel_id { Faker::Lorem.characters(number: 10) }
    discord_bot_token { Faker::Lorem.characters(number: 30) }
    discord_app_id { Faker::Lorem.characters(number: 10) }
    reset_password_token { nil }
    reset_password_sent_at { nil }
  end
end
