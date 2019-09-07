require 'benchmark'
require 'fileutils'

require 'rszr'
require 'mini_magick'
require 'gd2-ffij'
require 'vips'

def root
  Pathname.new(__FILE__).dirname
end

def work_path(name)
  root.join('work', name)
end

ITERATIONS = 100
ORIGINAL = root.join('..', 'spec', 'images', 'test.jpg').to_s
WIDTH = 800
HEIGHT = 532

puts 'Preparing ...'
(1..ITERATIONS).each { |i| FileUtils.cp ORIGINAL, work_path("#{i - 1}.jpg") }

Benchmark.bm(100) do |x|
  
  resized = Pathname.new(__FILE__).dirname.join('output.jpg')

  x.report 'MiniMagick' do
    ITERATIONS.times do |i|
      image = MiniMagick::Image.open(work_path("#{i}.jpg").to_s)
      image.resize "#{WIDTH}x#{HEIGHT}"
      image.write resized.to_s
      image = nil
    end
  end

  x.report 'GD2' do
    ITERATIONS.times do |i|
      image = GD2::Image.import(work_path("#{i}.jpg").to_s)
      image.resize! WIDTH, HEIGHT
      image.export resized.to_s
      image = nil
    end
  end

  x.report 'Vips' do
    ITERATIONS.times do |i|
      image = Vips::Image.new_from_file(work_path("#{i}.jpg").to_s)
      image = image.thumbnail_image(WIDTH, height: HEIGHT)
      image.jpegsave(resized.to_s)
      image = nil
    end
  end

  x.report 'Rszr' do
    ITERATIONS.times do |i|
      image = Rszr::Image.load(work_path("#{i}.jpg").to_s)
      image.resize! WIDTH, HEIGHT
      image.save resized.to_s
      image = nil
    end
  end
end
