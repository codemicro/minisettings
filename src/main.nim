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

const cmdExitCode {.intdefine.} = 0

when not defined(release):
  proc runCommand(command: string): int =
    debugEcho("[CMD] " & command)
    return cmdExitCode
else:
  proc runCommand(command: string): int =
    let ec = execCmd(command)
    return ec

template runMonitorMoveCommand(location: string) =
  if runCommand("/home/akp/scripts/setMonitors.sh " & location) != 0:
    igOpenPopup("Command failed")

proc setNextWindowCenter() =
  let center = igGetMainViewport().getCenter()
  igSetNextWindowPos(center, ImGuiCond.Appearing, ImVec2(x: 0.5'f32, y: 0.5'f32))

proc okCancelPopup(title, message: string): bool =
  var selected: bool = false

  setNextWindowCenter()

  if igBeginPopupModal(title, nil, ImGuiWindowFlags.AlwaysAutoResize):
    igText(message)
    igSpacing()

    redButton():
      if igButton("OK", ImVec2(x: 150, y: 0)):
        selected = true
        igCloseCurrentPopup()

    igSetItemDefaultFocus()
    igSameLine()

    if igButton("Cancel", ImVec2(x: 150, y: 0)):
      selected = false
      igCloseCurrentPopup()

    igEndPopup()

  return selected

proc messagePopup(title, message: string) =
  setNextWindowCenter()
  if igBeginPopupModal(title, nil, ImGuiWindowFlags.AlwaysAutoResize):
    igText(message)
    igSpacing()
    if igButton("OK", ImVec2(x: 300, y: 0)):
      igCloseCurrentPopup()
    igEndPopup()

template commandFailedPopup(): untyped =
  messagePopup("Command failed", "Command returned with a non-zero exit code.")

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

    if igBeginTabBar("MainTabBar", ImGuiTabBarFlags.None):
      if igBeginTabItem("Power"):
        let button_size = ImVec2(x: (WindowWidth - 35) / 3, y: 30)

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
            w.setWindowShouldClose(true)

        if okCancelPopup("Restart?", "Are you sure you want to restart?"):
          if runCommand("systemctl reboot") != 0:
            igOpenPopup("Command failed")
          else:
            w.setWindowShouldClose(true)

        if okCancelPopup("Sleep?", "Are you sure you want to sleep?"):
          if runCommand("systemctl suspend") != 0:
            igOpenPopup("Command failed")
          else:
            w.setWindowShouldClose(true)

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
