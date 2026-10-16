import { Controller } from '@hotwired/stimulus'

export default class extends Controller<HTMLElement> {
  static values = { openedAt: String }
  declare openedAtValue: string

  connect() {
    this.element.dataset.lastOpened = this.openedAtValue
  }
}
