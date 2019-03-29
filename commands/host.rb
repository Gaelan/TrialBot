require 'socket'

class ToSConnection
  INCOMING_MESSAGE_NAMES = {
    1 => :login_successful,
    2 => :CreateLobby,
    3 => :SetHost,
    4 => :UserJoinedGame,
    5 => :UserLeftGame,
    6 => :ChatBoxMessage,
    7 => :HostClickedOnCatalog,
    8 => :HostClickedOnPossibleRoles,
    9 => :HostClickedOnAddButton,
    10 => :HostClickedOnRemoveButton,
    11 => :HostClickedOnStartButton,
    12 => :CancelStartCountdown,
    13 => :AssignNewHost,
    14 => :VotedToRepickHost,
    15 => :NoLongerHost,
    16 => :DoNotSpam,
    17 => :HowManyPlayersAndGames,
    18 => :SystemMessage,
    20 => :friend_list,
    21 => :FriendRequestNotifications,
    22 => :AddFriendRequestResponse,
    23 => :ConfirmFriendRequest,
    24 => :SuccessfullyRemovedFriend,
    25 => :SuccessfullyDeclinedFriendRequest,
    26 => :FriendUpdate,
    27 => :FriendMessage,
    28 => :user_information,
    29 => :create_party_lobby,
    30 => :PartyInviteFailed,
    31 => :PartyInviteNotification,
    32 => :AcceptedPartyInvite,
    33 => :pending_party_invite_status,
    34 => :SuccessfullyLeftParty,
    35 => :party_chat,
    36 => :party_member_left,
    37 => :settings_information,
    38 => :AddFriend,
    39 => :ForcedLogout,
    40 => :ReturnToHomePage,
    43 => :purchased_characters,
    44 => :purchased_houses,
    45 => :purchased_backgrounds,
    46 => :selection_settings,
    47 => :RedeemCodeMessage,
    48 => :UpdatePaidCurrency,
    49 => :PurchasedPacks,
    50 => :PurchasedPets,
    51 => :set_last_bonus_win_time,
    52 => :EarnedAchievements,
    53 => :purchased_lobby_icons,
    54 => :purchased_death_animations,
    55 => :FacebookInviteFriends,
    56 => :PurchasedScrolls,
    58 => :HostGivenToPlayer,
    59 => :HostGivenToMe,
    60 => :KickedPlayer,
    61 => :KickedMe,
    62 => :invite_powers_given_to_player,
    63 => :InvitePowersGivenToMe,
    64 => :SteamFirstLogin,
    66 => :UpdateFriendUsername,
    67 => :EnableShopButtons,
    68 => :SteamPopup,
    71 => :StartRankedQueue,
    72 => :LeaveRankedQueue,
    73 => :AcceptRankedPopup,
    74 => :user_statistics,
    75 => :RankedTimeoutDuration,
    77 => :ModeratorMessage,
    78 => :ReferAFriendUpdate,
    79 => :PlayerStatistics,
    80 => :ScrollConsumed,
    81 => :AdViewResponse,
    82 => :UserJoiningLobbyTooQuicklyMessage,
    83 => :PromotionPopup,
    84 => :KickstarterShare,
    86 => :tutorial_progress,
    87 => :PurchasedTaunts,
    88 => :currency_multiplier,
    90 => :PickNames,
    142 => :UserLeftEndGameScreen,
    150 => :HousesChosen,
    153 => :CharactersChosen,
    161 => :EarnedAchievements,
    165 => :PetsChosen,
    168 => :DeathAnimationsChosen,
    171 => :EndGameInfo,
    172 => :EndGameChatMessage,
    173 => :EndGameUserUpdate,
    176 => :ExternalPurchase,
    187 => :CheckUsernameResult,
    188 => :NameChangeResult,
    189 => :AccountState,
    190 => :PurchasedAccountItems,
    191 => :AccountItemConsumed,
    193 => :ProductPurchaseResult,
    194 => :UpdateFreeCurrency,
    195 => :active_events,
    196 => :CauldronStatus,
    199 => :TauntConsumed,
    217 => :HostSetPartyConfigResult,
    218 => :active_game_modes,
    219 => :account_flags,
    224 => :ranked_info_update,
    228 => :server_flags,
    231 => :CaptchaQuestionReceived,
    232 => :CaptchaResult,
    233 => :ReferralCodes,
    234 => :ReferralFeedback,
    235 => :TicketsOwned,
    236 => :PopupInfo,
    237 => :TicketConsumed
  }

  OUTGOING_MESSAGE_IDS = {
    global_send_chat_box_msg: 3,
    global_send_system_command: 24,
    global_send_friend_add: 25,
    global_send_friend_confirm: 26,
    global_send_friend_remove: 27,
    global_send_friend_decline: 28,
    global_send_friend_msg: 29,
    global_send_afk: 38,
    global_send_return_home: 39,
    global_request_ad_view_reward: 66,
    global_request_promotion_purchase: 67,
    global_send_tutorial_progress: 69,
    global_send_captcha_answer: 87,
    global_request_referral_codes: 88,
    global_send_referral_code: 89,
    login_fb_connect: 1,
    login_request_load_homepage: 2,
    login_register_fb: 58,
    game_send_private_msg: 8,
    game_request_vote_target: 10,
    game_request_night_target: 11,
    game_request_night_target_second: 12,
    game_request_vote_guilty: 14,
    game_request_vote_innocent: 15,
    game_request_day_target: 16,
    game_send_last_will: 17,
    game_send_death_note: 18,
    game_request_mafia_target: 19,
    game_request_pass_target_msg_to_team: 19,
    game_request_name: 21,
    game_send_report: 22,
    game_send_party_msg: 36,
    game_send_return_home: 63,
    game_send_forger_forged_will: 64,
    game_request_taunt_target: 77,
    game_request_pirate_duel_selection: 78,
    game_request_potion_chosen: 79,
    game_request_hypnotist_choice: 82,
    game_send_jailor_deathnote: 83,
    home_send_customization_settings: 20,
    home_request_game: 30,
    home_request_party_create: 31,
    home_send_party_response: 33,
    home_send_game_settings: 37,
    home_request_purchase_character: 40,
    home_request_purchase_house: 41,
    home_request_purchase_background: 42,
    home_request_purchase_pack: 43,
    home_request_purchase_pet: 44,
    home_request_redeem_code: 45,
    home_send_fb_achievement_share: 46,
    home_send_fb_win_share: 47,
    home_request_purchase_lobby_icon: 48,
    home_request_purchase_death_anim: 49,
    home_send_fb_invite_friend: 50,
    home_request_purchase_scroll: 51,
    home_request_steam_order: 55,
    home_send_steam_approve: 56,
    home_request_steam_create_account: 57,
    home_request_fb_create_account: 58,
    home_request_steam_link_account: 59,
    home_request_ranked_game: 60,
    home_send_ranked_queue_leave: 61,
    home_send_ranked_queue_accept: 62,
    home_send_player_statistics: 65,
    home_request_paypal_sale: 68,
    home_kickstarter_shared: 70,
    home_request_purchase_account_item: 71,
    home_request_check_username: 72,
    home_request_name_change: 73,
    home_request_purchase_product: 74,
    home_request_cauldron_status: 75,
    home_request_cauldron_complete: 76,
    home_request_verify_account_flag: 81,
    lobby_clicked_catalog_list: 4,
    lobby_clicked_possible_roles: 5,
    lobby_request_add_role: 6,
    lobby_request_remove_role: 7,
    lobby_request_start: 9,
    lobby_request_repick: 23,
    lobby_send_party_invite: 32,
    lobby_send_party_leave: 34,
    lobby_request_party_start: 35,
    lobby_send_party_change_host: 52,
    lobby_send_party_kick: 53,
    lobby_send_party_give_invite_privileges: 54,
    lobby_host_set_party_config: 80
  }

  PARTY_INVITE_STATUSES = {
    1 => :pending,
    2 => :denied,
    3 => :accepted,
    4 => :failed,
    5 => :loading,
    6 => :cancelled,
    7 => :left,
    8 => :locale,
    9 => :no_coven
  }

  attr_reader :message

  def initialize(message)
    @message = message
  end

  def connect
    @players = {}
    @socket = TCPSocket.new 'live4.tos.blankmediagames.com', 3600
    @socket << "<policy-file-request/>\0"
    send_message :login_request_load_homepage,
                 2,
                 2,
                 1,
                 '11704',
                 30,
                 ENV['TOS_USERNAME'],
                 30,
                 ENV['TOS_PASSWORD_ENCRYPTED']
    @thread =
      Thread.new do
        while msg = @socket.gets("\0")
          begin
            type = INCOMING_MESSAGE_NAMES[msg[0].ord]
            p type, msg[1..-2]
            self.send(type, msg[1..-2])
          rescue Exception => e
            # Disconnect if anything goes wrong—this makes sure the bot will never end up in a game
            p e
            disconnect
            raise e
          end
        end
      end

    sleep 1
    send_message :home_send_game_settings, 11, 2 # 2 = English
    sleep 1
    send_message :home_request_party_create, 1 # 1 = Normal (not coven)
    message.edit('', to_embed)

    Thread.new do
      # Don't get stuck hosting a game that never starts.
      sleep 60 * 5
      disconnect
    end
  end

  def invite(name)
    send_message :lobby_send_party_invite, name
  end

  def to_embed
    embed = Discordrb::Webhooks::Embed.new
    embed.title = 'Hosting game!'
    embed.footer =
      Discordrb::Webhooks::EmbedFooter.new(
        text:
          'To join, log into Town of Salem then react to this message. To start the game before 15 people have joined, type "!start" in party chat.'
      )
    @players.keys.each do |player|
      embed.add_field(
        name: player,
        value: "<@#{User.find_by_tos_name(player).discord_id}>",
        inline: true
      )
    end

    embed
  end

  private

  def create_party_lobby(data); end

  def pending_party_invite_status(data)
    user, status_id = data.split('*')
    status = PARTY_INVITE_STATUSES[status_id.ord]
    puts "#{user} is now #{status}"
    @players[user] = status

    if status == :accepted
      send_message :lobby_send_party_give_invite_privileges, user
    end

    # Once we've got 15 people, get out.
    count =
      @players.values.count do |status|
        %i[pending accepted loading].include? status
      end
    disconnect if count >= 15

    message.edit('', to_embed)
  end

  def server_flags(data)
    @free_coven = data[0].ord > 1
  end

  def account_flags(data)
    puts "Warning: flags changed #{data[0].ord}" if data[0].ord != 49 #49 = restricted with trial
  end

  def party_chat(data)
    name, message = data.split('*')
    disconnect if message == '!start'
  end

  def party_member_left(data)
    @players[data] = :left
  end

  def invite_powers_given_to_player(data); end

  def login_successful(data); end
  def user_statistics(data); end
  def settings_information(data); end
  def selection_settings(data); end
  def currency_multiplier(data); end
  def active_events(data); end
  def user_information(data); end
  def set_last_bonus_win_time(data); end
  def purchased_characters(data); end
  def purchased_houses(data); end
  def purchased_backgrounds(data); end
  def friend_list(data); end
  def purchased_lobby_icons(data); end
  def purchased_death_animations(data); end
  def active_game_modes(data); end
  def tutorial_progress(data); end
  def ranked_info_update(data); end

  def send_message(type, *pieces)
    msg = OUTGOING_MESSAGE_IDS[type].chr
    pieces.each do |p|
      case p
      when Integer
        msg += p.chr
      when String
        msg += p
      end
    end
    msg += "\0"
    @socket << msg
  end

  def disconnect
    $tos_connection = nil
    @socket.close
    @thread.kill
  end
end

$tos_connection = nil

Bot.command :host do |event|
  if $tos_connection
    event.send ":warning: I'm currently busy starting another game. Please try again later."
    return
  end

  msg = event.send 'Getting ready...'

  $tos_connection = ToSConnection.new(msg)
  $tos_connection.connect

  msg.create_reaction('✅')
end

Bot.reaction_add do |event|
  p 'here'
  p event.message
  p $tos_connection.message
  if event.message == $tos_connection.message
    $tos_connection.invite(User.find_by_discord_id(event.user.id).tos_name)
  end
end
