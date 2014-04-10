require 'rubygems'
require 'bundler/setup'
require 'sinatra'
require 'json'
require 'logger'

# set up logging

$log = Logger.new('./logs/sinatra.log')

# require dependencies
require './lib/pdfer'
require './lib/sweeper'
require './config/settings.rb'

# routes

get '/' do
  erb :index, :layout => :'layouts/main'
end

post '/stitch' do
  if params[:url].nil? || params[:url] == ''
    { :success => false, :message => "You need a URL!" }.to_json
  else
    filename = "#{(0...16).map{(65+rand(26)).chr}.join}.pdf"
    file = Pdfer::Pdfer.new.compile_pdf(:url => params[:url], :filename => filename)
    { :success => true, :pdf => file }.to_json
  end
end
