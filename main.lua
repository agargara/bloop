screenshotter = require("Screenshotter.capture")

function love.load()
  -- setup
  love.window.setTitle("the hunter sleeps in golden fields")
  love.mouse.setRelativeMode(true)
  -- global variables
  DEBUG = false
  RECORDING = true
  debug_text = ""
  t = 0
  shaders = init_shaders()
  settings = init_settings()
  current_shader = "floop_shader"
  init_scene()
  get_dimensions()
end

function init_settings()
  local bloop_shader = {
    bounce = false,
    speed = 500, -- 1 is fastest
    scale = 0.1,
    min_scale = 0.01,
    max_scale = 1,
    zoom_level = 0,
    zoom_max = 512,
    autozoom = false,
    mouse_zoom = true,
    scale_movement = 0,
    time_range = 8*math.pi,
    time_scale_type = "log"
  }
  local gloop_shader = {
    bounce = false,
    speed = 300, -- 1 is fastest
    scale = 0.1,
    min_scale = 0.01,
    max_scale = 2,
    zoom_level = -512,
    zoom_max = 512,
    autozoom = true,
    mouse_zoom = false,
    scale_movement = 0,
    time_range = 0.1,
    time_scale_type = "linear"
  }
  local floop_shader = {
    bounce = false,
    speed = 400, -- 1 is fastest
    scale = 0.1,
    min_scale = 0.01,
    max_scale = 4,
    zoom_level = -356,
    zoom_max = 512,
    autozoom = false,
    mouse_zoom = false,
    scale_movement = 0,
    time_range = 2*math.pi,
    time_scale_type = "linear"
  }
  local settings = {
    bloop_shader = bloop_shader,
    mono_shader = bloop_shader,
    gloop_shader = gloop_shader,
    floop_shader = floop_shader
  }
  return settings
end

function init_scene()
  local s = settings[current_shader]
  bounce = s['bounce']
  speed = s['speed']
  scale = s['scale']
  min_scale = s['min_scale']
  max_scale = s['max_scale']
  zoom_level = s['zoom_level']
  zoom_max = s['zoom_max']
  autozoom = s['autozoom']
  mouse_zoom = s['mouse_zoom']
  scale_movement = s['scale_movement']
  time_range = s['time_range']
  time_scale_type = s['time_scale_type']
end

function get_dimensions()
  screen_width, screen_height = love.graphics.getDimensions()
  for key, shader in pairs(shaders) do
    shader:send("screen_width", screen_width)
    shader:send("screen_height", screen_height)
  end
end


function init_shaders()
  local mono_shader = love.graphics.newShader[[
    extern number screen_width;
    extern number screen_height;
    vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ){
      vec4 pixel = Texel(texture, texture_coords ); //This is the current pixel color
      number dummy = screen_height;
      dummy = dummy / screen_height;
      number average = (pixel.r+pixel.b+pixel.g)/3.0 * dummy;
      number factor = screen_coords.x/screen_width;
      pixel.r = pixel.r + (average - pixel.r) * factor;
      pixel.g = pixel.g + (average - pixel.g) * factor;
      pixel.b = pixel.b + (average - pixel.b) * factor;
      return pixel;
    }
  ]]
  local bloop_shader = love.graphics.newShader[[
    extern number time;
    extern number scale;
    extern number screen_width;
    extern number screen_height;
    vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ){
      float x = (screen_coords.x - (screen_width  * 0.5));
      float y = (screen_coords.y - (screen_height * 0.5));
      x = (x) * scale;
      y = (y) * scale;
      float n = sin(x) * sin(y) + time;
      n = sin(sqrt(abs(x * y * n)));
      if (n > 0){
        return vec4(1.0,1.0,1.0,1.0);
      }else{
        return vec4(0.0,0.0,0.0,1.0);
      }
    }
  ]]
  local gloop_shader = love.graphics.newShader[[
    extern number time;
    extern number scale;
    extern number screen_width;
    extern number screen_height;
    vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ){
      float x = (screen_coords.x - (screen_width  * 0.5));
      float y = (screen_coords.y - (screen_height * 0.5));
      x = (x) * scale;
      y = (y) * scale;
      float n = sin(x) * cos(y) + time;
      n = sin(sqrt(sqrt(abs(x * y * n))));
      float r = (sin(y + time) + 1 ) * 0.25 * abs(n);
      float g = r;
      float b = r;
      if (n > 0){
        return vec4(r,g,b,1.0);
      }else{
        return vec4(1-r,1-g,1-b,1.0);
      }
    }
  ]]
  local floop_shader = love.graphics.newShader[[
    extern number time;
    extern number scale;
    extern number screen_width;
    extern number screen_height;
    float linear_map (float n, float min_in, float max_in, float min_out, float max_out){
      float in_range = max_in - min_in;
      float out_range = max_out - min_out;
      float normalized = (n - min_in) / in_range;
      return (normalized*out_range) + min_out;
    }
    vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ){
      // Get x and y relative to center
      float x = screen_coords.x - (screen_width * 0.5);
      float y = screen_coords.y - (screen_height * 0.5);
      float z = time;
      x *= scale;
      y *= scale;
      float r = 1;
      float g = r;
      float b = r;
      float n = cos(x) * sin(y) + cos(y)*sin(z) + cos(z)*sin(x);
      if (int(n) == 0){
        return vec4(r,g,b,1.0);
      }else{
        return vec4(1-r,1-g,1-b,1.0);
      }
    }
  ]]
  local shaders = {
    mono_shader = mono_shader,
    bloop_shader = bloop_shader,
    gloop_shader = gloop_shader,
    floop_shader = floop_shader
  }
  return shaders
