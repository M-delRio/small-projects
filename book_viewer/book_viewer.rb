require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"

before do
  @contents = File.readlines("data/toc.txt")
end

helpers do
  def in_paragraphs(text)
    text.split("\n\n").each_with_index.map do |line, index|
     "<p id=paragraph#{index}>#{line}</p>"
    end.join
  end

  def each_chapter
    @contents.each_with_index do |name, index|
      number = index + 1
      contents = File.read("data/chp#{number}.txt")
      yield number, name, contents
    end
  end

  # This method returns an Array of Hashes representing chapters that match the
  # specified query. Each Hash contain values for its :name, :number, and
  # :paragraphs keys. The value for :paragraphs will be a hash of paragraph indexes
  # and that paragraph's text.

  def chapters_matching(query)
    results = []
    return results unless query

    each_chapter do |number, name, contents|
      matches = {}
      contents.split("\n\n").each_with_index do |paragraph, index|
        matches[index] = paragraph if paragraph.include?(query)
      end
      results << {number: number, name: name, paragraphs: matches} if matches.any?
    end

    results
  end

  def highlight(paragraph, text)
    if paragraph.include?(text)
      paragraph.gsub!(text, "<strong>#{text}</strong>")
    end
  end
end

not_found do
  redirect "/"
end

get "/" do
  @title = "The Adventures of Sherlock Holmes"
  
  erb :home
end

get "/search" do
  @results = chapters_matching(params[:query])

  erb :search
end

get "/chapters/:number" do
  number = params[:number].to_i
  @chp_title = @contents[number - 1]

  redirect "/" unless (1..@contents.size).cover? number

  @title = "Chapter #{number} : #{@chp_title}"

  @chapter = File.read("data/chp#{number}.txt")

  erb :chapter
end

