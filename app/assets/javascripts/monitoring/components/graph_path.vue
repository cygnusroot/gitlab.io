<script>
  export default {
    props: {
      generatedLinePath: {
        type: String,
        required: true,
      },
      generatedAreaPath: {
        type: String,
        required: true,
      },
      lineColor: {
        type: String,
        required: true,
      },
      areaColor: {
        type: String,
        required: true,
      },
    },
  };
</script>
<template>
  <g>
    <path
      class="metric-area"
      :d="generatedAreaPath"
      :fill="areaColor"
      transform="translate(-5, 20)">
    </path>
    <path
      class="metric-line"
      :d="generatedLinePath"
      :stroke="lineColor"
      fill="none"
      stroke-width="1"
      transform="translate(-5, 20)">
    </path>
  </g>
</template>
