import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "prompt"]
  static values = { closeUrl: String, autoOpen: Boolean }

  connect() {
    if (this.autoOpenValue) this.open()
  }

  open() {
    this.panelTarget.showModal()
  }

  close() {
    this.panelTarget.close()
    if (this.closeUrlValue) window.location.assign(this.closeUrlValue)
  }

  showPrompt() {
    this.promptTarget.showModal()
  }

  closePrompt() {
    this.promptTarget.close()
  }

  closeOnBackdrop(event) {
    if (event.target === this.panelTarget) this.close()
  }

  closePromptOnBackdrop(event) {
    if (event.target === this.promptTarget) this.closePrompt()
  }
}
