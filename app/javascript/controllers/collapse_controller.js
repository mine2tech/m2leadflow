import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "icon"]

  toggle(event) {
    // Don't toggle when clicking links or buttons inside
    if (event?.target?.closest("a, button")) return

    const content = this.contentTarget
    const isOpen = content.style.maxHeight && content.style.maxHeight !== "0px"

    if (isOpen) {
      content.style.maxHeight = "0px"
      content.style.opacity = "0"
      if (this.hasIconTarget) this.iconTarget.style.transform = "rotate(0deg)"
    } else {
      content.style.maxHeight = content.scrollHeight + "px"
      content.style.opacity = "1"
      if (this.hasIconTarget) this.iconTarget.style.transform = "rotate(180deg)"
    }
  }
}
