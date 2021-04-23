RSpec.describe 'Rszr' do

  context 'Garbage collection' do
    
    it 'releases instances' do
      10.times { GC.start(full_mark: true, immediate_sweep: true); sleep 0.5; print '.' }
      expect(ObjectSpace.each_object(Rszr::Image).count).to eq(0)
      20.times { Rszr::Image.load(RSpec.root.join('images/bacon.png')) }
      expect(ObjectSpace.each_object(Rszr::Image).count).to be > 0
      5.times { GC.start(full_mark: true, immediate_sweep: true); sleep 0.5; print '.' }
      expect(ObjectSpace.each_object(Rszr::Image).count).to eq(0)
    end
    
  end

  context 'Threading' do

    def data
      @data ||= RSpec.root.join('images', 'bacon.png').binread.freeze
    end

    def resize
      Tempfile.open('src') do |src_file|
        src_file.binmode
        src_file.write data
        Rszr::Image.open(src_file.path) do |image|
          image.resize!(200, :auto)
          Tempfile.open('dst') do |dst_file|
            image.save(dst_file.path)
            dst_file.close(true)
          end
        end
        src_file.close(true)
      end
    end

    it 'synchronizes access to imlib2 context by GIL' do
      threads = []
      10.times do |t|
        threads << Thread.new do
          1000.times do |i|
            print '.'
            resize
          end
        end
      end
      threads.each(&:join)
      puts
    end

  end
end
