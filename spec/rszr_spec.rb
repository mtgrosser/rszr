RSpec.describe 'Rszr' do

  it 'has a version number' do
    expect(Rszr::VERSION).to_not be_nil
  end

  it 'instantiates new images' do
    expect(Rszr::Image.new(300, 400)).to be_kind_of(Rszr::Image)
  end

  context 'Loading' do

    it 'loads images from disk' do
      expect(Rszr::Image.load(RSpec.root.join('images/bacon.png'))).to be_kind_of(Rszr::Image)
    end

    it 'loads image from memory' do
      expect(Rszr::Image.load_data(RSpec.root.join('images/test.jpg').binread).format).to eq('jpeg')
    end

    it 'loads images with uppercase extension' do
      expect(Rszr::Image.load(RSpec.root.join('images/bacon.png'))).to be_kind_of(Rszr::Image)
    end

    it 'raises an error when trying to load a non-existing image' do
      expect { Rszr::Image.load(RSpec.root.join('images/foo.jpg')) }.to raise_error(Rszr::FileNotFound)
    end

    it 'raises an error when trying to load a non-supported image' do
      expect { Rszr::Image.load(RSpec.root.join('images/broken.jpg')) }.to raise_error(Rszr::LoadError)
    end
  end

  context 'Images' do

    before(:each) do
      # 1500 997
      @image = Rszr::Image.load(RSpec.root.join('images/test.jpg'))
    end

    it 'provide the image format as lowercase' do
      expect(Rszr::Image.load(RSpec.root.join('images/CHUNKY.PNG')).format).to eq('png')
    end
    
    it 'provide width and height' do
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
    
    it 'saves image to memory' do
      expect(Rszr::Image.load(RSpec.root.join('images/test.jpg')).save_data(format: 'png')).to start_with("\x89PNG".force_encoding('BINARY'))
    end
    
  end
  
  context 'Autorotation' do

    %w[jpg tiff].each do |format|
      it "autorotates #{format.upcase} images" do
        1.upto(8) do |orientation|
          expect(Rszr::Image.load(RSpec.root.join('images', 'orientation', "#{orientation}.#{format}"), autorotate: true).original_orientation).to eq(orientation)
        end
      end
      
      it "ignores #{format.upcase} images without EXIF orientation" do
        expect(Rszr::Image.load(RSpec.root.join('images', 'orientation', "none.#{format}"), autorotate: true).original_orientation).to be_nil
      end
      
      it "ignores #{format.upcase} images with invalid EXIF orientation" do
        expect(Rszr::Image.load(RSpec.root.join('images', 'orientation', "invalid.#{format}"), autorotate: true).original_orientation).to be_nil
      end
    end

  end
  
  context 'Transformations' do
    before(:each) do
      @image = Rszr::Image.load(RSpec.root.join('images/test.jpg'))
    end
    
    it 'flips' do
      expect(@image.flip.dimensions).to eq(@image.dimensions)
    end

    it 'flops' do
      expect(@image.flop.dimensions).to eq(@image.dimensions)
    end
    
    it 'sharpens' do
      expect(@image.sharpen(2).dimensions).to eq(@image.dimensions)
    end
    
    it 'blurs' do
      expect(@image.blur(3).dimensions).to eq(@image.dimensions)
    end
    
    it 'brightens' do
      expect(@image.brighten(0.1).dimensions).to eq(@image.dimensions)
    end
    
    it 'darkens' do
      expect(@image.brighten(-0.1).dimensions).to eq(@image.dimensions)
    end
    
    it 'contrasts' do
      expect(@image.contrast(0.1).dimensions).to eq(@image.dimensions)
    end
    
    it 'gammas' do
      expect(@image.gamma(1.1).dimensions).to eq(@image.dimensions)
    end
    
    it 'filters' do
      expect(@image.filter('bump_map( map=tint(red=50,tint=200), blue=10 );').dimensions).to eq(@image.dimensions)
    end
  end

end
