# Rszr

Rszr is a fast image resizer.

## Installation

In your Gemfile:

```ruby
gem 'rszr'
```

## Usage

```ruby
# bounding box 400x300
image = Rszr::Image.load('image.jpg')
image.resize(400, 300)
image.save('resized.jpg')

# auto height
image.resize(400, :auto)

# auto width
image.resize(:auto, 300)

# scale factor
image.resize(0.5)

# crop
image.crop(200, 200, 100, 100)

# save memory, do not duplicate instance
image.resize!(400, :auto)

# image dimensions
image.width => 400
image.height => 300
image.dimensions => [400, 300]
```


