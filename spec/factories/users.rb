# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    # Define attributes as needed
    email { Faker::Internet.email }
    password { Faker::Internet.password(min_length: 8) }
  end
end
