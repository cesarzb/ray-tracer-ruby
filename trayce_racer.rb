# frozen_string_literal: true

require 'ruby2d'
require 'matrix'

WIDTH = 640.0
HEIGHT = 640.0
BG_COLOR = Vector[1.0, 1.0, 1.0, 1.0]
RECURSION_DEPTHT = 3
ORIGIN = Vector[0.0, 0.0, 0.0]
# scene
VIEWPORT_WIDTH = 1.0
VIEWPORT_HEIGHT = 1.0
PROJECTION_PLANE_D = 1.0
$pressed = false
TRANSFORMATION_PACE = 0.5

$size = 16

$spheres = [
  # metal
  {
    center: Vector[-1.0, 0.0, 3.0],
    radius: 0.5,
    color: Vector[130.0 / 255.0, 130.0 / 255.0, 120.0 / 255.0, 1.0],
    reflective: 0.8,
    alpha: 500.0,
    k_s: 1.02,
    k_d: 0.2,
    k_a: 0.1
  },
  # ściana
  {
    center: Vector[1.0, 0.0, 3.0],
    radius: 0.5,
    color: Vector[230.0 / 255.0, 230.0 / 255.0, 150.0 / 255.0, 1.0],
    reflective: 0.001,
    alpha: 100.0,
    k_s: 0.1,
    k_d: 0.5,
    k_a: 0.2
  },
  # plastik
  {
    center: Vector[-1.0, 1.0, 6.0],
    radius: 0.5,
    color: Vector[30.0 / 255.0, 170.0 / 255.0, 0.0 / 255.0, 1.0],
    reflective: 0.005,
    alpha: 100.0,
    k_s: 1.02,
    k_d: 0.8,
    k_a: 0.5
  },
  # drewno
  {
    center: Vector[1.0, 1.0, 6.0],
    radius: 0.5,
    color: Vector[90.0 / 255.0, 60.0 / 255.0, 0.0 / 255.0, 1.0],
    reflective: 0.001,
    alpha: 10.0,
    k_s: 0.1,
    k_d: 0.7,
    k_a: 0.2
  },
  # podłoze
  {
    center: Vector[0.0, -5001.0, 0.0],
    radius: 5000.0,
    color: Vector[255.0 / 255.0, 255.0 / 255.0, 0.0 / 255.0, 1.0],
    reflective: 0.001,
    alpha: 10.0,
    k_s: 0.1,
    k_d: 0.7,
    k_a: 0.2
  }
]

$lights = [
  {
    type: 'ambient',
    intensity: 0.2
  },
  {
    type: 'point',
    intensity: 1.6,
    position: Vector[1, 3, -4]
  }
  # {
  #   type: 'directional',
  #   intensity: 0.2,
  #   direction: Vector[1, 4, 4]
  # }
]

set width: WIDTH, height: HEIGHT

def draw_pixel(x, y, color)
  Pixel.draw(x: (WIDTH / 2.0) + x, y: (HEIGHT / 2.0) - y, size: $size, color: color)
end

def canvas_to_viewport(x, y)
  Vector[x * VIEWPORT_WIDTH / WIDTH, y * VIEWPORT_HEIGHT / HEIGHT, PROJECTION_PLANE_D]
end

def reflect_ray(ray, normal)
  2 * normal * normal.inner_product(ray) - ray
end

def compute_lighting(point, normal, viewing_direction, k_s, k_d, k_a, alpha)
  i = 0.0
  $lights.each do |light|
    if light[:type] == 'ambient'
      i += light[:intensity] * k_a
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
      i += light[:intensity] * k_d * normal_dot_l / (normal.norm * l.norm) if normal_dot_l > 0

      # specular
      if alpha != -1
        r = 2 * normal * normal.inner_product(l) - l
        r_dot_v = r.inner_product(viewing_direction)
        i += light[:intensity] * ((k_s * r_dot_v / (r.norm * viewing_direction.norm))**alpha) if r_dot_v > 0
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
  return BG_COLOR unless closest_sphere

  point = origin + closest_t * d
  normal = point - closest_sphere[:center]
  normal /= normal.norm
  computed_light = compute_lighting(point, normal, -d, closest_sphere[:k_s],
                                    closest_sphere[:k_d], closest_sphere[:k_a], closest_sphere[:alpha])
  local_color = closest_sphere[:color] * computed_light

  reflective = closest_sphere[:reflective]
  return local_color if recursion_depth <= 0 || reflective < 0

  reflection = reflect_ray(-d, normal)
  reflected_color = trace_ray(point, reflection, 0.001, Float::INFINITY, recursion_depth - 1)

  local_color * (1 - reflective) + reflected_color * reflective
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

on :key do |event|
  if event.key == '['
    $size += 1
  elsif event.key == ']' && $size - 1 > 0
    $size -= 1
  elsif event.key == 'w'
    $lights[1][:position] += Vector[0, 0, TRANSFORMATION_PACE]
  elsif event.key == 's'
    $lights[1][:position] -= Vector[0, 0, TRANSFORMATION_PACE]
  elsif event.key == 'a'
    $lights[1][:position] -= Vector[TRANSFORMATION_PACE, 0, 0]
  elsif event.key == 'd'
    $lights[1][:position] += Vector[TRANSFORMATION_PACE, 0, 0]
  elsif event.key == 'z'
    $lights[1][:position] += Vector[0, TRANSFORMATION_PACE, 0]
  elsif event.key == 'x'
    $lights[1][:position] -= Vector[0, TRANSFORMATION_PACE, 0]
  elsif event.key == '-' && $lights[1][:intensity] - 0.1 >= 0
    $lights[1][:intensity] -= 0.1
  elsif event.key == '='
    $lights[1][:intensity] += 0.1
  elsif event.key == 'r'
    $size = 4
    $lights[1][:position] = Vector[1, 3, -4]
    $lights[1][:intensity] = 1.6
  elsif event.key == '0'
    $size = 1
  elsif event.key == '1'
    $size = 2
  elsif event.key == '2'
    $size = 4
  elsif event.key == '3'
    $size = 8
  elsif event.key == '4'
    $size = 16
  elsif event.key == '5'
    $size = 32
  elsif event.key == '6'
    $size = 64
  elsif event.key == '7'
    $size = 128
  elsif event.key == '8'
    $size = 256
  elsif event.key == '9'
    $size = 512
  end
  $stale = true
  $cache = []
end

def render_info_to_console(x, y)
  puts "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n"
  puts "Light position: [#{$lights[1][:position][0]}, #{$lights[1][:position][1]}, #{$lights[1][:position][2]}]"
  puts "Light intensity: #{$lights[1][:intensity]}"
  puts "Pixel size: #{$size}"
  puts "#{((((x + WIDTH * 0.5) * HEIGHT + y + HEIGHT * 0.5) / (WIDTH * HEIGHT)) * 100).round(2)}%"
end
$cache = []
$stale = true
update do
  index = 0
  for x in ((-WIDTH / 2.0).to_i..(WIDTH / 2.0).to_i).step($size) do
    for y in ((-HEIGHT / 2.0).to_i..(HEIGHT / 2.0).to_i).step($size) do
      if $stale
        d = canvas_to_viewport(x, y)
        color = trace_ray(ORIGIN, d, 1.0, Float::INFINITY, RECURSION_DEPTHT)
        # render_info_to_console(x, y)
        $cache << color
        draw_pixel(x, y, color)
      else
        draw_pixel(x, y, $cache[index])
        index += 1
      end
    end
  end
  $stale = false
end

show
