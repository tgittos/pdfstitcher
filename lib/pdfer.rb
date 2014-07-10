#! /usr/bin/env ruby

# PDFer
#
# PDFer is a script that leverages Ghostscript to download multiple PDF files linked from
# a single web page and concatenate them into one PDF files.
#
# Basically, there are some great books available online in a chapter by chapter format
# only. This sucks, and is a pain to download. This script seeks to resolve that suck.

require 'net/http'
require 'uri'
require 'fileutils'
require 'optparse'
require 'date'
require 'logger'

module Pdfer

  class Pdfer

    def log
      $log ||= Logger.new(STDOUT)
    end

    def url
      @options[:url]
    end

    def initialize
      @temp_dir = "downloads/tmp_#{(0...16).map{(65+rand(26)).chr}.join}"
      @out_dir = "public/pdfs/"
      @download_dir = "/pdfs/"
    end

    def compile_pdf(options)
      @options = options
      log.info "Got options: #{@options.inspect}" if @options[:debug]
      # prep work
      today = Date.today.strftime("%Y%m%d")
      dir = File.join(@out_dir, today)
      filename = File.join(dir, @options[:filename])
      dl_filename = File.join(@download_dir, today, @options[:filename])
      FileUtils.mkdir_p(@temp_dir) unless File.directory?(@temp_dir)
      FileUtils.mkdir_p(dir) unless File.directory?(dir)
      # do the work
      content = fetch_page @options[:url]
      url_list = build_url_list content
      file_list = download_files url_list
      status = concatenate file_list, filename
      clean_temp_files unless @options[:debug]
      dl_filename
    end

    def concat_pdfs(options)
      @options = options
      dir = File.join(@options[:concat_only], "*")
      files = Dir[dir].reject{|p| %W{. ..}.include?(p) }
      log.info "Concatenating #{files.inspect} from #{dir}"
      concatenate(files, @options[:filename])
      @options[:filename]
    end

    def download_pdfs(url)
      content = fetch_page url
      url_list = build_url_list content
      download_files url_list
    end

    private

    def fetch_page(url)
      log.info "Downloading #{url.inspect}"
      uri = URI.parse(url)
      Net::HTTP.get(uri)
    end

    def build_url_list(text)
      url_list = []
      text.scan /href=["|']{1}([^"|']*)["|']/i do |match|
        if match[0] =~ /\.pdf$/i and not url_list.include?(match[0])
          url_list << match[0]
          log.info "Found link to #{match[0]}"
        end
      end
      url_list
    end

    def download_files (url_list)
      log.info "Downloading into temp dir #{@temp_dir}"
      file_list = []
      url_list.each_with_index do |local_url, i|
        if not local_url =~ /^http/i
          local_url = URI.join(url, local_url).to_s
        end
        filename = "#{sprintf('%02d', i)}_#{File.basename(local_url)}"
        log.info "Downloading #{local_url}..."
        uri = URI.parse(local_url)
        response = Net::HTTP.get(uri)
        open(File.join(@temp_dir, filename), "w") { |file|
          file.write(response)
        }
        file_list << File.join(@temp_dir, filename)
      end
      file_list
    end

    def concatenate (file_list, pdf)
      log.info "Starting concatenation"
      input_string = file_list.collect { |filename, i| "\"#{filename}\"" }.join(" ")
      log.info "executing `gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -sOutputFile=#{pdf} #{input_string}`"
      `gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -sOutputFile=#{pdf} #{input_string}`
      log.info "Finished concatenation"
      $?.exitstatus
    end

    def clean_temp_files
      FileUtils.rm_rf(@temp_dir)
    end

  end

end 

# Run it if we're calling from a command line
if __FILE__ == $0

  options = {
    :debug => false,
    :filename => "output.pdf"
  }

  op = OptionParser.new do |opts|
    opts.banner = "Usage: pdfer.rb [options] url"

    opts.on("-d", "--debug", "Run in debug mode (don't delete downloaded pdf files)") do |d|
      options[:debug] = true
    end

    opts.on("-o", "--output [filename]", "Output pdf file") do |o|
      options[:filename] = o
    end

    opts.on("-c", "--concatenate-only [dir]", "Concatenate the files in a given directory") do |c|
      options[:concat_only] = c
    end

  end
  op.parse!

  if !options[:concat_only] && ARGV.length < 1
    puts op.help
  else
    options[:url] = ARGV.shift
    pdfer = Pdfer::Pdfer.new
    if !options[:concat_only]
      pdfer.compile_pdf(options)
    else
      pdfer.concat_pdfs(options)
    end
  end

end
