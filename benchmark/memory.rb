require 'memory_profiler'
require 'rszr'
require 'mini_magick'
require 'gd2-ffij'

ITERATIONS = 100

original = Pathname.new(__FILE__).dirname.join('../spec/images/test.jpg')
resized = Pathname.new(__FILE__).dirname.join('output.jpg')

mini_magick = MemoryProfiler.report do
  ITERATIONS.times do
    image = MiniMagick::Image.open(original.to_s)
    image.resize '800x532'
    image.write resized.to_s
    image = nil
  end
end

mini_magick.pretty_print(scale_bytes: true)

gd2 = MemoryProfiler.report do
  image = GD2::Image.import(original.to_s)
  image.resize! 800, 532
  image.export resized.to_s
  image = nil
end

gd2.pretty_print(scale_bytes: true)

rszr = MemoryProfiler.report do
  ITERATIONS.times do
    image = Rszr::Image.load(original.to_s)
    image.resize! 800, 532
    image.save resized.to_s
    image = nil
  end
end

rszr.pretty_print(scale_bytes: true)
