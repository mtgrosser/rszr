require 'benchmark'
require 'rszr'
require 'mini_magick'
require 'gd2-ffij'

ITERATIONS = 100

Benchmark.bm(100) do |x|
  original = Pathname.new(__FILE__).dirname.join('../spec/images/test.jpg')
  resized = Pathname.new(__FILE__).dirname.join('output.jpg')

  x.report 'MiniMagick' do
    ITERATIONS.times do
      image = MiniMagick::Image.open(original.to_s)
      image.resize '800x532'
      image.write resized.to_s
    end
  end

  x.report 'GD2' do
    ITERATIONS.times do
      image = GD2::Image.import(original.to_s)
      image.resize! 800, 532
      image.export resized.to_s
    end
  end
  
  x.report 'Rszr' do
    ITERATIONS.times do
      image = Rszr::Image.load(original.to_s)
      image.resize! 800, 532
      image.save resized.to_s
    end
  end
end
