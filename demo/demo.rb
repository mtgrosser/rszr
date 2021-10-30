require 'rszr'
require 'base64'

def root
  Pathname.new(__FILE__).dirname
end

gravities = [:center, :n, :nw, :w, :sw, :s, :se, :e, :ne]

template = <<~HTML
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Rszr Demo</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bulma@0.9.3/css/bulma.min.css">
  </head>
  <body>
  <section class="section">
    <div class="container">
      <h1 class="title">
        Rszr Demo
      </h1>
      %IMAGES%
    </div>
  </section>
  </body>
</html>
HTML

def data_uri(data)
  "data:image/jpeg;base64,#{Base64.strict_encode64(data)}"
end

def image_tag(args, data)
  formatted_args = args.inspect[1..-2]
  %{<span class="tag is-family-monospace">resize(#{formatted_args})</span><div class="block"><img src="#{data_uri(data)}" /></div>}
end

html = ''

%i[landscape portrait].each do |aspect|
  image = Rszr::Image.load(root.join("#{aspect}.jpg"))
  modes = [[0.25], [200, :auto], [:auto, 150], [200, 150], [150, 200]] 
  modes += gravities.map { |g| [150, 200, { crop: g }] }
  modes += gravities.map { |g| [200, 150, { crop: g }] }
  modes.each do |args|
    html << image_tag(args, image.resize(*args).save_data)
  end
end

root.join('resizing.html').write(template.sub('%IMAGES%', html))
