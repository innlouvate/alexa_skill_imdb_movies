require 'sinatra'
require 'json'
require 'imdb'

post '/' do
  parsed_request = JSON.parse(request.body.read)

  case parsed_request["request"]["intent"]["name"]
  when "AMAZON.StartOverIntent"
    attributes_object = {}
    response_text = "Okay, starting over. What movie would you like to know about?"

  when "MovieFacts"
    movie_title = parsed_request["request"]["intent"]["slots"]["Movie"]["value"]
    movie = Imdb::Search.new(movie_title).movies.first
    attributes_object = {
      movieTitle: movie_title
    }
    response_text = "#{movie.plot_synopsis.slice(0, 140)}. You can ask who directed that, or who starred in it."

  when "FollowUp"
    movie_title = parsed_request["session"]["attributes"]["movieTitle"]
    movie = Imdb::Search.new(movie_title).movies.first
    role = parsed_request["request"]["intent"]["slots"]["Role"]["value"]
    attributes_object = {
      movieTitle: movie_title
    }

    if role == "directed"
      response_text = "#{movie_title} was directed by #{movie.director.join.slice(0, 140)}. You can ask who starred in #{movie_title} or start over."
    end

    if role == "starred in"
      response_text = "#{movie_title} starred #{movie.cast_members.join(", ").slice(0, 140)}. You can ask who directed #{movie_title} or start over."
    end

  else
    attributes_object = {}
    response_text = "Sorry I didn't understand that"
  end

  return {
    version: "1.0",
    sessionAttributes: attributes_object,
    response: {
      outputSpeech: {
          type: "PlainText",
          text: response_text
        }
    }
  }.to_json
end
