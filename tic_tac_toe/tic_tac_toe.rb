require 'pry'
class Board
  WINNING_LINES = [[1, 2, 3], [4, 5, 6], [7, 8, 9],
                   [1, 4, 7], [2, 5, 8], [3, 6, 9],
                   [1, 5, 9], [3, 5, 7]]

  attr_reader :squares

  def initialize
    @squares = {}
    reset
  end

  def []=(key, marker)
    @squares[key].marker = marker
  end

  def empty_square_numbers
    squares.select { |_, value| value.marker == Square::INITIALIZE_MARKER }.keys
  end

  def full?
    empty_square_numbers.empty?
  end

  def detect_winning_marker
    WINNING_LINES.each do |line_array|
      winning_line_content = line_array.map { |key| squares[key].marker }

      if winning_line_content.uniq.size == 1 &&
         winning_line_content.uniq[0] != ' '
        return(winning_line_content[0])
      end
    end
    false
  end

  def someone_won?
    !!detect_winning_marker
  end

  def reset
    1.upto(9) { |key| @squares[key] = Square.new }
  end

  # rubocop:disable Metrics/AbcSize
  def draw
    puts " " * 5 + "     |     |     "
    puts " " * 5 + "  #{squares[1]}  |  #{squares[2]}  |  #{squares[3]}"
    puts " " * 5 + "     |     |     "
    puts " " * 5 + "----------------"
    puts " " * 5 + "     |     |     "
    puts " " * 5 + "  #{squares[4]}  |  #{squares[5]}  |  #{squares[6]}"
    puts " " * 5 + "     |     |     "
    puts " " * 5 + "----------------"
    puts " " * 5 + "     |     |     "
    puts " " * 5 + "  #{squares[7]}  |  #{squares[8]}  |  #{squares[9]}"
    puts " " * 5 + "     |     |     "
  end
  # rubocop:enable Metrics/AbcSize
end

class Square
  INITIALIZE_MARKER = " "

  attr_accessor :marker

  def initialize(marker = INITIALIZE_MARKER)
    @marker = marker
  end

  def to_s
    @marker
  end
end

class Player
  attr_accessor :name, :marker, :wins

  def initialize
    self.wins = 0
  end

  def set_name(computer = nil)
    name_choice = nil
    loop do
      puts "\nwhat's your #{computer}name?"
      name_choice = gets.chomp
      break if name_choice.size >= 1 && name_choice != ' '
      puts "that doesn't seem right, please try again\n\n"
    end
    self.name = name_choice
  end

  def set_marker
    marker_choice = nil
    loop do
      puts "\nwhat marker do you want #{name}.? It can be any single "\
           "character except for a space"
      marker_choice = gets.chomp
      break if marker_choice.size == 1 && marker_choice != ' '
      puts "invalid choice, please try again\n\n"
    end
    self.marker = marker_choice
  end

  def score_reset
    self.wins = 0
  end
end

class Computer < Player
  def initialize
    super
    @marker = "O"
  end
end


