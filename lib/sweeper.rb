require 'fileutils'

# spin up a quick and dirty sweeper thread
Thread.new do
  puts "launching sweeper thread"
  while true do
    today = Date.today.strftime("%Y%m%d")
    puts "deleting all PDFs not generated on #{today}"
    Dir.foreach("./public/pdfs") do |item|
      next if item == '.' or item == '..' or item == today
      puts "deleting ./public/pdfs/#{item}"
      FileUtils.rm_rf("./public/pdfs/#{item}")
    end
    sleep 60 * 60 * 12
  end
  puts "ending sweeper thread"
end