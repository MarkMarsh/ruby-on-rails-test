# Derived from: http://kubernetes-rails.com/
#
FROM ruby:2.7

# get updated versions of node and yarn
RUN curl https://deb.nodesource.com/setup_12.x | bash
RUN curl https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

# and install them
RUN apt-get update && apt-get install -y nodejs yarn 

# copy the app to /app - do the Gemfile first to save compile time if nothing has changed
RUN mkdir /app
WORKDIR /app
COPY Gemfile Gemfile.lock ./
RUN gem install bundler
RUN bundle install
COPY . .

# make sure yarn packages are up to date
# https://classic.yarnpkg.com/en/docs/cli/check
RUN yarn install --check-files

RUN rake assets:precompile

EXPOSE 3000
CMD ["rails", "server", "-b", "0.0.0.0"]

