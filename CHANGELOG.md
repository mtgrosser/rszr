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

