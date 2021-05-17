import { Controller } from 'stimulus';

export default class extends Controller {
  static jQuery = window.jQuery;

  initialize() {
    this.affix();
    this.scrollspy();
  }

  affix() {
    const positionTop  = this.data.get('positionTop');
    const boundingRect = this.element.getBoundingClientRect();
    const offsetTop    = (window.scrollY + boundingRect.top) - positionTop;

    jQuery(this.element).on('affix.bs.affix', () => {
      const width = this.element.parentElement.getBoundingClientRect().width;

      this.element.style.top   = `${positionTop}px`;
      this.element.style.width = `${width}px`;
    });

    jQuery(this.element).on('affix-top.bs.affix', () => {
      this.element.style.top   = '';
      this.element.style.width = '';
    });

    jQuery(this.element).affix({
      offset: {
        top: offsetTop
      }
    });
  }

  scrollspy() {
    jQuery('body').scrollspy({
      target: `#${this.element.id}`,
      offset: Number(this.data.get('positionTop')),
    });
  }
}
