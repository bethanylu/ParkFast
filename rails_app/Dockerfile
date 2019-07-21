FROM ruby:2.6
EXPOSE 3000
RUN apt-get update && apt-get install -y build-essential nodejs
WORKDIR /app
COPY parkfast/Gemfile /app/parkfast/
RUN gem update bundler
RUN bundle install --gemfile=/app/parkfast/Gemfile
CMD ["rails", "server", "-b", "0.0.0.0"]
