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
  
  it 'loads image from memory' do
    expect(Rszr::Image.load_data(RSpec.root.join('images/test.jpg').binread).format).to eq('jpg')
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
      expect { @image.resize(-0.5) }.to raise_error(ArgumentError, 'scale factor -0.5 out of range')
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
  
  context 'Turning' do
    
    before(:each) do
      @image = Rszr::Image.load(RSpec.root.join('images/test.jpg'))
    end
    
    it 'turns images clockwise' do
      expect(@image.turn!(3).dimensions).to eq([997, 1500])
    end
    
    it 'turns images counterclockwise' do
      expect(@image.turn!(-3).dimensions).to eq([997, 1500])
    end
    
    it 'turns images in place' do
      expect(@image.turn!(3)).to be(@image)
    end
    
  end
  
  context 'Duplicating' do
    
    before(:each) do
      @image = Rszr::Image.load(RSpec.root.join('images/test.jpg'))
    end
    
    it 'duplicates images' do
      expect(@image.dup).not_to be(@image)
      expect(@image.dup.dimensions).to eq(@image.dimensions)
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
    
    it 'accepts uppercase extensions' do
      Dir.mktmpdir do |dir|
        %w[JPG JPEG PNG].each do |format|
          resized_file = Pathname.new(File.join(dir, "resized.#{format}"))
          expect(@image.save(resized_file.to_s)).to be(true)
          expect(resized_file.exist?).to be(true)
        end
      end
    end
    
  end

end

