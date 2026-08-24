import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["submit", "label", "spinner", "overlay", "idleIcon"]
  static values = {
    busyLabel: { type: String, default: "Working…" }
  }

  start() {
    this.element.setAttribute("aria-busy", "true")

    this.submitTargets.forEach((button) => {
      button.disabled = true
    })

    if (this.hasLabelTarget) {
      this.labelTarget.dataset.originalText ||= this.labelTarget.textContent
      this.labelTarget.textContent = this.busyLabelValue
    }

    this.spinnerTargets.forEach((spinner) => spinner.classList.remove("hidden"))
    this.idleIconTargets.forEach((icon) => icon.classList.add("hidden"))

    if (this.hasOverlayTarget) {
      this.overlayTarget.hidden = false
    }
  }

  stop() {
    this.element.removeAttribute("aria-busy")

    this.submitTargets.forEach((button) => {
      button.disabled = false
    })

    if (this.hasLabelTarget && this.labelTarget.dataset.originalText) {
      this.labelTarget.textContent = this.labelTarget.dataset.originalText
    }

    this.spinnerTargets.forEach((spinner) => spinner.classList.add("hidden"))
    this.idleIconTargets.forEach((icon) => icon.classList.remove("hidden"))

    if (this.hasOverlayTarget) {
      this.overlayTarget.hidden = true
    }
  }
}
