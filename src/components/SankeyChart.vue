<!-- Your HTML goes here -->
<template>
  <div>
    <h1 class="underline">{{ title }}</h1>
    <svg class="`sankey-chart-svg-${chartId}`" :viewBox="sankeyViewBox">
      <g :transform="`translate(${margin.left}, ${margin.top})`">
        <g class="sankeyPlotyayeet">
          <g class="plot2">
          </g>
        </g>
      </g>
    </svg>
  </div>
</template>

<script>
import * as d3 from 'd3'

import * as d3Sankey from "d3-sankey"

export default {
  name: 'SankeyChart', // Feel free to rename this and the file
  props: {
    // Feel free to add props to communicate between components
    title: {
      required: true
    },
    data: {
      required: true,
    },
    selected_countries: {},
    width: {
      required: true,
      type: Number,
    },
    height: {
      required: true,
      type: Number,
    },
    chartId: {
      required: true,
      type: String,
    },
  },
  data() {
    return {
      selectedData: null,
      sankeyData: null,
      list_of_countries: null,
      margin: {
        left: 80,
        top: 20,
        right: 100,
        bottom: -600,
      },
    }
  },
  watch: {
    selected_countries: function () {
      d3.select(".plot2").remove();
      d3.select(".sankeyPlotyayeet").append("g").attr("class", "plot2")
      this.update();
    }
  },

  mounted() {
    this.init()
  },
  computed: {
    sankeyViewBox() {
      return `0 0 ${this.width + this.margin.left + this.margin.right} ${this.height + this.margin.top + this.margin.bottom}`
    },
    sankeyNodesAndLinksSelectedCountries() {


      let countries = []
      let species = []
      let qualityPercentiles = []
      let processedData = {"nodes": [], "links": []}


      /// setting up list of countries, species, and quality Percentiles to contruct nodes and links
      let beans = []
      this.data.forEach((d => {
        if (this.selected_countries.includes(d.Country_of_Origin)) {


          let newBean = {
            Country_of_Origin: d.Country_of_Origin,
            Species: d.Species,
            percentile: d.percentile
          }
          beans.push(newBean)

          if (species.includes(newBean.Species) === false) {
            species.push(newBean.Species)
          }
          if (countries.includes(newBean.Country_of_Origin) === false) {
            countries.push(newBean.Country_of_Origin)
          }

          if (qualityPercentiles.includes(newBean.percentile) === false) {
            qualityPercentiles.push(newBean.percentile)
          }
        }
      }))
      /// construct links from lists of nodes

      var i;
      var j;
      var sourceValue;
      var targetValue;
      var linkValue;

      for (i = 0; i < species.length; i++) {
        sourceValue = species[i]
        for (j = 0; j < countries.length; j++) {
          targetValue = countries[j]
          linkValue = d3.filter(beans, d => d.Species == sourceValue
              && d.Country_of_Origin == targetValue).length
          processedData.links.push({
            "source": i,
            "target": j + species.length,
            "value": linkValue
          })
        }
      }

      for (i = 0; i < countries.length; i++) {
        sourceValue = countries[i];
        for (j = 0; j < qualityPercentiles.length; j++) {
          targetValue = qualityPercentiles[j]
          linkValue = d3.filter(beans, d => d.Country_of_Origin == sourceValue
              && d.percentile == targetValue).length
          processedData.links.push({
            "source": i + species.length,
            "target": j + species.length + countries.length,
            "value": linkValue
          })
        }
      }


      /// add placeholder speies nodes into processedData nodes
      species.forEach((d => {
        processedData.nodes.push({
          "name": d,
          "category": "Species"
        })
      }));
      /// add placeholder country nodes into processedData nodes
      countries.forEach((d => {
        processedData.nodes.push({
          "name": d,
          "category": "Continent"
        })
      }));
      /// add placeholder qualityPercentiles nodes into processedData nodes
      qualityPercentiles.forEach((d => {
        processedData.nodes.push({
          "name": d,
          "category": "Quality Percentiles"
        })
      }));
      return processedData

    },
    sankeyNodesAndLinksContinents() {
      let continents = []
      let species = []
      let qualityPercentiles = []
      let processedData = {"nodes": [], "links": []}
      /// setting up list of countries, species, and quality Percentiles to contruct nodes and links
      let beans = []
      this.data.forEach((d => {

        let newBean = {
          continent: d.continent,
          Species: d.Species,
          percentile: d.percentile
        }
        beans.push(newBean)
        if (continents.includes(newBean.continent) === false) {
          continents.push(newBean.continent)
        }
        if (species.includes(newBean.Species) === false) {
          species.push(newBean.Species)
        }
        if (qualityPercentiles.includes(newBean.percentile) === false) {
          qualityPercentiles.push(newBean.percentile)
        }

      }))

      /// setting up links using nodes

      var i;
      var j;
      var sourceValue;
      var targetValue;
      var linkValue;

      for (i = 0; i < species.length; i++) {
        sourceValue = species[i]
        for (j = 0; j < continents.length; j++) {
          targetValue = continents[j]
          linkValue = d3.filter(beans, d => d.Species == sourceValue
              && d.continent == targetValue).length
          processedData.links.push({
            "source": i,
            "target": j + species.length,
            "value": linkValue
          })
        }
      }

      for (i = 0; i < continents.length; i++) {
        sourceValue = continents[i];
        for (j = 0; j < qualityPercentiles.length; j++) {
          targetValue = qualityPercentiles[j]
          linkValue = d3.filter(beans, d => d.continent == sourceValue
              && d.percentile == targetValue).length
          processedData.links.push({
            "source": i + species.length,
            "target": j + continents.length + species.length,
            "value": linkValue
          })
        }
      }


      /// add placeholder speies nodes into processedData nodes
      species.forEach((d => {
        processedData.nodes.push({
          "name": d,
          "category": "Species"
        })
      }));
      /// add placeholder country nodes into processedData nodes
      continents.forEach((d => {
        processedData.nodes.push({
          "name": d,
          "category": "Continent"
        })
      }));
      /// add placeholder qualityPercentiles nodes into processedData nodes
      qualityPercentiles.forEach((d => {
        processedData.nodes.push({
          "name": d,
          "category": "Quality Percentiles"
        })
      }));
      return processedData

    },


  },
  methods: {
    init() {
      console.log(d3) // This can be savely removed
                      // This will be called when the page loads.
                      // You can load your data and setup D3 her

      this.list_of_countries = this.selected_countries
      if (this.selected_countries == null) {
        this.sankeyData = this.sankeyNodesAndLinksContinents
      } else {
        if (this.selected_countries.length > 0) {

          this.sankeyData = this.sankeyNodesAndLinksSelectedCountries
        } else {
          this.sankeyData = this.sankeyNodesAndLinksContinents
        }
      }

      this.update()
    },
    update() {
      this.list_of_countries = this.selected_countries
      if (this.selected_countries == null) {
        this.sankeyData = this.sankeyNodesAndLinksContinents
      } else {
        if (this.selected_countries.length > 0) {

          this.sankeyData = this.sankeyNodesAndLinksSelectedCountries
        } else {
          this.sankeyData = this.sankeyNodesAndLinksContinents
        }
      }
      this.renderSankeyPlot();
    },
    renderSankeyPlot() {

      d3.select(`.sankey-chart-svg-${this.chartId}`).select("svg").remove();
      let svg = d3.select(`.spider-chart-svg-${this.chartId}`)
          .select(".sankeyPlotyayeet")

      let g = svg.append("g")
          .attr("transform", "translate(" + (this.width / 2 + this.margin.left) + "," + (this.height / 2 + this.margin.top) + ")");


      var formatNumber = d3.format(",.0f"),    // zero decimal places
          format = function (d) {
            return formatNumber(d)
          },
          color = d3.scaleOrdinal(["#6a8358", "#c39b7f", "#b77878", "#558c84",
            "#d2c693", "#9d7272", "#3d665b", "#80588a",
            "#be8071", "#34644a", "#9ba471"]);

      var newSankey = d3Sankey.sankey(this.sankeyData)
          .nodeWidth(36)
          .nodePadding(25)
          .size([this.width, this.height / 2.5]);

      var graph = newSankey(this.sankeyData)
      var link = d3.select('.plot2')
          .append("g")
          .attr("fill", "none")
          .attr("stroke", "#ffffff")
          .attr("stroke-opacity", 0.2)
          .attr("class", "linkGroup")
          .selectAll("path")
          .data(graph.links)
          .join("path")
          .attr("d", d3Sankey.sankeyLinkHorizontal())
          .style("stroke-width", function (d) {
            return d.width;
          })


      link.append("title")
          .text(d => {
            if (d.value > 0) {
              return d.source.name + " -> " +
                  d.target.name + "\n" + format(d.value)
            }
          });


      var node = d3.select('.plot2')
          .append("g")
          .attr("class", "nodeGroup")
          .selectAll("node")
          .data(graph.nodes)
          .enter().append("g")
          .attr("class", "node");


      node.append("rect")
          .attr("x", function (d) {
            return d.x0;
          })
          .attr("y", function (d) {
            return d.y0;
          })
          .attr("height", function (d) {
            return d.y1 - d.y0;
          })
          .attr("width", newSankey.nodeWidth())
          .style("fill", function (d) {
            return d.color = color(d.name.replace(/ .*/, ""));
          })
          .style("stroke", function (d) {
            return d3.rgb(d.color).darker(2);
          })
          .append("title")
          .text(function (d) {
            if (d.value > 0) {
              return d.name + "\n" + format(d.value) + " Coffees";
            }
          });

      node.append("text")
          .attr("x", function (d) {
            return d.x0 - 6;
          })
          .attr("y", function (d) {
            return (d.y1 + d.y0) / 2;
          })
          .attr("dy", ".35em")
          .attr("text-anchor", "end")
          .text(function (d) {
            if (d.value > 0) {
              return d.name;
            }
          })
          .style("font-size", "20px")
          .style("fill", "#f8f6ff")
          .filter(function (d) {
            return d.x0 < this.width / 2;
          })
          .attr("x", function (d) {
            return d.x1 + 6;
          })
          .attr("text-anchor", "start");
    },

  }
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style>
/* Add your CSS here */
</style>