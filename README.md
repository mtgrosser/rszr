[![Gem Version](https://badge.fury.io/rb/rszr.svg)](http://badge.fury.io/rb/rszr) [![build](https://github.com/mtgrosser/rszr/actions/workflows/build.yml/badge.svg)](https://github.com/mtgrosser/rszr/actions/workflows/build.yml)
# Rszr - fast image resizer for Ruby

Rszr is an image resizer for Ruby based on the Imlib2 library.
It is faster and consumes less memory than MiniMagick, GD2 and VIPS, and comes with an optional drop-in interface for Rails ActiveStorage image processing.

## Installation

In your Gemfile:

```ruby
gem 'rszr'
```

### Imlib2

Rszr requires the `Imlib2` library to do the heavy lifting.

#### OS X

Using homebrew:

```bash
brew install imlib2
```

#### Linux

Using your favourite package manager:

##### RedHat-based

```bash
yum install imlib2 imlib2-devel
```

##### Debian-based

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

# save it as PNG
image.save('resized.png')
```

### Image info
```ruby
image.width => 400
image.height => 300
image.dimensions => [400, 300]
image.format => "jpeg"
```

### Transformations

For each transformation, there is a bang! and non-bang method.
The bang method changes the image in place, while the non-bang method
creates a copy of the image in memory.

```ruby
# auto height
image.resize(400, :auto)

# auto width
image.resize(:auto, 300)

# scale factor
image.resize(0.5)

# crop
image.crop(200, 200, 100, 100)

# rotate three times 90 deg clockwise
image.turn!(3)

# rotate one time 90 deg counterclockwise
image.turn!(-1)

# rotate by arbitrary angle
image.rotate(45)

# flip vertically
image.flip

# flop horizontally
image.flop

# initialize copy
image.dup

# save memory, do not duplicate instance
image.resize!(400, :auto)
```

### Filters

Filters also support bang! and non-bang methods.

```ruby
# sharpen image by pixel radius
image.sharpen!(1)

# blur image by pixel radius
image.blur!(1)

# brighten
image.brighten(0.1)

# darken
image.brighten(-0.1)

# contrast
image.contrast(0.5)

# gamma
image.gamma(1.1)
```

### Image auto orientation

Auto-rotation is supported for JPEG and TIFF files that include the necessary
EXIF metadata.

```ruby
# load and autorotate
image = Rszr::Image.load('image.jpg', autorotate: true)
```

To enable autorotation by default:

```ruby
# auto-rotate by default, for Rails apps put this into an initializer
Rszr.autorotate = true
```

## Rails / ActiveStorage interface

Rszr provides a drop-in interface to the `image_resizing` gem.
It is faster than both `mini_magick` and `vips` and way easier to install than the latter.

```ruby
# Gemfile
gem 'image_resizing'
gem 'rszr'

# config/initializers/rszr.rb
require 'rszr/image_processing'

# config/application.rb
config.active_storage.variant_processor = :rszr
```

When creating image variants, you can use all of Rszr's transformation methods:

```erb
<%= image_tag user.avatar.variant(resize_to_fit: [300, 200]) %>
```

## Loading from and saving to memory

The `Imlib2` library is mainly file-oriented and doesn't provide a way of loading
the undecoded image from a memory buffer. Therefore, the functionality is
implemented on the Ruby side of the gem, writing the memory buffer to a Tempfile.
Currently, this local write cannot be avoided.

```ruby
image = Rszr::Image.load_data(binary_data)

data = image.save_data(format: :jpeg)
```

## Thread safety

As of version 0.5.0, Rszr is thread safe through Ruby's global VM lock.
Use of any previous versions in a threaded environment is discouraged.

## Speed

Resizing a 1500x997 JPEG image to 800x532, 500 times:
![Speed](https://github.com/mtgrosser/rszr/blob/master/benchmark/speed.png)


Library         | Time
----------------|-----------
MiniMagick      | 27.0 s
GD2             | 28.2 s
VIPS            | 13.6 s
Rszr            |  7.9 s
