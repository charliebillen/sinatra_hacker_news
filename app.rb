require 'sinatra'
require 'sinatra/activerecord'

class CreateSubmissionTable < ActiveRecord::Migration
  def self.change
    create_table :submissions do |t|
      t.integer :votes, null: false, default: 0
      t.integer :score, null: false, default: 0
      t.string :url, null: false
      t.string :title, null: false
      t.timestamps
    end
  end
end

ActiveRecord::Base.establish_connection adapter: 'sqlite3', database: 'app.db'
CreateSubmissionTable.change unless ActiveRecord::Base.connection.table_exists? :submissions

class Submission < ActiveRecord::Base
  GRAVITY = 1.8

  scope :by_score_descending, -> { order('score desc') }

  validates_presence_of :title, :url

  def age
    (DateTime.now.to_i - self.created_at.to_i) / 60 / 60
  end

  def calculate_score
    (self.votes - 1) / (self.age + 2) ** GRAVITY
  end
  protected :calculate_score

  def host
    URI.parse(self.url).host
  end

  def upvote!
    self.votes += 1
    self.score = self.calculate_score
    self.save!
  end
end

get '/' do
  @submissions = Submission.by_score_descending
  erb :index
end

get '/upvote/:id' do
  submission = Submission.find(params[:id])
  submission.upvote!
  redirect '/'
end

get '/new' do
  erb :new
end

post '/create' do
  submission = Submission.new
  submission.title = params[:title]
  submission.url = params[:url]
  submission.save
  redirect '/'
end

__END__

@@layout
<!doctype html>
<html lang='en'>
  <head>
    <title>Sinatra Hacker News</title>
    <style>
    .container {
      font: 0.8em/1.2em sans-serif;
      width: 60%;
      margin: 0 auto;
      color: lightslategray;
    }
    .detail {
      width: 100%;
    }
    .menu {
      border-bottom: 1px dashed lightslategray;
      width: 100%;
      margin-bottom: 5px;
      padding-bottom: 5px;
    }
    .link {
      text-decoration: none;
      font-weight: bold;
      color: darkslategray;
    }
    .link:hover {
      text-decoration: underline;
    }
    </style>
  </head>
  <body>
    <div class='container'>
      <div class='menu'>
        <a href='/' class='link'>Links</a> |
        <a href='/new' class='link'>Submit</a>
      </div>
      <%= yield %>
    </div>
  </body>
</html>

@@index
<table class='links'>
  <% @submissions.each_with_index do |submission, index| %>
    <tr>
      <td><%= index + 1 %></td>
      <td class='detail'>
        <a href='<%= submission.url %>' target='_blank' class='link'><%= submission.title %></a>
        <span>(<%= submission.host %>) <%= submission.score %> points, <%= submission.age %> hours ago</span>
      </td>
      <td><a href='<%= "/upvote/#{submission.id}" %>' class='link'>Upvote</a></td>
    </tr>
  <% end %>
</table>

@@new
<form action='/create' method='post'>
  <label>Title: <input type='text' name='title' placeholder='Title...' /></label>
  <br />
  <label>URL: <input type='text' name='url' placeholder='URL...' /></label>
  <br />
  <input type='submit' value='OK' />
</form>
