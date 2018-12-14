import { withKnobs } from '@storybook/addon-knobs/vue';
import documentedStoriesOf from '../utils/documented_stories';
import readme from '../../components/base/form/form_input.md';
import { GlFormInput } from '../../index';

const components = {
  GlFormInput,
};

documentedStoriesOf('base|form-input', readme)
  .addDecorator(withKnobs)
  .add('default', () => ({
    components,
    template: `
      <gl-form-input type="text" />
    `,
  }));