class TTTGame
  FIRST_PLAYER = "choose"
  WINNING_SCORE = 2

  attr_reader :board, :human, :computer
  attr_accessor :current_marker

  def initialize
    @board = Board.new
    @human = Player.new
    @computer = Computer.new
  end

  def play
    clear
    display_welcome_message
    set_names_markers

    self.current_marker = set_first_player
    loop do
      clear_screen_and_display_board

      loop do
        current_player_moves
        break if board.someone_won? || board.full?
        clear_screen_and_display_board
      end

      display_result
      prompt_next_game
      update_wins
      reset_board

      next unless grand_winner?

      display_grand_winner if grand_winner?

      break unless play_again?
      reset_board
      reset_wins_and_first_to_play if grand_winner?
    end

    display_goodbye_message
  end

  private

  def display_welcome_message
    puts "Welcome to Tic Tac Toe!"
  end

  def set_names_markers
    human.set_name
    computer.set_name("computer's ")
    human.set_marker
  end

  def decide_first_player
    choice = nil
    loop do
      puts "\nwho should have the first move for this race to #{WINNING_SCORE}"\
           " points (1 win = 1 point),\n#{computer.name} or you #{human.name}? "\
           "(#{computer.name}/#{human.name})"
      choice = gets.chomp
      valid_choices = [computer.name, human.name]
      return(choice) if valid_choices.include?(choice)
      puts "that's not a valid choice, let's try again\n\n"
    end

    choice == computer.name ? "computer" : "player"
  end

  def set_first_player(choice_made = nil)
    if FIRST_PLAYER == "player" || choice_made == human.name
      human.marker
    elsif FIRST_PLAYER == "computer" || choice_made == computer.name
      computer.marker
    else
      set_first_player(decide_first_player)
    end
  end

  def display_goodbye_message
    puts "\nThanks for playing Tic Tac Toe! Hasta La Vista!"
  end

  def display_board
    puts "You're a #{human.marker}. Computer is a #{computer.marker}."
    puts ""
    board.draw
    puts ""
  end

  def display_grand_winner
    case who_won?
    when :human
      puts "\nYou made it to #{WINNING_SCORE} wins first!\n\n"
    else
      puts "\nThe computer made it to #{WINNING_SCORE} "\
           "wins first! ah well\n\n"
    end
  end

  def clear_screen_and_display_board
    clear
    display_board
  end

  def prompt_next_game
    puts "\npress return to continue"
    gets.chomp
  end

  def joinor(available_choices, first_delimiter= ', ', second_delimiter = 'or')
    return(available_choices.join) if available_choices.size < 2
    if available_choices.size == 2
      available_choices.join(" #{second_delimiter} ")
    else
      available_choices[0..-2].join(first_delimiter) + first_delimiter +
      "#{second_delimiter} #{available_choices[-1]}"
    end
  end

  def human_moves
    puts "Choose an available square: #{joinor(board.empty_square_numbers)}"
    square = nil
    loop do
      square = gets.chomp.to_i
      break if board.empty_square_numbers.include?(square)
      puts "Sorry, that's not a valid choice"
    end

    board[square] = human.marker
  end

  def computer_strategic_choice(strategy)
    marker_search = case strategy
                    when :defensive then human.marker
                    when :offensive then computer.marker
                    end

    square = nil

    Board::WINNING_LINES.each do |line_array|
      winning_line_content = line_array.map { |key| board.squares[key].marker }

      if winning_line_content.count(marker_search) == 2 &&
         winning_line_content.include?(' ')
        square = line_array.select do |key|
                   board.squares[key].marker == ' '
                 end
        break
      end
    end
    square
  end

  def computer_moves
    choice =
      if computer_strategic_choice(:offensive)
        computer_strategic_choice(:offensive).first
      elsif computer_strategic_choice(:defensive)
        computer_strategic_choice(:defensive).first
      elsif board.empty_square_numbers.include?(5)
        5
      else
        board.empty_square_numbers.sample
      end

    board[choice] = computer.marker
  end

  def who_won?
    case board.detect_winning_marker
    when human.marker     then :human
    when computer.marker  then :computer
    else                       :tie
    end
  end

  def display_result
    clear_screen_and_display_board

    case who_won?
    when :human     then puts "You won the match!"
    when :computer  then puts "The Computer won the match!"
    else                       puts "it's a didly darn tie"
    end
  end

  def update_wins
    case who_won?
    when :human     then human.wins += 1
    when :computer  then computer.wins += 1
    end
  end

  def play_again?
    choice = nil
    loop do
      puts "Would you like to play again? (y/n)"
      choice = gets.chomp.downcase
      break if ["yes", "no", "y", "n"].include?(choice)
      puts "that's not a valid choice, try again"
    end
    ["yes", "y"].include?(choice)
  end

  def clear
    system('clear') || system('cls')
  end

  def grand_winner?
    human.wins == WINNING_SCORE ||
    computer.wins == WINNING_SCORE
  end

  def reset_wins_and_first_to_play
    human.score_reset
    computer.score_reset
    self.current_marker = set_first_player
  end

  def reset_board
    board.reset
    clear
  end

  def current_player_moves
    if current_marker == human.marker
      human_moves
      self.current_marker = computer.marker
    else
      computer_moves
      self.current_marker = human.marker
    end
  end
end

game = TTTGame.new
game.play
