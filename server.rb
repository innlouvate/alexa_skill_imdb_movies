require 'sinatra'
require 'json'
require 'imdb'

post '/' do
  parsed_request = JSON.parse(request.body.read)

  if parsed_request["request"]["intent"]["name"] == "AMAZON.StartOverIntent"
    {
      version: "1.0",
      sessionAttributes: {},
      response: {
        outputSpeech: {
          type: "PlainText",
          text: "Okay, starting over. What movie would you like to know about?"
        },
        shouldEndSession: false
      }
    }.to_json

  elsif parsed_request["request"]["intent"]["name"] == "MovieFacts"
    requested_movie = parsed_request["request"]["intent"]["slots"]["Movie"]["value"]
    movie = Imdb::Search.new(requested_movie).movies.first
    {
      version: "1.0",
      sessionAttributes: {
        movieTitle: requested_movie
      },
      response: {
        outputSpeech: {
            type: "PlainText",
            text: "#{movie.plot_synopsis.slice(0, 140)}. You can ask who directed that, or who starred in it."
          }
      }
    }.to_json

  elsif parsed_request["request"]["intent"]["name"] == "FollowUp"
    movie_title = parsed_request["session"]["attributes"]["movieTitle"]
    movie_list = Imdb::Search.new(movie_title).movies
    movie = movie_list.first
    role = parsed_request["request"]["intent"]["slots"]["Role"]["value"]

    if role == "directed"
      response_text = "#{movie_title} was directed by #{movie.director.join.slice(0, 140)}. You can ask who starred in #{movie_title} or start over."
    end

    if role == "starred in"
      response_text = "#{movie_title} starred #{movie.cast_members.join(", ").slice(0, 140)}. You can ask who directed #{movie_title} or start over."
    end

    {
      version: "1.0",
      sessionAttributes: {
        movieTitle: movie_title
      },
      response: {
        outputSpeech: {
          type: "PlainText",
          text: response_text
        }
      }
    }.to_json
  else
    {
      version: "1.0",
      response: {
        outputSpeech: {
            type: "PlainText",
            text: "Sorry I didn't understand that"
          }
      }
    }.to_json
  end
end
