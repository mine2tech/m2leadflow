import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.handleKeydown = this.handleKeydown.bind(this)
    document.addEventListener("keydown", this.handleKeydown)
  }

  disconnect() {
    document.removeEventListener("keydown", this.handleKeydown)
  }

  handleKeydown(event) {
    // Ignore when typing in form fields
    const tag = event.target.tagName.toLowerCase()
    if (tag === "input" || tag === "textarea" || tag === "select" || event.target.isContentEditable) return
    if (event.metaKey || event.ctrlKey || event.altKey) return

    switch (event.key) {
      case "c":
        window.Turbo.visit("/companies")
        break
      case "d":
        window.Turbo.visit("/drafts")
        break
      case "n":
        window.Turbo.visit("/companies/new")
        break
      case "m":
        window.Turbo.visit("/meetings")
        break
      case "f":
        window.Turbo.visit("/followups")
        break
      case "h":
        window.Turbo.visit("/")
        break
    }
  }
}
