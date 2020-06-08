import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["start", "end"];

  update_duration() {
    var startDateString = this.start;
    var splitStartDate = startDateString.split("/");
    var startMonth = splitStartDate[1] - 1;
    var startDate = new Date(splitStartDate[2], startMonth, splitStartDate[0]);

    var endDateString = this.end;
    var splitEndDate = endDateString.split("/");
    var endMonth = splitEndDate[1] - 1;
    var endDate = new Date(splitEndDate[2], endMonth, splitEndDate[0]);

    const MILLISECONDS_PER_DAY = 1000 * 60 * 60 * 24;

    var timeDiff = Math.ceil(endDate.getTime() - startDate.getTime());
    var diffDays = Math.ceil(timeDiff / MILLISECONDS_PER_DAY);

    var totalMonths = Math.ceil(
      (endDate.getFullYear() - startDate.getFullYear()) * 12 +
        (endDate.getMonth() - startDate.getMonth())
    );

    if (totalMonths > 0) {
      $("#project_duration").html(`<p>${totalMonths + " Months"}</p>`);
    } else {
      if (diffDays > 0) {
        $("#project_duration").html(`<p>${diffDays + " Days"}</p>`);
      } else {
        $("#project_duration").html("<p>Unable to calculate duration</p>");
      }
    }
  }

  connect() {
    this.update_duration();
  }

  get start() {
    return this.startTarget.value;
  }

  get end() {
    return this.endTarget.value;
  }
}
