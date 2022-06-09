import os
import nimgl/imgui, nimgl/imgui/[impl_opengl, impl_glfw]
import nimgl/[opengl, glfw]
import std/osproc

const
  WindowWidth = 400
  WindowHeight = 300

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

template colouredButton(hue: float32, buttonCode: untyped): untyped =
  igPushStyleColor(ImGuiCol.Button, newImColorFromHSV(hue, 0.6'f32, 0.6'f32).value)
  igPushStyleColor(ImGuiCol.ButtonHovered, newImColorFromHSV(hue, 0.7'f32, 0.7'f32).value)
  igPushStyleColor(ImGuiCol.ButtonActive, newImColorFromHSV(hue, 0.8'f32, 0.8'f32).value)

  buttonCode

  igPopStyleColor(3)

template redButton(buttonCode: untyped): untyped =
  colouredButton(0, buttonCode)

template yellowButton(buttonCode: untyped): untyped =
  colouredButton(0.1, buttonCode)
 
proc setNextWindowCenter() =
  let center = igGetMainViewport().getCenter()
  igSetNextWindowPos(center, ImGuiCond.Appearing, ImVec2(x: 0.5'f32, y: 0.5'f32))

proc okCancelPopup(title, message: string): ptr bool =
  var
    o: bool = false
    selected: bool = false

  setNextWindowCenter()

  if igBeginPopupModal(title, nil, ImGuiWindowFlags.AlwaysAutoResize):
    igText(message)
    igSpacing()

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

proc messagePopup(title, message: string) =
  setNextWindowCenter()
  if igBeginPopupModal(title, nil, ImGuiWindowFlags.AlwaysAutoResize):
    igText(message)
    igSpacing()
    if igButton("OK", ImVec2(x: 300, y: 0)):
      igCloseCurrentPopup()
    igEndPopup()

proc main() =
  doAssert glfwInit()

  glfwWindowHint(GLFWContextVersionMajor, 3)
  glfwWindowHint(GLFWContextVersionMinor, 3)
  glfwWindowHint(GLFWOpenglForwardCompat, GLFW_TRUE)
  glfwWindowHint(GLFWOpenglProfile, GLFW_OPENGL_CORE_PROFILE)
  glfwWindowHint(GLFWResizable, GLFW_FALSE)

  var w: GLFWWindow = glfwCreateWindow(WindowWidth, WindowHeight, cstring("Minisettings"))
  if w == nil:
    quit(-1)

  w.makeContextCurrent()

  doAssert glInit()

  let context = igCreateContext()
  #let io = igGetIO()

  doAssert igGlfwInitForOpenGL(w, true)
  doAssert igOpenGL3Init()

  var show_demo: bool
  if paramCount() >= 1:
    if paramStr(1) == "demo":
      show_demo = true
      w.setWindowAttrib(GLFWResizable, GLFWTrue)

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

    if igBeginTabBar("MainTabBar", ImGuiTabBarFlags.None):
      if igBeginTabItem("Power"):
        redButton():
          if igButton("Shutdown", ImVec2(x: 100, y: 30)):
            debugEcho("Shutdown button clicked")
            igOpenPopup("Shutdown?")

        let res = okCancelPopup("Shutdown?", "Are you sure you want to shutdown?")
        if not res.isNil:
          if res[]:
            debugEcho("yes")
          else:
            debugEcho("no")
        igEndTabItem()

      if igBeginTabItem("Displays"):

        igText("Set second monitor position")

        var initial_pos: ImVec2
        igGetCursorPosNonUDT(initial_pos.addr)

        let
          button_size = ImVec2(x: 50, y: 25)
          padding = 5'f32

        igSetCursorPos(ImVec2(x: initial_pos.x, y: initial_pos.y + padding + button_size.y))
        igButton("Left", buttonSize)

        igSetCursorPos(ImVec2(x: initial_pos.x + padding + button_size.x, y: initial_pos.y))
        igButton("Above", buttonSize)

        igSetCursorPos(ImVec2(x: initial_pos.x + padding + button_size.x, y: initial_pos.y + padding + button_size.y))
        yellowButton():
          igButton("Single", buttonSize)

        igSetCursorPos(ImVec2(x: initial_pos.x + padding + button_size.x, y: initial_pos.y + (2 * (padding + button_size.y))))
        igButton("Below", buttonSize)

        igSetCursorPos(ImVec2(x: initial_pos.x + (2 * (padding + button_size.x)), y: initial_pos.y + padding + button_size.y))
        igButton("Right", buttonSize)

        igSetCursorPos(ImVec2(x: initial_pos.x, y: initial_pos.y + (3 * (padding + button_size.y))))

        if igButton("Set Monitor Single"):
          if execCmd("/home/akp/scripts/setMonitors.sh single") != 0:
            igOpenPopup("Command failed")

        if igButton("Set Monitor Left"):
          if execCmd("/home/akp/scripts/setMonitors.sh left") != 0:
            igOpenPopup("Command failed")

        messagePopup("Command failed", "Command returned with a non-zero exit code.")

        igEndTabItem()

      igEndTabBar()

    let button_size = ImVec2(x: WindowWidth - 16, y: 20)
    igSetCursorPosY(WindowHeight - button_size.y - 10)
    if igButton("Close", button_size):
      w.setWindowShouldClose(true)

    igEnd() # fullscreen window

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