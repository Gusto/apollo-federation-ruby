FROM cimg/ruby:2.7.5-node

RUN gem update --system
RUN gem install bundler -v 2.3.6

ADD . / ./
