RSpec.describe 'Rszr' do

  it 'has a version number' do
    expect(Rszr::VERSION).to_not be_nil
  end
  
  it 'raises an error when trying to load a non-existing image' do
    expect { Rszr::Image.load(RSpec.root.join('images/foo.jpg')) }.to raise_error(Rszr::FileNotFound)
  end
  
  it 'raises an error when trying to load a non-supported image' do
    expect { Rszr::Image.load(RSpec.root.join('images/broken.jpg')) }.to raise_error(Rszr::LoadError)
  end

  it 'loads images with uppercase extension' do
    expect(Rszr::Image.load(RSpec.root.join('images/bacon.png'))).to be_kind_of(Rszr::Image)
  end

  it 'can instantiate new images' do
    expect(Rszr::Image.new(300, 400)).to be_kind_of(Rszr::Image)
  end

  context 'Images' do

    before(:each) do
      # 1500 997
      @image = Rszr::Image.load(RSpec.root.join('images/test.jpg'))
    end

    it 'provides the image format as lowercase' do
      expect(Rszr::Image.load(RSpec.root.join('images/CHUNKY.PNG')).format).to eq('png')
    end
    
    it 'provides width and height' do
      expect(@image.width).to eq(1500)
      expect(@image.height).to eq(997)
    end
    
  end  
  
  context 'Resizing' do

    before(:each) do
      # 1500 997
      @image = Rszr::Image.load(RSpec.root.join('images/test.jpg'))
    end
    
    it 'creates a new instance' do
      expect(@image.resize(0.5)).not_to be(@image)
    end
    
    it 'modifies instance in place' do
      expect(@image.resize!(0.5)).to be(@image)
    end

    it 'by scale' do
      expect(@image.resize(0.5).dimensions).to eq([750, 499])
      expect(@image.resize(Rational(1, 3)).dimensions).to eq([500, 332])
      expect(@image.resize(0.75).dimensions).to eq([1125, 748])
    end
  
    it 'by max width' do
      expect(@image.resize(500, :auto).dimensions).to eq([500, 332])
    end
  
    it 'by max height' do
      expect(@image.resize(:auto, 100).dimensions).to eq([150, 100])
    end
    
    it 'by narrower bounding box' do
      expect(@image.resize(100, 400).dimensions).to eq([100, 66])
    end
    
    it 'by wider bounding box' do
      expect(@image.resize(400, 100).dimensions).to eq([150, 100])
    end
    
    it 'skew to dimensions' do
      expect(@image.resize(100, 100, skew: true).dimensions).to eq([100, 100])
    end
    
    it 'raises on scale larger than one' do
      expect { @image.resize(2) }.to raise_error(ArgumentError, 'scale 2 out of range')
    end
    
    it 'raises on too many arguments' do
      expect { @image.resize(20, 30, 40) }.to raise_error(ArgumentError, 'wrong number of arguments (3 for 1..2)')
    end
    
    it 'raises on too few arguments' do
      expect { @image.resize }.to raise_error(ArgumentError, 'wrong number of arguments (0 for 1..2)')
    end
    
    it 'raises on nonsense arguments' do
      expect { @image.resize('foo', 'bar') }.to raise_error(ArgumentError)
    end
  
  end
  
  context 'Cropping' do
    
    before(:each) do
      @image = Rszr::Image.load(RSpec.root.join('images/test.jpg')).resize(0.1)
    end
    
    it 'crops images' do
      expect(@image.crop(40, 50, 60, 70).dimensions).to eq([60, 70])
    end
    
    it 'crops images in place' do
      expect(@image.crop!(40, 50, 60, 70)).to be(@image)
    end
    
  end
  
  context 'Saving' do
    
    before(:each) do
      @image = Rszr::Image.load(RSpec.root.join('images/test.jpg')).resize(0.1)
    end
    
    it 'saves images' do
      Dir.mktmpdir do |dir|
        resized_file = Pathname.new(File.join(dir, 'resized.jpg'))
        resized_file.unlink if resized_file.exist?
        expect(resized_file.exist?).to be(false)
        expect(@image.save(resized_file.to_s)).to be(true)
        expect(resized_file.exist?).to be(true)
      end
    end
    
    it 'raises save errors' do
      Dir.mktmpdir do |dir|
        resized_file = Pathname.new(File.join(dir, 'foo', 'bar', 'resized.jpg'))
        expect(resized_file.exist?).to be(false)
        expect { @image.save(resized_file.to_s) }.to raise_error(Rszr::SaveError, 'Non-existant path component')
      end
    end
    
  end

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