end

function love.update()
  t = t + 1
  local adjusted_time = (t%speed) / speed
  if (autozoom) then
    zoom_level = math.max(math.min(zoom_level + 0.5, zoom_max), -zoom_max)
    if zoom_level == zoom_max then
      RECORDING = false
    end
  elseif (t == (speed*2)) then
    RECORDING = false
  end
  scale = log_scale(zoom_level, -zoom_max, zoom_max, min_scale, max_scale)
  screenshotter.update(dt)
  if RECORDING then
    screenshotter.takeShot()
  end
  if(bounce) then
    if (adjusted_time > 0.5) then
      adjusted_time = 1 - adjusted_time
    end
    adjusted_time = adjusted_time * 2
  end
  if time_scale_type == "linear" then
    adjusted_time = linear_scale(adjusted_time, 0, 1, 0, time_range)
  else
    adjusted_time = log_scale(adjusted_time, 0, 1, 0.0001, time_range)
  end
  shaders['bloop_shader']:send("time", adjusted_time)
  shaders['bloop_shader']:send("scale", scale)
  shaders['gloop_shader']:send("time", adjusted_time)
  shaders['gloop_shader']:send("scale", scale)
  shaders['floop_shader']:send("time", adjusted_time)
  shaders['floop_shader']:send("scale", scale)
end

function love.draw()
  love.graphics.setShader(shaders[current_shader])
  love.graphics.rectangle('fill', 0,0,screen_width,screen_height)
  love.graphics.setShader()
  if DEBUG then
    love.graphics.setColor(0, 0, 0, 255)
    love.graphics.rectangle('fill', 6,6,200,22)
    love.graphics.setColor(255, 255, 255, 255)
    local fps = tostring(love.timer.getFPS())
    love.graphics.print(fps..debug_text, 10, 10)
  end
end

-- event handling
function love.keypressed(key, scancode, isrepeat)
  if (key == 'f') then
    love.window.setFullscreen( not love.window.getFullscreen(), "exclusive")
    get_dimensions()
  elseif (key == 'd') then
    DEBUG = not DEBUG
  end
end

function love.mousemoved(x, y, dx, dy)
  if mouse_zoom then
    zoom_level = math.max(math.min(zoom_level + dy, zoom_max), -zoom_max)
    scale = log_scale(zoom_level, -zoom_max, zoom_max, min_scale, max_scale)
  end
end

-- utility

function log_scale(n, min_in, max_in, min_out, max_out)
  local minv = math.log(min_out)
  local maxv = math.log(max_out)
  local scale = (maxv - minv) / (max_in - min_in)
  return math.exp(minv + scale*(n - min_in))
end

function linear_scale(n, min_in, max_in, min_out, max_out)
  local in_range = max_in - min_in
  local out_range = max_out - min_out
  local normalized = (n - min_in) / in_range
  return (normalized*out_range) + min_out
end
