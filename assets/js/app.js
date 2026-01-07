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
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import { hooks as colocatedHooks } from "phoenix-colocated/tesseract_studio"
import topbar from "../vendor/topbar"

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

// Custom hooks for the builder
const NodeCanvas = {
  mounted() {
    this.setupDragAndDrop()
  },

  setupDragAndDrop() {
    const nodesLayer = this.el.querySelector('#nodes-layer')
    if (!nodesLayer) return

    let draggedNode = null
    let offsetX = 0
    let offsetY = 0

    nodesLayer.addEventListener('mousedown', (e) => {
      const node = e.target.closest('.node')
      if (node) {
        draggedNode = node
        const rect = node.getBoundingClientRect()
        offsetX = e.clientX - rect.left
        offsetY = e.clientY - rect.top
        node.style.cursor = 'grabbing'
        node.style.zIndex = '1000'
        e.stopPropagation()
      }
    })

    document.addEventListener('mousemove', (e) => {
      if (draggedNode) {
        const canvas = this.el.getBoundingClientRect()
        const x = e.clientX - canvas.left - offsetX
        const y = e.clientY - canvas.top - offsetY

        draggedNode.style.left = `${Math.max(0, x)}px`
        draggedNode.style.top = `${Math.max(0, y)}px`
      }
    })

    document.addEventListener('mouseup', (e) => {
      if (draggedNode) {
        const nodeId = draggedNode.dataset.nodeId
        const x = parseInt(draggedNode.style.left)
        const y = parseInt(draggedNode.style.top)

        draggedNode.style.cursor = 'grab'
        draggedNode.style.zIndex = ''

        this.pushEvent('update_node_position', { id: nodeId, x: x, y: y })
        draggedNode = null
      }
    })
  }
}

import ReactFlowHook from './hooks/react_flow_hook.js'
import ContentEditorHook from './hooks/content_editor_hook.js'

const Hooks = {
  NodeCanvas,
  ReactFlow: ReactFlowHook,
  ContentEditor: ContentEditorHook,
  ...colocatedHooks
}

const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: Hooks,
})

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" })
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

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
  window.addEventListener("phx:live_reload:attached", ({ detail: reloader }) => {
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
      if (keyDown === "c") {
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtCaller(e.target)
      } else if (keyDown === "d") {
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtDef(e.target)
      }
    }, true)

    window.liveReloader = reloader
  })
}

