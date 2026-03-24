import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list", "row"]

  add() {
    const row = document.createElement("div")
    row.classList.add("flex", "gap-2")
    row.setAttribute("data-invitees-target", "row")
    row.innerHTML = `
      <input type="email" name="meeting[invitees][]" value="" class="form-input flex-1" placeholder="email@example.com">
      <button type="button" data-action="invitees#remove" class="btn-ghost btn-sm text-rose-500 hover:text-rose-700">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
      </button>
    `
    this.listTarget.appendChild(row)
  }

  remove(event) {
    const row = event.target.closest("[data-invitees-target='row']")
    if (this.rowTargets.length > 1) {
      row.remove()
    } else {
      row.querySelector("input").value = ""
    }
  }
}
