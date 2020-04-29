require "redcarpet"
require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "tilt/erubis"
require "pry"
require "yaml"
require 'bcrypt'

configure do
  enable :sessions
  set :session_secret, 'secret'
end

# method that returns the correct path to where the documents will be stored based on the current environment
def data_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/data", __FILE__)
  else
    File.expand_path("../data", __FILE__)
  end
end

def render_markdown(text)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(text)
end

def load_file_content(path)
  file_extension = File.extname(path)

  unless [".txt", ".md", ".yml"].include?(file_extension)
    session[:message] = "That's an invalid file type"
    redirect "/"
  end

  content = File.read(path)
  case file_extension
  when ".txt"
    headers["Content-Type"] = "text/plain"
    content
  when ".md"
    erb render_markdown(content)
  when ".yml"
    YAML.load_file(path)
  end
end

def file_extension?(file_name)
  !(File.extname(file_name).empty?)
end

def user_signed_in?
  session.key?(:username)
end

def redirect_logged_out
  unless user_signed_in?
    session[:message] = "You must be signed in to do that."
    redirect "/"
  end
end
# get "/"               display all the files in the data directory
# get "/new_document"   render the create new document form
# get "/:filename"      view content of a file
# get "/:filename/edit" render the edit document form
# get "/sign_in"        render sign in form

# post "/new_document"    create a new file
# post "/:filename"       update file content
#post "/:filename/delete" delete a file

get "/" do
  # binding.pry
  pattern = File.join(data_path, "*")
  @docs = Dir.glob(pattern).map { |path| File.basename(path) }
  erb :index
end

# render signin form
get "/users/signin" do
  erb :signin
end

# render signup form
get "/users/signup" do
  erb :signup
end

# render a new document form
get "/new_document" do
  redirect_logged_out
  erb :new_document
end

get "/:filename" do
  file_path = File.join(data_path, params[:filename])

  if File.exist?(file_path)
    load_file_content(file_path)
  else
    session[:message] = "#{params[:filename]} is not a valid filename"
    redirect "/"
  end
end

# render template to edit document's content
get "/:filename/edit" do
  redirect_logged_out

  file_path = File.join(data_path, params[:filename])

  @file_name = params[:filename]
  @content = File.read(file_path)

  erb :edit_doc
end

# render template to duplicate document's content
get "/:filename/duplicate" do
  redirect_logged_out
  session[:filename] = params[:filename]
  erb :duplicate_doc
end

post "/users/signup" do

  name = params[:username]
  password = params[:password]

  if password.empty? || name.empty?
    session[:message] = "Empty Credentials are not accepted"
    status 422
    erb :signup
  else
    password = BCrypt::Password.create(password)
    password = BCrypt::Password.new(password)

    users_file_path = File.join(data_path, "users.yml")
    users = load_file_content(users_file_path)

    users[name] = password.to_s

    File.open(users_file_path, 'w') do |out|
      YAML.dump(users, out)
    end
  end
end

post "/users/signin" do
  users_file_path = File.join(data_path, "users.yml")

  users = load_file_content(users_file_path)
  name = params[:username]
  password = params[:password]
  stored_password = BCrypt::Password.new(users[name])

  if users[name] && stored_password == password
    session[:username] = name
    session[:message] = "Welcome! #{name}"
    redirect "/"
  else
    session[:message] = "Invalid Credentials"
    status 422
    erb :signin
  end
end

post "/users/signout" do
  session.delete(:username)
  session[:message] = "You have been signed out."
  redirect "/"
end

# create new file
post "/new_document" do
  redirect_logged_out

  file_name = params[:filename].to_s

  if file_name.empty? || !file_extension?(file_name)
    session[:message] = "A name with a file extension is required"
    status 422
    erb :new_document
  else
    file_path = File.join(data_path, file_name)

    File.write(file_path, "")

    session[:message] = "#{params[:filename]} was created"
    redirect "/"
  end
end

# create a duplicate file
post "/duplicate" do
  redirect_logged_out

  new_file = params[:filename].to_s
  origin_file = session.delete(:filename)

  if new_file.empty? || !file_extension?(new_file)
    session[:message] = "A name with a file extension is required"
    status 422
    erb :new_document
  else
    new_file_path = File.join(data_path, new_file)
    origin_file_path = File.join(data_path, origin_file)
    origin_file_content = File.read(origin_file_path)

    #binding.pry

    File.copy_stream(origin_file_path, new_file_path)

    session[:message] = "#{params[:filename]} was created"
    redirect "/"
  end
end

# update file content
post "/:filename" do
  redirect_logged_out

  file_path = File.join(data_path, params[:filename])

  File.write(file_path, params[:content])

  session[:message] = "#{params[:filename]} has been updated"
  redirect "/"
end

#delete a file
post "/:filename/delete" do
  redirect_logged_out

  file_path = File.join(data_path, params[:filename])

  File.delete(file_path)

  session[:message] = "#{params[:filename]} was deleted"
  redirect "/"
end
