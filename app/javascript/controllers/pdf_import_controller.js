import { Controller } from "stimulus"

export default class extends Controller {
  static targets = ["dropzone"]

  connect() {
    $(this.dropzoneTarget).bind('fileuploaddone',  this.uploaded)
  }

  uploaded(event, data) {
    const result = data.result.files[0]

    if(result.errors.length == 0) {
      Turbolinks.visit(result.location)
    } else {
      $("#modal_title").html('<h4 class="text-center">Could not import file!</h4>')
      $("#modal_body").html(`
        <p>The following errors were encountered:<p>
        <ul class="text-danger">
          ${
            result.errors
              .map(error => `<li>${error}</li>`)
              .reduce((output, element) => output + element)
          }
        </ul>
        <div class="text-center" style="margin-top: 30px;">
          <button type="button" class="btn btn-primary" data-dismiss="modal">OK</button>
        </div>
      `)
      $("#modal").modal("show")
    }
  }
}
