import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { delay: { type: Number, default: 4000 } }

  connect() {
    this.timeout = setTimeout(() => this.dismiss(), this.delayValue)
  }

  disconnect() {
    if (this.timeout) clearTimeout(this.timeout)
  }

  dismiss() {
    this.element.classList.remove("animate-slide-in-right")
    this.element.classList.add("animate-fade-out")
    this.element.addEventListener("animationend", () => {
      this.element.remove()
    }, { once: true })
  }
}
