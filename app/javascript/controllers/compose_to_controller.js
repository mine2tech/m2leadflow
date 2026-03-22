import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["select", "newFields"]

  toggleNew() {
    if (this.selectTarget.value === "new") {
      this.newFieldsTarget.classList.remove("hidden")
      this.selectTarget.name = ""
    } else {
      this.newFieldsTarget.classList.add("hidden")
      this.selectTarget.name = "draft[contact_id]"
    }
  }
}
