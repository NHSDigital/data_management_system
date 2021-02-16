import { Controller } from "stimulus";

export default class extends Controller {
  initialize() {
    this._success = this._success.bind(this)
    this._error   = this._error.bind(this)
  }

  connect() {
    this.load()
  }

  load() {
    const success = this._success
    const error   = this._error

    window.$.ajax({
      url:      this.data.get('url'),
      method:   'GET',
      dataType: 'html',
      success:  success,
      error:    error,
    })
  }

  _success(data, status, xhr) {
    this.element.innerHTML = data
  }

  _error(xhr, status, error) { }
}
