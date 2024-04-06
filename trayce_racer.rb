# frozen_string_literal: true

require 'ruby2d'
require 'matrix'
require 'pry'
require 'pry-nav'

$width = 640.0
$height = 640.0
$background_color = [1.0, 1.0, 1.0, 1.0]
$recursion_depth = 3
$origin = Vector[0.0, 0.0, 0.0]
$recursion_depth = 3
# scene
$viewport_width = 1.0
$viewport_height = 1.0
$projection_plane_d = 1.0
$spheres = [
  # drewno
  {
    center: Vector[-2.0, 0.0, 3.0],
    radius: 1.0,
    color: [90.0 / 255.0, 60.0 / 255.0, 0.0, 1.0],
    specular: 500.0,
    reflective: 0.2
  },
  {
    center: Vector[2.0, 0.0, 3.0],
    radius: 1.0,
    color: [90.0 / 255.0, 60.0 / 255.0, 0.0, 1.0],
    specular: 500.0,
    reflective: 0.2
  },
  {
    center: Vector[-2.0, 0.0, 6.0],
    radius: 1.0,
    color: [90.0 / 255.0, 60.0 / 255.0, 0.0, 1.0],
    specular: 500.0,
    reflective: 0.2
  },
  {
    center: Vector[2.0, 0.0, 6.0],
    radius: 1.0,
    color: [90.0 / 255.0, 60.0 / 255.0, 0.0, 1.0],
    specular: 500.0,
    reflective: 0.2
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

def reflect_ray(ray, normal)
  2 * normal * normal.inner_product(ray) - ray
end

def compute_lighting(point, normal, viewing_direction, specularity)
  i = 0.0
  $lights.each do |light|
    if light[:type] == 'ambient'
      i += light[:intensity]
    else
      if light[:type] == 'point'
        l = light[:position] - point
        t_max = 1
      else
        l = light[:direction]
        t_max = Float::INFINITY
      end

      # shadow check
      shadow_sphere, shadow_t = closest_intersection(point, l, 0.001, t_max)
      next if shadow_sphere

      # diffuse
      normal_dot_l = normal.inner_product(l)
      i += light[:intensity] * normal_dot_l / (normal.norm * l.norm) if normal_dot_l > 0

      # specular
      if specularity != -1
        r = 2 * normal * normal.inner_product(l) - l
        r_dot_v = r.inner_product(viewing_direction)
        i += light[:intensity] * ((r_dot_v / (r.norm * viewing_direction.norm))**specularity) if r_dot_v > 0
      end
    end
  end
  i
end

def closest_intersection(origin, d, t_min, t_max)
  closest_t = Float::INFINITY
  closest_sphere = nil
  $spheres.each do |sphere|
    t1, t2 = intersect_ray_sphere(origin, d, sphere)
    if t1 >= t_min && t1 <= t_max && t1 < closest_t
      closest_t = t1
      closest_sphere = sphere
    end
    if t2 >= t_min && t2 <= t_max && t2 < closest_t
      closest_t = t2
      closest_sphere = sphere
    end
  end
  [closest_sphere, closest_t]
end

def trace_ray(origin, d, t_min, t_max, recursion_depth)
  closest_sphere, closest_t = closest_intersection(origin, d, t_min, t_max)
  return $background_color unless closest_sphere

  point = origin + closest_t * d
  normal = point - closest_sphere[:center]
  normal /= normal.norm
  computed_light = compute_lighting(point, normal, -d, closest_sphere[:specular])
  local_color = closest_sphere[:color].map { |el| el * computed_light }

  reflective = closest_sphere[:reflective]
  return local_color if recursion_depth <= 0 || reflective < 0

  reflection = reflect_ray(-d, normal)
  reflected_color = trace_ray(point, reflection, 0.001, Float::INFINITY, recursion_depth - 1)

  (Vector.elements(local_color.map { |el| el * (1 - reflective) }) + Vector.elements(reflected_color.map do |el|
                                                                                       el * reflective
                                                                                     end)).to_a
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
      # if x % 10 == 0
      #   # linie układu współrzędnych
      #   draw_pixel(x, 0, [0.0, 1.0, 0.0, 1.0])
      #   draw_pixel(0, x, [0.0, 1.0, 0.0, 1.0])
      # end

      for y in (-$height / 2.0).to_i..($height / 2.0).to_i do
        d = canvas_to_viewport(x, y)
        color = trace_ray($origin, d, 1.0, Float::INFINITY, $recursion_depth)
        puts "#{((((x + $width * 0.5) * $height + y + $height * 0.5) / ($width * $height)) * 100).round(2)}%"
        draw_pixel(x, y, color)
      end

    end
    puts 'Robota odwalona wariacie'
  end
end

show
