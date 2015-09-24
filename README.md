# Rszr

Rszr is a fast image resizer.

## Installation

In your Gemfile:

```ruby
gem 'rszr'
```

## Usage

```ruby
Rszr::Image.load('image.jpg').resize(width: 300, height: 400).save('resized.jpg')
```


