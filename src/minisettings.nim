import nimgl/imgui, nimgl/imgui/[impl_opengl, impl_glfw]
import nimgl/[opengl, glfw]

func `or`(x: ImGuiWindowFlags, y: ImGuiWindowFlags): ImGuiWindowFlags = (x.int32 or y.int32).ImGuiWindowFlags

func newImColorFromHSV(h, s, v: float32): ImColor =
  var r: float32
  var g: float32 
  var b: float32
  
  igColorConvertHSVtoRGB(h, s, v, r.addr, g.addr, b.addr)

  return ImColor(value: ImVec4(x: r, y: g, z: b, w: 1.0'f32))

func getCenter(vp: ptr ImGuiViewport): ImVec2 = 
  ImVec2(
    x: vp.pos.x + (vp.size.x * 0.5'f32), 
    y: vp.pos.y + (vp.size.y * 0.5'f32)
  )

template redButton(buttonCode: untyped): untyped =
  igPushStyleColor(ImGuiCol.Button, newImColorFromHSV(0'f32, 0.6'f32, 0.6'f32).value)
  igPushStyleColor(ImGuiCol.ButtonHovered, newImColorFromHSV(0'f32, 0.7'f32, 0.7'f32).value)
  igPushStyleColor(ImGuiCol.ButtonActive, newImColorFromHSV(0'f32, 0.8'f32, 0.8'f32).value)

  buttonCode

  igPopStyleColor(3)

proc okCancelPopup(title, message: string): ptr bool =
  var
    o: bool = false
    selected: bool = false

  if igBeginPopupModal("Shutdown?", nil, ImGuiWindowFlags.AlwaysAutoResize):
    igText("Are you sure you want to shutdown?\n\n")
    igSeparator()

    redButton():
      if igButton("OK", ImVec2(x: 150, y: 0)):
        o = true
        selected = true
        igCloseCurrentPopup()

    igSetItemDefaultFocus()
    igSameLine()

    if igButton("Cancel", ImVec2(x: 150, y: 0)):
      o = false
      selected = true
      igCloseCurrentPopup()

    igEndPopup()

  if not selected:
    return nil

  return o.addr

proc main() =
  doAssert glfwInit()

  glfwWindowHint(GLFWContextVersionMajor, 3)
  glfwWindowHint(GLFWContextVersionMinor, 3)
  glfwWindowHint(GLFWOpenglForwardCompat, GLFW_TRUE)
  glfwWindowHint(GLFWOpenglProfile, GLFW_OPENGL_CORE_PROFILE)
  glfwWindowHint(GLFWResizable, GLFW_FALSE)

  var w: GLFWWindow = glfwCreateWindow(400, 300)
  if w == nil:
    quit(-1)

  w.setWindowAttrib(GLFWResizable, GLFWTrue)

  w.makeContextCurrent()

  doAssert glInit()

  let context = igCreateContext()
  #let io = igGetIO()

  doAssert igGlfwInitForOpenGL(w, true)
  doAssert igOpenGL3Init()

  var show_demo: bool = false

  while not w.windowShouldClose:
    glfwPollEvents()

    igOpenGL3NewFrame()
    igGlfwNewFrame()
    igNewFrame()

    let mainViewport = igGetMainViewport()
    igSetNextWindowSize(mainViewport.workSize)
    igSetNextWindowPos(mainViewport.workPos)

    var p_open = false
    igBegin(cstring("fullscreen"), p_open.addr, ImGuiWindowFlags.NoDecoration or ImGuiWindowFlags.NoMove or ImGuiWindowFlags.NoSavedSettings)
    
    igText("Minisettings")

    redButton():
      if igButton("Shutdown"):
        debugEcho("Shutdown button clicked")
        igOpenPopup("Shutdown?")

    let center = igGetMainViewport().getCenter()
    igSetNextWindowPos(center, ImGuiCond.Appearing, ImVec2(x: 0.5'f32, y: 0.5'f32))

    var res = okCancelPopup("Shutdown?", "Are you sure you want to shutdown?")
    if not res.isNil:
      if res[]:
        debugEcho("yes")
      else:
        debugEcho("no")

    igEnd()

    if show_demo:
      igShowDemoWindow(show_demo.addr)

    igRender()

    glClearColor(0.45f, 0.55f, 0.60f, 1.00f)
    glClear(GL_COLOR_BUFFER_BIT)

    igOpenGL3RenderDrawData(igGetDrawData())

    w.swapBuffers()

  igOpenGL3Shutdown()
  igGlfwShutdown()
  context.igDestroyContext()

  w.destroyWindow()
  glfwTerminate()

when isMainModule:
  main()