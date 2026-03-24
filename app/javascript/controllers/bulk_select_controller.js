import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "selectAll", "toolbar", "count", "idsField"]

  connect() {
    this.updateToolbar()
  }

  toggle() {
    this.updateToolbar()
  }

  toggleAll() {
    const checked = this.selectAllTarget.checked
    this.checkboxTargets.forEach(cb => cb.checked = checked)
    this.updateToolbar()
  }

  updateToolbar() {
    const checked = this.checkboxTargets.filter(cb => cb.checked)
    const count = checked.length

    if (this.hasToolbarTarget) {
      if (count > 0) {
        this.toolbarTarget.classList.remove("hidden")
        this.countTarget.textContent = count
      } else {
        this.toolbarTarget.classList.add("hidden")
      }
    }

    if (this.hasSelectAllTarget) {
      this.selectAllTarget.checked = count === this.checkboxTargets.length && count > 0
      this.selectAllTarget.indeterminate = count > 0 && count < this.checkboxTargets.length
    }
  }

  submitSelected() {
    const ids = this.checkboxTargets.filter(cb => cb.checked).map(cb => cb.value)
    this.idsFieldTarget.value = ids.join(",")
  }
}
