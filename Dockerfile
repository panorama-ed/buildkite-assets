FROM ruby:3.1.3

COPY ./ ./

RUN bundle install
