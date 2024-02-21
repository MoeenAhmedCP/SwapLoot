module CsgoEmpireApiHelpers
  def stub_get_inventory(csgoempire_api_key)
    url = 'https://csgoempire.com/api/v2/trading/user/inventory'

    stub_request(:get, url)
      .with(headers: { 'Authorization' => "Bearer #{csgoempire_api_key}" })
      .to_return(
        status: 200,
        body: {
          success: true,
          updatedAt: 1666082810,
          allowUpdate: true,
          data: inventory_data
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  def stub_items_bid_history(csgoempire_api_key)
    url = 'https://csgoempire.com/api/v2/trading/user/auctions'

    stub_request(:get, url).
      with(headers: { 'Authorization' => "Bearer #{csgoempire_api_key}" }).
      to_return(
        status: 200,
        body: auctions_body,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  def stub_socket_meta_data(csgoempire_api_key)
    url = 'https://csgoempire.com/api/v2/metadata/socket'
    
    stub_request(:get, url).
      with(headers: { 'Authorization'=>"Bearer #{csgoempire_api_key}" }).
      to_return(
        status: 200,
        body: meta_data_body,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  private

  def inventory_data
    return (1..1_000_0).map do
      {
        asset_id: Faker::Number.unique.number(digits: 10),
        created_at: Faker::Time.between(from: 2.years.ago, to: Time.now).strftime('%Y-%m-%d %H:%M:%S'),
        custom_price_percentage: nil,
        full_position: Faker::Number.between(from: 1, to: 100),
        icon_url: Faker::Internet.url,
        id: Faker::Number.unique.number(digits: 10),
        invalid: Faker::Lorem.sentence,
        is_commodity: Faker::Boolean.boolean,
        market_name: Faker::Commerce.product_name,
        market_value: Faker::Number.between(from: 1000, to: 50000),
        name_color: Faker::Color.hex_color,
        position: nil,
        preview_id: Faker::Alphanumeric.alphanumeric(number: 12),
        price_is_unreliable: Faker::Number.between(from: 0, to: 1),
        stickers: [],
        tradable: Faker::Boolean.boolean,
        tradelock: Faker::Boolean.boolean,
        updated_at: Faker::Time.between(from: 2.years.ago, to: Time.now).strftime('%Y-%m-%d %H:%M:%S'),
        wear: Faker::Number.decimal(l_digits: 1, r_digits: 3)
      }
    end
  end

  def meta_data_body
    {
      "user" => {
        "id" => 303119,
        "steam_id" => "76561198106192114",
        "steam_id_v3" => "145926386",
        "steam_name" => "Artemis",
        "avatar" => "https://steamcdn-a.akamaihd.net/steamcommunity/public/images/avatars/4f/4f619bc788f0d41261d2a5ced0e96a281af88479_full.jpg",
        "profile_url" => "https://steamcommunity.com/id/G0FastMen/",
        "registration_timestamp" => "2016-07-27 23:20:03",
        "registration_ip" => "0.0.0.0",
        "last_login" => "2021-11-29 13:02:54",
        "balance" => 0,
        "total_profit" => 0,
        "total_bet" => 0,
        "betback_total" => 0,
        "bet_threshold" => 0,
        "total_trades" => 0,
        "total_deposit" => 0,
        "total_withdraw" => 0,
        "withdraw_limit" => 0,
        "csgo_playtime" => 0,
        "last_csgo_playtime_cache" => "2016-07-27 23:20:03",
        "trade_url" => "https://steamcommunity.com/tradeoffer/new/?partner=145926386&token=ABCDEF",
        "trade_offer_token" => "ABCDEF",
        "ref_id" => 0,
        "total_referral_bet" => 0,
        "total_referral_commission" => 0,
        "ref_permission" => 0,
        "ref_earnings" => 0,
        "total_ref_earnings" => 0,
        "total_ref_count" => 0,
        "total_credit" => 0,
        "referral_code" => "Artemis",
        "referral_amount" => 50,
        "muted_until" => 1632354690,
        "mute_reason" => "Other",
        "admin" => 0,
        "super_mod" => 0,
        "mod" => 0,
        "utm_campaign" => "",
        "country" => "",
        "is_vac_banned" => 2,
        "steam_level" => 343,
        "last_steam_level_cache" => "2021-11-30 07:41:07",
        "whitelisted" => 1,
        "total_tips_received" => 0,
        "total_tips_sent" => 0,
        "withdrawal_fee_owed" => "0.0000",
        "flags" => 0,
        "ban" => nil,
        "balances" => [],
        "level" => 0,
        "xp" => 0,
        "socket_token" => "",
        "user_hash" => "",
        "hashed_server_seed" => "",
        "intercom_hash" => "",
        "roles" => [],
        "eligible_for_free_case" => false,
        "extra_security_type" => "2fa",
        "total_bet_skincrash" => 0,
        "total_bet_matchbetting" => 0,
        "total_bet_roulette" => 0,
        "total_bet_coinflip" => 0,
        "total_bet_supershootout" => 0,
        "p2p_telegram_notifications_allowed" => true,
        "p2p_telegram_notifications_enabled" => true,
        "verified" => false,
        "hide_verified_icon" => false,
        "unread_notifications" => [],
        "last_session" => {},
        "email" => "",
        "email_verified" => false,
        "eth_deposit_address" => "",
        "btc_deposit_address" => "",
        "ltc_deposit_address" => "",
        "bch_deposit_address" => "",
        "steam_inventory_url" => "https://steamcommunity.com/profiles/76561198106192114/inventory/#730",
        "steam_api_key" => "",
        "has_crypto_deposit" => true,
        "chat_tag" => {},
        "linked_accounts" => [],
        "api_token" => "nice try"
      },
      "socket_token" => "",
      "socket_signature" => ""
    }.to_json
  end

  def auctions_body
    {
      "success" => true,
      "active_auctions" => [
        {
          "auction_ends_at" => 1666083221,
          "auction_highest_bid" => 227,
          "auction_highest_bidder" => 303119,
          "auction_number_of_bids" => 1,
          "custom_price_percentage" => 0,
          "icon_url" => "-9a81dlWLwJ2UUGcVs_nsVtzdOEdtWwKGZZLQHTxDZ7I56KU0Zwwo4NUX4oFJZEHLbXX7gNTPcUmqBwTTR7SQb37g5vWCwlxdFEC5uyncgZi0vGQJWwQudm0xtTexaD2ZOmClyVB5sL8h7mCHA",
          "is_commodity" => true,
          "market_name" => "Name Tag",
          "market_value" => 227,
          "name_color" => "D2D2D2",
          "preview_id" => nil,
          "price_is_unreliable" => true,
          "stickers" => [],
          "wear" => nil,
          "published_at" => "2022-10-18T08:51:02.803761Z",
          "id" => 11204,
           "depositor_stats" => {
            "delivery_rate_recent" => 0.6,
            "delivery_rate_long" => 0.7567567567567568,
            "delivery_time_minutes_recent" => 7,
            "delivery_time_minutes_long" => 7,
            "steam_level_min_range" => 5,
            "steam_level_max_range" => 10,
            "user_has_trade_notifications_enabled" => false,
            "user_is_online" => nil
          },
          "above_recommended_price" => -5
        }
      ]
    }.to_json
  end
end
