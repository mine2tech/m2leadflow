import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["typeSelect", "payload"]

  static templates = {
    enrich_company: JSON.stringify({ company_id: 1, domain: "example.com" }, null, 2),
    draft_email: JSON.stringify({
      contact_id: 1,
      company_context: { name: "Acme", domain: "acme.com" },
      contact: { name: "John", role: "CISO" },
      is_followup: false,
      sequence_number: 1
    }, null, 2),
    company_research: JSON.stringify({
      criteria: {
        industry: "fintech",
        trend: "recently_breached",
        count: 10,
        employee_count_min: 500,
        employee_count_max: 5000
      }
    }, null, 2)
  }

  updateTemplate() {
    const type = this.typeSelectTarget.value
    const template = this.constructor.templates[type]
    if (template && (this.payloadTarget.value === "{}" || this.payloadTarget.value === "")) {
      this.payloadTarget.value = template
    }
  }
}
