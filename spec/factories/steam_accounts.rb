FactoryBot.define do
  factory :steam_account do
    unique_name { Faker::Internet.unique.username(specifier: 8) }
    steam_id { Faker::Number.unique.number(digits: 17).to_s }
    steam_web_api_key { Faker::Crypto.sha256 }
    waxpeer_api_key { nil }
    csgoempire_api_key { Faker::Crypto.sha256 }
    active { true }
    association :user
    sold_item_job_id { Faker::Alphanumeric.alphanumeric(number: 10) }
    valid_account { false }
    steam_account_name { Faker::Internet.username }
    steam_password { Faker::Internet.password(min_length: 8) }
    steam_identity_secret { Faker::Crypto.sha256 }
    steam_shared_secret { Faker::Crypto.sha256 }
  end
end
