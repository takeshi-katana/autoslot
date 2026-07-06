// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//
// If you have dependencies that try to import CSS, esbuild will generate a separate `app.css` file.
// To load it, simply add a second `<link>` to your `root.html.heex` file.

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import {hooks as colocatedHooks} from "phoenix-colocated/autoslot"
import topbar from "../vendor/topbar"

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: {...colocatedHooks},
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

const initTechBackground = () => {
  const root = document.getElementById("tech-background")
  const canvas = document.getElementById("tech-background-canvas")

  if (!root || !canvas || root.dataset.initialized === "true") {
    return
  }

  root.dataset.initialized = "true"

  const context = canvas.getContext("2d")
  const prefersReducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches

  let width = 0
  let height = 0
  let pixelRatio = 1
  let points = []
  let pointer = {
    x: window.innerWidth * 0.5,
    y: window.innerHeight * 0.5,
    active: false,
  }

  const randomBetween = (min, max) => Math.random() * (max - min) + min

  const createPoint = () => ({
    x: randomBetween(-80, width + 80),
    y: randomBetween(-80, height + 80),
    originX: 0,
    originY: 0,
    vx: randomBetween(-0.12, 0.12),
    vy: randomBetween(-0.08, 0.08),
    radius: randomBetween(1.1, 2.4),
    phase: randomBetween(0, Math.PI * 2),
  })

  const resetPointOrigin = point => {
    point.originX = point.x
    point.originY = point.y
  }

  const resize = () => {
    width = window.innerWidth
    height = window.innerHeight
    pixelRatio = Math.min(window.devicePixelRatio || 1, 2)

    canvas.width = Math.floor(width * pixelRatio)
    canvas.height = Math.floor(height * pixelRatio)
    canvas.style.width = `${width}px`
    canvas.style.height = `${height}px`

    context.setTransform(pixelRatio, 0, 0, pixelRatio, 0, 0)

    const pointCount = Math.min(90, Math.max(44, Math.floor((width * height) / 25000)))

    points = Array.from({length: pointCount}, () => {
      const point = createPoint()
      resetPointOrigin(point)
      return point
    })
  }

  const drawLine = (from, to, opacity, lineWidth = 1) => {
    context.beginPath()
    context.moveTo(from.x, from.y)
    context.lineTo(to.x, to.y)
    context.strokeStyle = `rgba(148, 163, 184, ${opacity})`
    context.lineWidth = lineWidth
    context.stroke()
  }

  const drawTriangle = (a, b, c, opacity) => {
    context.beginPath()
    context.moveTo(a.x, a.y)
    context.lineTo(b.x, b.y)
    context.lineTo(c.x, c.y)
    context.closePath()
    context.fillStyle = `rgba(99, 102, 241, ${opacity})`
    context.fill()
  }

  const animate = time => {
    context.clearRect(0, 0, width, height)

    const gradient = context.createRadialGradient(
      pointer.x,
      pointer.y,
      0,
      pointer.x,
      pointer.y,
      Math.max(width, height) * 0.45
    )

    gradient.addColorStop(0, "rgba(99, 102, 241, 0.10)")
    gradient.addColorStop(0.42, "rgba(99, 102, 241, 0.035)")
    gradient.addColorStop(1, "rgba(99, 102, 241, 0)")

    context.fillStyle = gradient
    context.fillRect(0, 0, width, height)

    for (const point of points) {
      const drift = Math.sin(time * 0.0006 + point.phase) * 9
      const pointerDistance = Math.hypot(point.x - pointer.x, point.y - pointer.y)
      const pointerPower = Math.max(0, 1 - pointerDistance / 260)

      point.x += point.vx + (point.x - pointer.x) * pointerPower * 0.004
      point.y += point.vy + (point.y - pointer.y) * pointerPower * 0.004

      point.x += (point.originX + drift - point.x) * 0.006
      point.y += (point.originY - drift * 0.4 - point.y) * 0.006

      if (point.x < -120 || point.x > width + 120 || point.y < -120 || point.y > height + 120) {
        point.x = randomBetween(-60, width + 60)
        point.y = randomBetween(-60, height + 60)
        resetPointOrigin(point)
      }
    }

    for (let i = 0; i < points.length; i += 1) {
      for (let j = i + 1; j < points.length; j += 1) {
        const first = points[i]
        const second = points[j]
        const distance = Math.hypot(first.x - second.x, first.y - second.y)

        if (distance < 185) {
          const centerX = (first.x + second.x) / 2
          const centerY = (first.y + second.y) / 2
          const pointerDistance = Math.hypot(centerX - pointer.x, centerY - pointer.y)
          const pointerBoost = Math.max(0, 1 - pointerDistance / 340)
          const opacity = (1 - distance / 185) * (0.16 + pointerBoost * 0.34)

          drawLine(first, second, opacity, 1 + pointerBoost * 0.8)
        }
      }
    }

    for (let i = 0; i < points.length - 2; i += 8) {
      const opacity = 0.018 + Math.sin(time * 0.0007 + i) * 0.012

      if (opacity > 0.012) {
        drawTriangle(points[i], points[i + 1], points[i + 2], opacity)
      }
    }

    for (const point of points) {
      const pointerDistance = Math.hypot(point.x - pointer.x, point.y - pointer.y)
      const pointerBoost = Math.max(0, 1 - pointerDistance / 260)
      const pulse = 0.42 + Math.sin(time * 0.0015 + point.phase) * 0.28

      context.beginPath()
      context.arc(point.x, point.y, point.radius + pointerBoost * 1.3, 0, Math.PI * 2)
      context.fillStyle = `rgba(226, 232, 240, ${0.16 + pulse * 0.16 + pointerBoost * 0.35})`
      context.fill()
    }

    if (!prefersReducedMotion) {
      requestAnimationFrame(animate)
    }
  }

  window.addEventListener("pointermove", event => {
    pointer = {
      x: event.clientX,
      y: event.clientY,
      active: true,
    }

    root.style.setProperty("--cursor-x", `${event.clientX}px`)
    root.style.setProperty("--cursor-y", `${event.clientY}px`)
  }, {passive: true})

  window.addEventListener("pointerleave", () => {
    pointer.active = false
    pointer.x = width * 0.5
    pointer.y = height * 0.5
  })

  window.addEventListener("resize", resize)

  resize()
  requestAnimationFrame(animate)
}

initTechBackground()

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// The lines below enable quality of life phoenix_live_reload
// development features:
//
//     1. stream server logs to the browser console
//     2. click on elements to jump to their definitions in your code editor
//
if (process.env.NODE_ENV === "development") {
  window.addEventListener("phx:live_reload:attached", ({detail: reloader}) => {
    // Enable server log streaming to client.
    // Disable with reloader.disableServerLogs()
    reloader.enableServerLogs()

    // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
    //
    //   * click with "c" key pressed to open at caller location
    //   * click with "d" key pressed to open at function component definition location
    let keyDown
    window.addEventListener("keydown", e => keyDown = e.key)
    window.addEventListener("keyup", _e => keyDown = null)
    window.addEventListener("click", e => {
      if(keyDown === "c"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtCaller(e.target)
      } else if(keyDown === "d"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtDef(e.target)
      }
    }, true)

    window.liveReloader = reloader
  })
}
