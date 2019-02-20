import flash from '~/flash';
import { __ } from '~/locale';

export default {
  methods: {
    requestExpandedPipelines(pipeline) {
      this.mediator.store.toggleLoading(pipeline);
      this.mediator.poll.stop();
    },
    getExpandedPipelines(pipeline) {
      this.mediator.service
        .getPipeline(this.mediator.getExpandedParameters())
        .then(response => {
          this.mediator.store.toggleLoading(pipeline);
          this.mediator.store.storePipeline(response.data);
          this.mediator.poll.restart({ data: this.mediator.getExpandedParameters() });
        })
        .catch(() => {
          flash(__('An error occurred while fetching the pipeline.'));
        });
    },
    /**
     * Called when a linked pipeline is clicked.
     *
     * If the pipeline is collapsed we will start polling it & we will reset the other pipelines.
     * If the pipeline is expanded we will close it.
     *
     * @param {String} method Method to fetch the pipeline
     * @param {String} storeKey Store property that will be updates
     * @param {String} resetStoreKey Store key for the visible pipeline that will need to be reset
     * @param {Object} pipeline The clicked pipeline
     */
    clickPipeline(parentPipeline, pipeline, openMethod, closeMethod) {
      if (!pipeline.isExpanded) {
        this.mediator.store[openMethod](parentPipeline, pipeline);

        this.requestExpandedPipelines(pipeline);

        // update the request data with the clicked pipeline
        this.mediator.store.addExpandedPipelineToRequestData(pipeline.id);

        this.getExpandedPipelines(pipeline);
      } else {
        this.mediator.store[closeMethod](pipeline);

        this.requestExpandedPipelines(pipeline);

        // remove the expanded pipeline
        this.mediator.store.removeExpandedPipelineToRequestData(pipeline.id);

        this.getExpandedPipelines(pipeline);
      }
    },
    clickTriggeredByPipeline(parentPipeline, pipeline) {
      this.clickPipeline(
        parentPipeline,
        pipeline,
        'openTriggeredByPipeline',
        'closeTriggeredByPipeline',
      );
    },
    clickTriggeredPipeline(parentPipeline, pipeline) {
      this.clickPipeline(
        parentPipeline,
        pipeline,
        'openTriggeredPipeline',
        'closeTriggeredPipeline',
      );
    },
    requestRefreshPipelineGraph() {
      // When an action is clicked
      // (wether in the dropdown or in the main nodes, we refresh the big graph)
      this.mediator
        .refreshPipeline()
        .catch(() => flash(__('An error occurred while making the request.')));
    },
  },
};
