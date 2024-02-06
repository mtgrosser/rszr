## Rsze 1.5.0 (Feb 6, 2024)

* Image desaturation (grayscale)

## Rszr 1.4.0 (Jan 11, 2024)

* Fix `load_data` (@mantas)

## Rszr 1.3.0 (Aug 25, 2022)

* Alpha channel control
* Background initialization
* Image blending / watermarking
* Rectangle and image fills
* Color gradients
* Hex color codes always prefixed by "#"

## Rszr 1.2.1 (Mar 22, 2022)

* Fix saving without extension (@mantas)

## Rszr 1.2.0 (Mar 11, 2022)

* Saving interlaced PNG and progressive JPEG

## Rszr 1.1.0 (Feb 9, 2022)

* Use pkg_config as imlib2 dropped imlib2-config

## Rszr 1.0.1 (Nov 10, 2021)

* Remove libexif.h header check

## Rszr 1.0.0 (Nov 9, 2021)

* Fix blur method
* Gravity cropping (resize to fill)
* Query pixel
* Add demo generator

## Rszr 0.8.0 (Oct 8, 2021)

* Allow loading of binary image data from buffer
* Drop libexif dependency, use Ruby implementation for image orientation
* Support Ruby 3

## Rszr 0.7.1 (May 10, 2021)

* EXIF autorotation support
* GFX filter support
* Fix error on uppercase file extensions
* image_processing integration


## Rszr 0.5.3 (March 13, 2021)

* Fix rake dependency
* Open-end bundler dev dependency


## Rszr 0.5.0 (March 7, 2019)

*   Full reimplementation in C to avoid Fiddle GC issues in Ruby 2.4+ (issue:3)


## Rszr 0.4.0 (March 5, 2019)

*   Synchronize imlib2 context access for thread safety (issue:2)

