FROM ruby:3.1.1

WORKDIR /app
COPY . /app

RUN gem install bundler && bundle install
EXPOSE 4567

CMD ["bundle", "exec", "rackup", "--host", "0.0.0.0", "-p","4567"]

