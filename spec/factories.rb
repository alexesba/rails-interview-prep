# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    role { "member" }

    trait :admin do
      role { "admin" }
    end
  end

  factory :project do
    name { Faker::App.name }
    description { Faker::Lorem.paragraph }
    status { "active" }
    association :owner, factory: :user
  end

  factory :project_membership do
    association :user
    association :project
    role { "member" }
  end

  factory :task do
    title { Faker::Lorem.sentence(word_count: 3) }
    description { Faker::Lorem.paragraph }
    status { "todo" }
    priority { :medium }
    association :project
    association :creator, factory: :user
  end

  factory :tag do
    sequence(:name) { |n| "tag#{n}" }
  end

  factory :comment do
    body { Faker::Lorem.paragraph }
    association :author, factory: :user
    association :task
  end
end
