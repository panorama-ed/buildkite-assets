FROM ruby:2.3

RUN gem install bundler

COPY ./ ./

RUN bundle install
