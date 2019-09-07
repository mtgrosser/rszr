require 'rszr/image_processing'
 
RSpec.describe 'Rszr image processing' do
  
  it 'resizes image' do
    pipeline = ImageProcessing::Rszr.source(fixture_image('bacon.png'))
    resized = pipeline.resize(50, :auto)
    expect(resized.call(save: false)).to have_dimensions(50, 42)
  end
  
  it 'accepts convert option' do
    pipeline = ImageProcessing::Rszr.source(fixture_image('test.jpg'))
    converted = pipeline.convert(:png)
    expect(converted.options[:format]).to eq(:png)
  end
  
  it 'applies format' do
    result = ImageProcessing::Rszr.convert('png').call(fixture_image('test.jpg'))
    expect(File.extname(result.path)).to eq('.png')
    expect(result.path).to have_format('png')
  end
  
  describe 'image validation' do
    it 'returns true for correct images' do
      expect(ImageProcessing::Rszr.valid_image?(fixture_image('test.jpg'))).to be(true)
    end

    it 'returns false for incorrect images' do
      expect(ImageProcessing::Rszr.valid_image?(fixture_image('broken.jpg'))).to be(false)
    end
  end
  
end
