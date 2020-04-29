module Displayable
  def prompt(message)
    puts "=> #{message}"
  end

  def clear_screen
    system('clear') || system('cls')
  end

  def display_welcome_message
    prompt("Welcome to Twenty-One!\n\n")
  end

  def display_farewell
    puts ''
    prompt("Thanks for playing!")
    puts ''
  end

  def display_introduction
    puts "\nGreetings #{user.name}, you're matched up against #{computer.name}."
    puts "\nThe rules of this 21 game are simple:\n\n"
    prompt(" you'll be given 2 cards to start and see 1 of #{computer.name}'s'"\
           " cards\n\n")
    prompt(" then you'll decide whether to hit or stay\n\n")
    prompt(" the goal is have your cards' total end up being higher then")
    puts "    your opponents' hand without exceeding 21\n\n"
    prompt(" card values are the same as with BlackJack\n\n")
    prompt(" ready to get this party started? (press enter to commence)")
    gets.chomp
  end

  def display_user_hand
    list_card_names =
      user.hand.each_with_object([]) do |card, list|
        list << "#{card[:name]} of #{card[:suit]}"
      end

    prompt("Your hand: - #{list_card_names.shift}")

    loop do
      puts "              - #{list_card_names.shift}"
      break if list_card_names.empty?
    end
    puts"  hand value: #{user.hand_total}\n\n"
  end

  def display_in_game_hands
    display_user_hand

    c_first_card = "#{computer.hand[0][:name]} of #{computer.hand[0][:suit]}"

    prompt("#{computer.name}'s hand: - #{c_first_card}")
    puts "                        - ???"
    puts"  hand value: ???\n\n"
  end

  def display_computer_hand
    list_card_names =
      computer.hand.each_with_object([]) do |card, list|
        list << "#{card[:name]} of #{card[:suit]}"
      end

    prompt("#{computer.name}'s hand: - #{list_card_names.shift}")
    loop do
      puts "              - #{list_card_names.shift}"
      break if list_card_names.empty?
    end
    puts"  hand value: #{computer.hand_total}\n\n"
  end

  def display_final_hands
    display_user_hand
    display_computer_hand
  end

  def display_computer_stay
    puts ''
    prompt("#{computer.name} stays")
    sleep 2
  end

  def display_busted
    if busted?(user)
      prompt("You Busted!!\n\n")
    else
      prompt("#{computer.name} Busted!!\n\n")
    end
  end

  def display_outcome
    case winner_or_tie
    when :user
      prompt("#{user.name} won the hand!")
    when :tie
      prompt("it's a tie")
    else
      prompt("#{computer.name} won the hand!")
    end
  end
end

class Deck
  NAMES = ['Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine',
           'Ten', 'Jack', 'Queen', 'King', 'Ace']
  VALUES = [2, 3, 4, 5, 6, 7, 8, 9, 10, 10, 10, 10, 11]
  SUITS = ['Hearts', 'Spades', 'Clubs', 'Diamonds']

  attr_accessor :game_deck

  def initialize
    @game_deck = fresh_deck
  end

  def fresh_deck
    deck = []

    SUITS.each do |suit|
      0.upto(12) do |index|
        deck << { name: NAMES[index], value: VALUES[index], suit: suit }
      end
    end
    deck.shuffle!
  end

  def deal_cards(quantity)
    game_deck.shift(quantity)
  end
end

class Player
  include Displayable

  attr_accessor :name, :hand

  def initialize
    @hand = []
  end

  def add_cards(cards)
    hand << cards
    hand.flatten!
  end

  def hand_reset
    self.hand = []
  end

  def hand_total
    sum = 0
    hand.each do |card|
      sum += card[:value]
    end

    ace_count = hand.count { |card| card[:name] == 'Ace' }

    ace_count > 0 && sum > 21 ? hand_total_ace_adjust(sum, ace_count) : sum
  end

  def hand_total_ace_adjust(sum, ace_count)
    loop do
      sum -= 10
      ace_count -= 1
      break if sum < 22 || ace_count == 0
    end
    sum
  end
end

class User < Player
  def set_name
    name_input = nil
    loop do
      prompt("what's your name?")
      name_input = gets.chomp.strip
      break unless name_input.empty?
      prompt("try again and remember that your name can't be blank,")
    end
    self.name = name_input
  end
end

class Computer < Player
  def initialize
    super
    set_name
  end

  def set_name
    machines = ['Apple Jack', 'PC Principal', 'Commondore']
    self.name = machines.sample
  end
end

module TwentyOneGame
  class Round
    include Displayable

    attr_reader :user, :computer
    attr_accessor :deck

    def initialize(user, computer)
      @user = user
      @computer = computer
      @deck = Deck.new
    end

    def play
      deal_hands
      display_in_game_hands
      user_moves

      unless busted?(user)
        computer_moves
      end

      if someone_busted?
        busted_end_match
      end

      no_bust_outcome if !someone_busted?
    end

    def busted_end_match
      clear_screen
      display_busted
      display_final_hands
    end

    def no_bust_outcome
      clear_screen
      display_final_hands
      display_outcome
    end

    def deal_hands
      user.add_cards(deck.deal_cards(2))
      computer.add_cards(deck.deal_cards(2))
    end

    def user_moves
      loop do
        choice = hit_or_stay
        if choice == 'hit'
          user.add_cards(deck.game_deck.shift)
          break if busted?(user)
          clear_screen
          display_user_hand
        elsif choice == 'stay'
          break
        end
      end
    end

    def computer_hits
      clear_screen
      puts ''
      prompt("#{computer.name} goes for the hit!")
      puts ''
      sleep 1
      computer.add_cards(deck.game_deck.shift)
      display_computer_hand if !busted?(computer)
      sleep 2
    end

    def computer_moves
      number_moves = 0
      while computer.hand_total < 17
        sleep 2 if number_moves > 0
        computer_hits
        number_moves += 1
      end

      display_computer_stay if !busted?(computer)
    end

    def hit_or_stay
      choice = nil
      loop do
        prompt("do you want to hit or stay (h/s)?")
        choice = gets.chomp.downcase
        break if ['hit', 'stay', 'h', 's'].include?(choice)
        prompt("that's not a valid choice, try again")
      end

      case choice
      when 'h', 'hit' then 'hit'
      else 'stay'
      end
    end

    def busted?(competitor)
      competitor.hand_total > 21
    end

    def someone_busted?
      busted?(user) || busted?(computer)
    end

    def winner_or_tie
      case user.hand_total <=> computer.hand_total
      when 1 then :user
      when 0 then :tie
      else :computer
      end
    end
  end

  class TotalGame
    include Displayable

    attr_reader :user, :computer, :round

    def initialize
      @user = User.new
      @computer = Computer.new
      @round = TwentyOneGame::Round.new(user, computer)
    end

    def play
      introductions

      loop do
        round.play
        play_again? ? reset_table : break
      end
      display_farewell
    end

    def introductions
      clear_screen
      display_welcome_message
      user.set_name
      clear_screen
      display_introduction
      clear_screen
    end

    def play_again?
      choice = nil
      loop do
        puts ''
        prompt("Do you want to play again? (y/n)")
        choice = gets.chomp.downcase
        break if ['y', 'n', 'yes', 'no'].include?(choice)
        prompt("invalid input, try again")
      end
      choice == 'y' || choice == 'yes'
    end

    def reset_table
      round.deck = Deck.new
      user.hand_reset
      computer.hand_reset
      clear_screen
    end
  end
end

new_game = TwentyOneGame::TotalGame.new
new_game.play
