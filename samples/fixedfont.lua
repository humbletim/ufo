local ffi  = require( "ffi" )
local gl   = require( "ffi/OpenGL" ) 
local glfw = require( "ffi/glfw" )

local font = require( "lib/fonts/pearl8x8" )
local font = ffi.new( "uint8_t[?]", #font, font )

local rshift, band = bit.rshift, bit.band

local width, height = 640, 480
local vbo_capacity = 1024*1024
local vbo_index = 0
local vbo = ffi.new( "float[?]", vbo_capacity )

local function draw_char(x,y,c)
   local font, vbo, index = font, vbo, vbo_index
   assert( index + 8 * 8 * 2 < vbo_capacity )
   c = c * 8
   for i=0,7 do
      local b = font[c + i]
      for j=0,7 do
	 if band(rshift(b, 7-j), 1) == 1 then
	    vbo[ index + 0 ] = x + j + 4
	    vbo[ index + 1 ] = y + i + 4
	    index = index + 2
	 end
      end
   end
   vbo_index = index
end

local function draw_string(x,y,s)
   local height = height
   for i=1,#s do
      local c = s:byte(i)
      if c == 10 or c == 13 then
	 y = y + 10 
	 if y > height then
	    break
	 end
	 x = 0
      else
	 draw_char(x,y,c)
	 x = x + 8
      end
   end
end

local text = debug.getinfo(1, "S").source
if text:byte(1)==64 then
   text = io.input(text:sub(2)):read("*all")   
end

local function main()
   assert( glfw.glfwInit() )

   local desktop_mode = ffi.new( "GLFWvidmode[1]" )
   glfw.glfwGetDesktopMode( desktop_mode )

   local desktop_width, desktop_height = desktop_mode[0].width, desktop_mode[0].height
   local window_x = ( desktop_width - width ) / 2
   local window_y = ( desktop_height - height ) / 2

   glfw.glfwOpenWindowHint(glfw.GLFW_WINDOW_NO_RESIZE, 1)
   local window = glfw.glfwOpenWindow( width, height, glfw.GLFW_WINDOWED, "fixedfont", nil )
   assert( window )

   glfw.glfwSetWindowPos( window, window_x, window_y )
   glfw.glfwSwapInterval( 0 );

   gl.glMatrixMode(gl.GL_PROJECTION);
   gl.glLoadIdentity();
   gl.glOrtho(0, width, height, 0, 0, 1)
   
   gl.glMatrixMode( gl.GL_MODELVIEW );
   gl.glLoadIdentity();
   
   local curr_time = glfw.glfwGetTime()
   local prev_time = glfw.glfwGetTime()
   while glfw.glfwIsWindow(window) 
   and   glfw.glfwGetKey(window, glfw.GLFW_KEY_ESCAPE) ~= glfw.GLFW_PRESS 
   do
      prev_time, curr_time = curr_time, glfw.glfwGetTime()
      
      gl.glClear(gl.GL_COLOR_BUFFER_BIT);

      draw_string( 0, 0, tostring( curr_time - prev_time ) .. " fps, vbo_index = " .. tostring(prev_vbo_index) )
      draw_string( 0, 10, text )

      gl.glEnableClientState(gl.GL_VERTEX_ARRAY);
      gl.glVertexPointer(2, gl.GL_FLOAT, 0, vbo);
      gl.glDrawArrays(gl.GL_POINTS, 0, vbo_index);
      gl.glDisableClientState(gl.GL_VERTEX_ARRAY);
      prev_vbo_index, vbo_index = vbo_index, 0 
      
      glfw.glfwSwapBuffers();
      glfw.glfwPollEvents();
   end
   glfw.glfwTerminate();
end

main()