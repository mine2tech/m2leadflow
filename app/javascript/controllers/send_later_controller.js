import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["picker"]

  connect() {
    this.outsideClickHandler = (event) => {
      if (!this.element.contains(event.target)) {
        this.close()
      }
    }
  }

  toggle() {
    const isHidden = this.pickerTarget.classList.toggle("hidden")
    if (!isHidden) {
      document.addEventListener("click", this.outsideClickHandler)
    } else {
      document.removeEventListener("click", this.outsideClickHandler)
    }
  }

  close() {
    this.pickerTarget.classList.add("hidden")
    document.removeEventListener("click", this.outsideClickHandler)
  }

  disconnect() {
    document.removeEventListener("click", this.outsideClickHandler)
  }
}
