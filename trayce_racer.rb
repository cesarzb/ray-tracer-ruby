# frozen_string_literal: true

require 'ruby2d'
require 'matrix'
require 'pry'
require 'pry-nav'

$width = 640.0
$height = 640.0
$background_color = [0.0, 0.0, 0.0, 1.0]

$origin = Vector[0.0, 0.0, 0.0]

# scene
$viewport_width = 1.0
$viewport_height = 1.0
$projection_plane_d = 0.1
$spheres = [
  {
    center: Vector[0.0, -1.0, 3.0],
    radius: 1.0,
    color: [1.0, 0.0, 0.0, 1.0]
  },
  {
    center: Vector[2.0, 0.0, 4.0],
    radius: 1.0,
    color: [0.0, 0.0, 1.0, 1.0]
  },
  {
    center: Vector[-2.0, 0.0, 4.0],
    radius: 1.0,
    color: [0.0, 1.0, 0.0, 1.0]
  },
  {
    center: Vector[0, -5001, 0],
    radius: 5000.0,
    color: [1.0, 1.0, 0.0, 1.0]
  }
]

$lights = [
  {
    type: 'ambient',
    intensity: 0.2
  },
  {
    type: 'point',
    intensity: 0.6,
    position: Vector[2, 1, 0]
  },
  {
    type: 'directional',
    intensity: 0.2,
    direction: Vector[1, 4, 4]
  }
]

set width: $width, height: $height

def draw_pixel(x, y, color)
  Pixel.draw(x: ($width / 2.0) + x, y: ($height / 2.0) - y, size: 1, color: color)
end

def canvas_to_viewport(x, y)
  Vector[x * $viewport_width / $width, y * $viewport_height / $height, $projection_plane_d]
end

def compute_lighting(point, normal)
  i = 0.0
  $lights.each do |light|
    if light[:type] == 'ambient'
      i += light[:intensity]
    else
      l = if light[:type] == 'point'
            light[:position] - point
          else
            light[:direction]
          end
      normal_dot_l = normal.inner_product(l)
      i += light[:intensity] * normal_dot_l / (normal.norm * l.norm) if normal_dot_l > 0
    end
  end
  i
end

def trace_ray(origin, d, t_min, t_max)
  closest_t = Float::INFINITY
  closest_sphere = nil
  $spheres.each do |sphere|
    ts = intersect_ray_sphere(origin, d, sphere)
    if ts[0] >= t_min && ts[0] <= t_max && ts[0] < closest_t
      closest_t = ts[0]
      closest_sphere = sphere
    end
    if ts[1] >= t_min && ts[1] <= t_max && ts[1] < closest_t
      closest_t = ts[1]
      closest_sphere = sphere
    end
  end
  # return $background_color unless closest_sphere
  # binding.pry
  return [1.0, 1.0, 1.0, 1.0] unless closest_sphere

  # puts "#{closest_sphere}"
  point = origin + closest_t * d
  normal = point - closest_sphere[:center]
  normal /= normal.norm
  computed_light = compute_lighting(point, normal)
  closest_sphere[:color].map { |el| el * computed_light }
end

def intersect_ray_sphere(origin, d, sphere)
  r = sphere[:radius]
  c_origin = origin - sphere[:center]

  a = d.inner_product(d)
  b = 2 * c_origin.inner_product(d)
  c = c_origin.inner_product(c_origin) - r * r

  discriminant = b * b - 4.0 * a * c
  return [Float::INFINITY, Float::INFINITY] if discriminant < 0

  t1 = (-b + Math.sqrt(discriminant)) / (2.0 * a)
  t2 = (-b - Math.sqrt(discriminant)) / (2.0 * a)
  [t1, t2]
end

$go = true
render do
  if $go
    for x in (-$width / 2.0).to_i..($width / 2.0).to_i do
      # podziałka co 10 pikseli
      if x % 10 == 0
        # linie układu współrzędnych
        draw_pixel(x, 0, [0.0, 1.0, 0.0, 1.0])
        draw_pixel(0, x, [0.0, 1.0, 0.0, 1.0])
        # linie namierzające punkt
        # draw_pixel(x, 50, [1.0, 0.0, 0.0, 1.0])
        # draw_pixel(270, x, [1.0, 0.0, 0.0, 1.0])
      end

      for y in (-$height / 2.0).to_i..($height / 2.0).to_i do
        d = canvas_to_viewport(x, y)
        # binding.pry
        color = trace_ray($origin, d, 1.0, Float::INFINITY)

        puts "#{((((x + $width * 0.5) * $height + y + $height * 0.5) / ($width * $height)) * 100).round(2)}%"
        draw_pixel(x, y, color)
      end

    end
    puts 'Robota odwalona wariacie'
  end
end

show
