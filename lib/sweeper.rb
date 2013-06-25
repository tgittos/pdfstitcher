require 'fileutils'

# spin up a quick and dirty sweeper thread
Thread.new do
  $log.info "launching sweeper thread"
  while true do
    today = Date.today.strftime("%Y%m%d")
    $log.info "deleting all PDFs not generated on #{today}"
    Dir.foreach("./public/pdfs") do |item|
      next if item == '.' or item == '..' or item == today
      $log.info "deleting ./public/pdfs/#{item}"
      FileUtils.rm_rf("./public/pdfs/#{item}")
    end
    sleep 60 * 60 * 12
  end
  $log.info "ending sweeper thread"
end