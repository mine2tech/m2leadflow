import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar", "overlay"]

  connect() {
    this.closeOnNav = () => this.close()
    document.addEventListener("turbo:before-visit", this.closeOnNav)
  }

  disconnect() {
    document.body.classList.remove("overflow-hidden")
    document.removeEventListener("turbo:before-visit", this.closeOnNav)
  }

  toggle() {
    if (this.sidebarTarget.classList.contains("is-open")) {
      this.close()
    } else {
      this.open()
    }
  }

  open() {
    this.sidebarTarget.classList.add("is-open")
    this.overlayTarget.classList.add("is-open")
    document.body.classList.add("overflow-hidden")
  }

  close() {
    this.sidebarTarget.classList.remove("is-open")
    this.overlayTarget.classList.remove("is-open")
    document.body.classList.remove("overflow-hidden")
  }
}
