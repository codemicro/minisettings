import nimgl/imgui, nimgl/imgui/[impl_opengl, impl_glfw]
import nimgl/[opengl, glfw]
import std/[os, osproc]

const
  WindowWidth = 400
  WindowHeight = 200

func `or`(x: ImGuiWindowFlags, y: ImGuiWindowFlags): ImGuiWindowFlags = (
  x.int32 or y.int32).ImGuiWindowFlags

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

proc getContentRegionAvail(): ImVec2 =
  var o: ImVec2
  igGetContentRegionAvailNonUDT(o.addr)
  return o

template colouredButton(hue: float32, buttonCode: untyped): untyped =
  igPushStyleColor(ImGuiCol.Button, newImColorFromHSV(hue, 0.6'f32,
      0.6'f32).value)
  igPushStyleColor(ImGuiCol.ButtonHovered, newImColorFromHSV(hue, 0.7'f32,
      0.7'f32).value)
  igPushStyleColor(ImGuiCol.ButtonActive, newImColorFromHSV(hue, 0.8'f32,
      0.8'f32).value)

  buttonCode

  igPopStyleColor(3)

template redButton(buttonCode: untyped): untyped =
  colouredButton(0, buttonCode)

template yellowButton(buttonCode: untyped): untyped =
  colouredButton(0.1, buttonCode)

when not defined(release):
  const cmdExitCode {.intdefine.} = 0
  proc runCommand(command: string): int =
    debugEcho("[CMD] " & command)
    return cmdExitCode
else:
  proc runCommand(command: string): int =
    return execCmd(command)

template runMonitorMoveCommand(location: string) =
  # TODO: Don't hardcode this
  if runCommand("/home/akp/scripts/setMonitors.sh " & location) != 0:
    igOpenPopup("Command failed")
  else:
    igOpenPopup("Done")

proc setNextWindowCenter() =
  let center = igGetMainViewport().getCenter()
  igSetNextWindowPos(center, ImGuiCond.Appearing, ImVec2(x: 0.5'f32, y: 0.5'f32))

proc okCancelPopup(title, message: string): bool =
  var selected: bool = false

  setNextWindowCenter()

  if igBeginPopupModal(title, nil, ImGuiWindowFlags.AlwaysAutoResize):
    igText(message)
    igSpacing()

    let
      padding = 8
      button_size = ImVec2(x: (getContentRegionAvail().x - float32(padding)) / 2)

    redButton():
      if igButton("OK", button_size):
        selected = true
        igCloseCurrentPopup()

    igSetItemDefaultFocus()
    igSameLine()

    if igButton("Cancel", button_size):
      selected = false
      igCloseCurrentPopup()

    igEndPopup()

  return selected

proc messagePopup(title, message: string) =
  setNextWindowCenter()
  if igBeginPopupModal(title, nil, ImGuiWindowFlags.AlwaysAutoResize):
    igText(message)
    igSpacing()
    if igButton("OK", ImVec2(x: getContentRegionAvail().x, y: 0)):
      igCloseCurrentPopup()
    igEndPopup()

template commandFailedPopup(): untyped =
  messagePopup("Command failed", "Command returned with a non-zero exit code.")

template donePopup(): untyped =
  messagePopup("Done", "Success!")

proc close(w: GLFWWindow) =
  w.setWindowShouldClose(true)

proc closeAndPauseAudio(w: GLFWWindow) =
  w.close()
  discard runCommand("playerctl pause")

proc drawUI(w: GLFWWindow) =
  if igBeginTabBar("MainTabBar", ImGuiTabBarFlags.None):
    if igBeginTabItem("Power"):
      let
        padding = 8
        button_size = ImVec2(x: (getContentRegionAvail().x - float32(padding * 2)) / 3, y: 30)

      redButton():
        if igButton("Shutdown", button_size):
          igOpenPopup("Shutdown?")

      yellowButton:
        igSameLine()
        if igButton("Sleep", buttonSize):
          igOpenPopup("Sleep?")

        igSameLine()
        if igButton("Restart", button_size):
          igOpenPopup("Restart?")

      if okCancelPopup("Shutdown?", "Are you sure you want to shutdown?"):
        if runCommand("systemctl poweroff") != 0:
          igOpenPopup("Command failed")
        else:
          w.closeAndPauseAudio()

      if okCancelPopup("Restart?", "Are you sure you want to restart?"):
        if runCommand("systemctl reboot") != 0:
          igOpenPopup("Command failed")
        else:
          w.close()

      if okCancelPopup("Sleep?", "Are you sure you want to sleep?"):
        if runCommand("systemctl suspend") != 0:
          igOpenPopup("Command failed")
        else:
          w.closeAndPauseAudio()

      commandFailedPopup()

      igEndTabItem()

    if igBeginTabItem("Displays"):

      igText("Set second monitor position")

      var initial_pos: ImVec2
      igGetCursorPosNonUDT(initial_pos.addr)

      let
        button_size = ImVec2(x: 50, y: 25)
        padding = 5'f32

      igSetCursorPos(ImVec2(x: initial_pos.x, y: initial_pos.y + padding +
          button_size.y))
      if igButton("Left", buttonSize):
        runMonitorMoveCommand("left")

      igSetCursorPos(ImVec2(x: initial_pos.x + padding + button_size.x,
          y: initial_pos.y))
      if igButton("Above", buttonSize):
        runMonitorMoveCommand("above")

      igSetCursorPos(ImVec2(x: initial_pos.x + padding + button_size.x,
          y: initial_pos.y + padding + button_size.y))
      yellowButton():
        if igButton("Single", buttonSize):
          runMonitorMoveCommand("single")

      igSetCursorPos(ImVec2(x: initial_pos.x + padding + button_size.x,
          y: initial_pos.y + (2 * (padding + button_size.y))))
      if igButton("Below", buttonSize):
        runMonitorMoveCommand("below")

      igSetCursorPos(ImVec2(x: initial_pos.x + (2 * (padding +
          button_size.x)), y: initial_pos.y + padding + button_size.y))
      if igButton("Right", buttonSize):
        runMonitorMoveCommand("right")

      igSetCursorPos(ImVec2(x: initial_pos.x, y: initial_pos.y + (3 * (
          padding + button_size.y))))

      commandFailedPopup()
      donePopup()

      igEndTabItem()

    igEndTabBar()

  var window_size, window_pos: ImVec2
  igGetWindowSizeNonUDT(window_size.addr)
  igGetWindowPosNonUDT(window_pos.addr)

  let button_size = ImVec2(x: getContentRegionAvail().x, y: 20)

  igSetCursorPosY(window_pos.y + (window_size.y - button_size.y - 10))
  if igButton("Close", button_size):
    w.close()

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
    igBegin(cstring("fullscreen"), p_open.addr, ImGuiWindowFlags.NoDecoration or
        ImGuiWindowFlags.NoMove or ImGuiWindowFlags.NoSavedSettings)

    drawUI(w)

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
