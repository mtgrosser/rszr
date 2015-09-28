[![Gem Version](https://badge.fury.io/rb/rszr.svg)](http://badge.fury.io/rb/rszr)
# Rszr

Rszr is a fast image resizer.

## Installation

In your Gemfile:

```ruby
gem 'rszr'
```

### Imlib2

Rszr requires the Imlib2 library to do the heavy lifting.

#### OS X

Using homebrew:

```bash
brew install imlib2
```

### Linux

Using your favourite package manager:

```bash
yum install imlib2
```

```bash
apt-get install libimlib2
```

## Usage

```ruby
# bounding box 400x300
image = Rszr::Image.load('image.jpg')
image.resize(400, 300)

# save it
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

## Speed

Resizing an 1500x997 JPEG image to 800x532, 100 times:

Library         | Time
----------------|-----------
MiniMagick      | 11.4 s
GD2             | 7.2 s
Rszr            | 3.2 s
