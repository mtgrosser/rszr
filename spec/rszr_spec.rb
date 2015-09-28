RSpec.describe 'Rszr' do

  it 'has a version number' do
    expect(Rszr::VERSION).to_not be_nil
  end
  
  it 'raises an error when trying to load a non-existing image' do
    expect { Rszr::Image.load(RSpec.root.join('images/foo.jpg')) }.to raise_error(Rszr::FileNotFound)
  end
  
  it 'raises an error when trying to load a non-supported image' do
    expect { Rszr::Image.load(RSpec.root.join('images/broken.jpg')) }.to raise_error(Rszr::ImageLoadError)
  end

  it 'loads images with uppercase extension' do
    expect(Rszr::Image.load(RSpec.root.join('images/CHUNKY.PNG'))).to be_kind_of(Rszr::Image)
  end

  it 'provides the image format as lowercase' do
    expect(Rszr::Image.load(RSpec.root.join('images/CHUNKY.PNG')).format).to eq('png')
  end
  
  context 'Resizing images' do

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
      expect(@image.resize(0.5).dimensions).to eq([750, 498])
    end
  
    it 'by max width' do
      expect(@image.resize(500, :auto).dimensions).to eq([500, 332])
    end
  
    it 'by max height' do
      expect(@image.resize(:auto, 100).dimensions).to eq([150, 100])
    end
    
    it 'by narrower bounding box' do
      expect(@image.resize(200, 200).dimensions).to eq([200, 133])
    end
    
    it 'by wider bounding box' do
      expect(@image.resize(400, 100).dimensions).to eq([150, 100])
    end
    
  end
end
