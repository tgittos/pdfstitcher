require 'rubygems'
require 'bundler/setup'
require 'sinatra'
require 'json'
require 'logger'
require 'base64'

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
    filename = "#{generate_uid}.pdf"
    file = Pdfer::Pdfer.new.compile_pdf(:url => params[:url], :filename => filename)
    { :success => true, :pdf => file }.to_json
  end
end

post '/stitch_files' do
  # paths for downloading the resulting file
  today = Date.today.strftime("%Y%m%d")
  write_dir = File.join("public", "pdfs", today)
  data = params[:files]
  base_path = "uploads/#{generate_uid}"
  FileUtils.mkdir_p(base_path) unless File.directory?(base_path)
  FileUtils.mkdir_p(write_dir) unless File.directory?(write_dir)
  filename = "#{generate_uid}.pdf"
  files = data.collect{|d| upload_file(d.last, base_path)}
  file = Pdfer::Pdfer.new.concat_pdfs(:concat_only => base_path, :filename => File.join(write_dir, filename))
  # clean temp files
  FileUtils.rm_rf(base_path)
  { :success => true, :pdf => file.split('/')[1..-1].join('/') }.to_json
end

private

def upload_file(f, base_path)
  filename = f[:filename]
  data = f[:data]
  data_index = data.index('base64') + 7
  filedata = data.slice(data_index, data.length)
  decoded_file = Base64.decode64(filedata)
  path = File.join(base_path, filename)
  file = File.new(path, "w+")
  file.write(decoded_file)
  path
end

def generate_uid
  (0...16).map{(65+rand(26)).chr}.join
end