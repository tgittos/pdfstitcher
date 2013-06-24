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

module Pdfer

  class Pdfer

    def initialize
      @temp_dir = "downloads/tmp_#{(0...16).map{(65+rand(26)).chr}.join}"
      @out_dir = "public/pdfs/"
      @download_dir = "/pdfs/"
    end

    def compile_pdf (url, pdf)
      @url = url
      # prep work
      today = Date.today.strftime("%Y%m%d")
      dir = File.join(@out_dir, today)
      filename = File.join(dir, pdf)
      dl_filename = File.join(@download_dir, today, pdf)
      FileUtils.mkdir_p(@temp_dir) unless File.directory?(@temp_dir)
      FileUtils.mkdir_p(dir) unless File.directory?(dir)
      # do the work
      content = fetch_page url
      url_list = build_url_list content
      file_list = download_files url_list
      status = concatenate file_list, filename
      clean_temp_files
      dl_filename
    end

    def download_pdfs (url)
      @url = url
      content = fetch_page url
      url_list = build_url_list content
      download_files url_list
    end

    private

    def fetch_page (url)
      uri = URI.parse(url)
      Net::HTTP.get(uri)
    end

    def build_url_list (text)
      url_list = []
      text.scan /href=["|']{1}([^"|']*)["|']/i do |match|
        url_list << match[0] if match[0] =~ /\.pdf$/ and not url_list.include? match[0]
      end
      url_list
    end

    def download_files (url_list)
      puts "Downloading into temp dir #{@temp_dir}"
      file_list = []
      url_list.each do |url|
        if not url =~ /^http/i
          filename = url
          url = ""
          @url.split('/').each_with_index do |segment, i|
            url << segment + '/' if i < @url.split('/').length - 1
          end
          url += filename
        end
        filename = File.basename(url)
        print "Downloading #{url}..."
        uri = URI.parse(url)
        response = Net::HTTP.get(uri)
        open(File.join(@temp_dir, filename), "w") { |file|
          file.write(response)
        }
        file_list << File.join(@temp_dir, filename)
        puts " done.\n"
      end
      file_list
    end

    def concatenate (file_list, pdf)
      input_string = ""
      file_list.each { |filename, i| input_string << filename << " " }
      `gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -sOutputFile=#{pdf} #{input_string}`
      $?.exitstatus
    end

    def clean_temp_files
      FileUtils.rm_rf(@temp_dir)
    end

  end

end 

# Run it if we're calling from a command line
if __FILE__ == $0
  if ARGV.length == 2 and ARGV[0] == "-download"
    pdfer = Pdfer::Pdfer.new
    pdfer.download_pdfs ARGV[1]
  else
    if ARGV.length < 2
      puts "Usage: ruby pdfer.rb url output-pdf\n"
      puts "where\n"
      puts "url\t\t\turl with list of PDF links\n"
      puts "output-pdf\t\tname of the PDF file to create\n"
    else  
      # Run it!
      pdfer = Pdfer::Pdfer.new
      pdfer.compile_pdf ARGV[0], ARGV[1]
    end
  end
end
