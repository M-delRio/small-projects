class Move
  attr_accessor :move_name, :greater, :lesser

  def initialize
    @move_name = self.class.to_s.downcase
    set_order
  end

  VALUES = ['rock', 'paper', 'scissors', 'spock', 'lizard']

  def >(other_move)
    greater.include?(other_move.to_s)
  end

  def <(other_move)
    lesser.include?(other_move.to_s)
  end

  def to_s
    move_name
  end
end

class Rock < Move
  def set_order
    self.greater = ['scissors', 'lizard']
    self.lesser = ['paper', 'spock']
  end
end

class Paper < Move
  def set_order
    self.greater = ['rock', 'spock']
    self.lesser = ['scissors', 'lizard']
  end
end

class Scissors < Move
  def set_order
    self.greater = ['paper', 'lizard']
    self.lesser = ['rock', 'spock']
  end
end

class Lizard < Move
  def set_order
    self.greater = ['paper', 'spock']
    self.lesser = ['scissors', 'rock']
  end
end

class Spock < Move
  def set_order
    self.greater = ['rock', 'scissors']
    self.lesser = ['paper', 'lizard']
  end
end

class Player
  attr_accessor :move, :name, :wins, :move_history

  def initialize
    set_name
    @wins = 0
    @move_history = {
      wins: { rock: 0, paper: 0, scissors: 0, spock: 0, lizard: 0 },
      loses: { rock: 0, paper: 0, scissors: 0, spock: 0, lizard: 0 }
    }
  end

  def fix_choice(string_choice)
    case string_choice
    when 'rock' then Rock.new
    when 'paper' then Paper.new
    when 'scissors' then Scissors.new
    when 'spock' then Spock.new
    when 'lizard' then Lizard.new
    end
  end

  def games_played
    move_history[:wins].values.sum +
      move_history[:loses].values.sum
  end
end

class Human < Player
  def set_name
    n = ''
    loop do
      puts "What's your name?"
      n = gets.chomp
      break unless n.empty? || n.strip.empty?
      puts "Sorry, must enter a value."
    end
    self.name = n
  end

  def letter_to_name(letter)
    case letter
    when 'r' then 'rock'
    when 'p' then 'paper'
    when 's' then 'scissors'
    when 'sp' then 'spock'
    when 'l' then 'lizard'
    end
  end

  def choose_move
    choice = nil
    loop do
      puts "Please choose rock, paper, scissors, spock or lizard: (r/p/s/sp/l)"
      choice = gets.chomp.downcase
      if ['r', 'p', 's', 'sp', 'l'].include?(choice)
        choice = letter_to_name(choice)
      end
      break if Move::VALUES.include? choice
      puts "Sorry, invalid choice"
    end
    system('clear') || system('cls')
    self.move = fix_choice(choice)
  end
end

class Computer < Player
  COMPUTER_THRESHOLD = 3

  R2D2 = Move::VALUES + (['rock'] * 2) + (['paper'] * 2)

  HAL = ['spock', 'lizard']

  CHAPPIE = Move::VALUES + (['spock'] * 2) + (['lizard'] * 2)

  SONNY = Move::VALUES + (['paper'] * 5)

  NUMBER_5 = Move::VALUES

  attr_accessor :computer_preference

  def initialize
    super
    fix_computer_preference(name)
  end

  def set_name
    self.name = ['R2D2', 'Hal', 'Chappie', 'Sonny', 'Number 5'].sample
  end

  def fix_computer_preference(computer_name)
    self.computer_preference =
      case computer_name
      when 'R2D2' then R2D2
      when 'Hal' then HAL
      when 'Chappie' then CHAPPIE
      when 'Sonny' then SONNY
      when 'Number 5' then NUMBER_5
      end
  end

  def choose_move
    choice =
      if games_played < COMPUTER_THRESHOLD
        computer_preference.sample
      else
        move_history[:loses].sort_by { |_, value| value }.first[0].to_s
      end

    self.move = fix_choice(choice)
  end
end

class RPSGame
  BEST_OF = 5

  attr_accessor :human, :computer

  def initialize
    display_welcome_message
    @human = Human.new
    new_computer_player
  end

  def new_computer_player
    @computer = Computer.new
  end

  def display_welcome_message
    puts "Welcome to Rock, Paper, Scissors, Spock, Lizard!\n\n"\
         "First one to #{BEST_OF} wins is the grand winner\n\n"
  end

  def display_goodbye_message
    puts "Thanks for player Rock, Paper, Scissors, Spock, Lizard Good bye!"
  end

  def display_moves
    puts "#{human.name} chose #{human.move}"
    puts "#{computer.name} chose #{computer.move}."
  end

  def display_score_board
    puts "#{computer.name} has won #{computer.wins} game(s)"
    puts "#{human.name} has won #{human.wins} game(s)"
  end

  def grand_winner?
    computer.wins == BEST_OF || human.wins == BEST_OF
  end

  def display_grand_winner
    if computer.wins == BEST_OF
      puts "#{computer.name} is the first to make it to #{BEST_OF} wins!"
    else
      puts "#{human.name} is the first to make it to #{BEST_OF} wins!"
    end
  end

  def score_reset
    computer.wins = 0
    human.wins = 0
  end

  def update_human_score(outcome)
    human.wins += 1 if outcome == :wins
    human.move_history[outcome][human.move.move_name.to_sym] += 1
  end

  def update_computer_score(outcome)
    computer.wins += 1 if outcome == :wins
    computer.move_history[outcome][computer.move.move_name.to_sym] += 1
  end

  def determine_winner
    if human.move > computer.move
      human
    elsif human.move < computer.move
      computer
    end
  end

  def display_winner
    case determine_winner
    when human
      puts "#{human.name} won!\n\n"
    when computer
      puts "#{computer.name} won!\n\n"
    else
      puts "It's a tie!\n\n"
    end
  end

  def update_scores
    case determine_winner
    when human
      update_human_score(:wins)
      update_computer_score(:loses)
    when computer
      update_human_score(:loses)
      update_computer_score(:wins)
    end
  end

  def play_again?
    answer = nil
    loop do
      puts "Would you like to play again? (y/n)"
      answer = gets.chomp
      break if ['y', 'n'].include? answer.downcase
      puts "Sorry, must be y or n."
    end

    answer == 'y'
  end

  def cue_next_match
    puts "press return to start next match.."
    gets.chomp
  end

  def play_one_match
    human.choose_move
    computer.choose_move
    display_moves
    display_winner
    update_scores
  end

  def play_full_game
    loop do
      loop do
        play_one_match
        display_score_board
        break if grand_winner?
        cue_next_match
      end
      display_grand_winner
      score_reset
      new_computer_player
      break unless play_again?
    end
    display_goodbye_message
  end
end

system('clear') || system('cls')
RPSGame.new.play_full_game

#   def play
#     loop do
#       loop do
#         human.choose_move
#         computer.choose_move
#         display_moves
#         display_winner
#         update_scores
#         display_score_board
#         break if grand_winner?
#         cue_next_match
#       end
#       display_grand_winner
#       score_reset
#       new_computer_player
#       break unless play_again?
#     end
#     display_goodbye_message
#   end
# end
