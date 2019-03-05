[![Gem Version](https://badge.fury.io/rb/rszr.svg)](http://badge.fury.io/rb/rszr) [![Build Status](https://travis-ci.org/mtgrosser/rszr.svg)](https://travis-ci.org/mtgrosser/rszr)
# Rszr - fast image resizer for Ruby

Rszr is an image resizer for Ruby based on the Imlib2 library. It is faster and consumes less memory than MiniMagick, rmagick and GD2.

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

#### Linux

Using your favourite package manager:

```bash
yum install imlib2 imlib2-devel
```

```bash
apt-get install libimlib2 libimlib2-dev
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

## Thread safety

As of version 0.4.0, Rszr provides thread safety by synchronizing access to imlib2 function calls.
Use of any previous versions in a threaded environment is discouraged.

## Speed

Resizing an 1500x997 JPEG image to 800x532, 100 times:

Library         | Time
----------------|-----------
MiniMagick      | 12.9 s
GD2             | 7.5 s
Rszr            | 2.8 s
