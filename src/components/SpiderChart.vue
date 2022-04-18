<!-- Your HTML goes here -->
<template>
  <div>
    <h1>{{ title }}</h1>
    <svg :class="`spider-chart-svg-${chartId}`" :viewBox="viewBox">
      <g :transform="`translate(${margin.left}, ${margin.top})`">
        <g class="plot"></g>
      </g>
    </svg>
    <svg class="legends" height=45 width=600></svg>
  </div>
</template>

<script>
import * as d3 from 'd3'

export default {
  name: 'SpiderChart', // Feel free to rename this and the file
  props: {
    // Feel free to add props to communicate between components
    chartId: {
      required: true,
      type: String
    },
    title: {
      type: String
    },
    height: {
      required: true,
      type: Number,
    },
    width: {
      required: true,
      type: Number,
    },
    data: {
      required: true,
      type: Array,
    },
    selectedCountry: {
      required: true,
      type: Array,
    },
  },
  mounted() {
    this.init()
  },
  data() {
    return {
      scaleData: null,
      rScaleMax: null,
      rScale: null,         //Scale for the radius
      total: null,					//The number of different axes
      radius: null,       	//Radius of the outermost circle
      Format: null,			   	//Percentage formatting
      angleSlice: null,	  	//The width in radians of each "slice"
      allAxis: null,        //Names of each axis
      levels: 5,				    //How many levels or inner circles should there be drawn
      maxValue: 0.5, 		   	//What is the value that the biggest circle will represent
      labelFactor: 1.1,   	//How much farther than the radius of the outer circle should the labels be placed
      wrapWidth: 60, 	    	//The number of pixels after which a label needs to be given a new line
      opacityArea: 0.35, 	  //The opacity of the area of the blob
      dotRadius: 10, 			  //The size of the colored circles of each blog
      opacityCircles: 0.1, 	//The opacity of the circles of each blob
      strokeWidth: 2, 		  //The width of the stroke around each blob
      roundStrokes: false,
      color: null,
      margin: {
        left: 100,
        top: 100,
        right: 300,
        bottom: 50,
      },
      // data: [
      //   [//iPhone
      //     {axis: "Battery Life", value: 0.22},
      //     {axis: "Brand", value: 0.28},
      //     {axis: "Contract Cost", value: 0.29},
      //     {axis: "Design And Quality", value: 0.17},
      //     {axis: "Have Internet Connectivity", value: 0.22},
      //     {axis: "Large Screen", value: 0.02},
      //     {axis: "Price Of Device", value: 0.21},
      //     {axis: "To Be A Smartphone", value: 0.50}
      //   ], [//Samsung
      //     {axis: "Battery Life", value: 0.27},
      //     {axis: "Brand", value: 0.16},
      //     {axis: "Contract Cost", value: 0.35},
      //     {axis: "Design And Quality", value: 0.13},
      //     {axis: "Have Internet Connectivity", value: 0.20},
      //     {axis: "Large Screen", value: 0.13},
      //     {axis: "Price Of Device", value: 0.35},
      //     {axis: "To Be A Smartphone", value: 0.38}
      //   ], [//Nokia Smartphone
      //     {axis: "Battery Life", value: 0.26},
      //     {axis: "Brand", value: 0.10},
      //     {axis: "Contract Cost", value: 0.30},
      //     {axis: "Design And Quality", value: 0.14},
      //     {axis: "Have Internet Connectivity", value: 0.22},
      //     {axis: "Large Screen", value: 0.04},
      //     {axis: "Price Of Device", value: 0.41},
      //     {axis: "To Be A Smartphone", value: 0.30}
      //   ]
      // ],
    }
  },
  watch: {
    data() {
      this.update()
    },
    selectedCountry(){
      this.render_legend()
    }
  },
  methods: {
    init() {
      // This will be called when the page loads.
      // You can load your data and setup D3 here
      this.calc_spider_scale_data()
      this.color = d3.scaleOrdinal(d3.schemeTableau10)
      this.radius = Math.min(this.width / 2, this.height / 2) * 0.9
      this.rScale = d3.scaleLinear()
          .domain([0, 10])
          .range([0, this.radius])

    },
    update() {
      this.allAxis = (this.data[0].map((i) => {
        return i.axis
      }))
      this.total = this.allAxis.length
      this.angleSlice = Math.PI * 2 / this.total
      this.renderSpiderChart()
      this.render_legend()
    },
    render_legend(){
      d3.select(`.legends`).selectAll("circle").remove()
      d3.select(`.legends`).selectAll("text").remove()
      var svg = d3.select(`.legends`)
      console.log("render legend")
      console.log(this.selectedCountry)
      if(!this.selectedCountry || this.selectedCountry.length === 0){
        const startX = 20
        const circleTextSpacing = 14
        svg.append("circle").attr("cx",startX).attr("cy",10).attr("r", 6).style("fill", this.color(0))
        svg.append("text").attr("x", startX + circleTextSpacing).attr("y", 12).text("All Countries").style("font-size", "15px").attr("alignment-baseline","middle").style("fill", "#f8f6ff")
      } else {
        const startX = 200
        const circleTextSpacing = 14
        const textCircleSpacing = 150
        for (let i = 0; i < this.selectedCountry.length; i++){
          const countryName = this.selectedCountry[i]
          console.log(countryName)
          svg.append("circle").attr("cx",startX + i * textCircleSpacing).attr("cy",10).attr("r", 6).style("fill", this.color(i))
          svg.append("text").attr("x", startX + circleTextSpacing + i * textCircleSpacing).attr("y", 12).text(countryName).style("font-size", "15px").attr("alignment-baseline","middle").style("fill", "#f8f6ff")

        }
      }

    },
    calc_spider_scale_data() {
      d3.csv("/data/spider_chart_data.csv", d3.autoType).then((data) => {
        const attributes = ["Aroma", "Aftertaste", "Acidity", "Balance", "Sweetness", "Flavor", "Uniformity", "Clean Cup"]
        const attrToScoreArr = {}
        for (let attribute of attributes) {
          attrToScoreArr[attribute] = []
        }
        for (let row of data) {
          for (let attribute of attributes) {
            if (row[attribute]) {
              attrToScoreArr[attribute].push(row[attribute])
            }
          }
        }
        const attrToMinMaxScore = {}
        for (let attribute of attributes) {
          attrToMinMaxScore[attribute] = [d3.min(attrToScoreArr[attribute]), d3.max(attrToScoreArr[attribute])]
        }

        this.scaleData = attrToMinMaxScore
        this.update()
      })
    },
    renderSpiderChart() {
      this.render_legend()
      /////////////////////////////////////////////////////////
      //////////// Create the container SVG and g /////////////
      /////////////////////////////////////////////////////////

      //Remove whatever chart with the same id/class was present before
      d3.select(`.spider-chart-svg-${this.chartId}`).select("g").remove();

      let svg = d3.select(`.spider-chart-svg-${this.chartId}`)

      //Append a g element
      let g = svg.append("g")
          .attr("transform", "translate(" + (this.width / 2 + this.margin.left) + "," + (this.height / 2 + this.margin.top) + ")");

      /////////////////////////////////////////////////////////
      ////////// Glow filter for some extra pizzazz ///////////
      /////////////////////////////////////////////////////////

      // Filter for the outside glow
      let filter = g.append('defs').append('filter').attr('id', 'glow')
      // eslint-disable-next-line no-unused-vars
      let feGaussianBlur = filter.append('feGaussianBlur').attr('stdDeviation', '2.5').attr('result', 'coloredBlur')
      let feMerge = filter.append('feMerge')
      // eslint-disable-next-line no-unused-vars
      let feMergeNode_1 = feMerge.append('feMergeNode').attr('in', 'coloredBlur')
      // eslint-disable-next-line no-unused-vars
      let feMergeNode_2 = feMerge.append('feMergeNode').attr('in', 'SourceGraphic')

      /////////////////////////////////////////////////////////
      /////////////// Draw the Circular grid //////////////////
      /////////////////////////////////////////////////////////

      //Wrapper for the grid & axes
      var axisGrid = g.append("g").attr("class", "axisWrapper");

      //Draw the background circles
      axisGrid.selectAll(".levels")
          .data(d3.range(1, (this.levels + 1)).reverse())
          .enter()
          .append("circle")
          .attr("class", "gridCircle")
          .attr("r", (d) => {
            return this.radius / this.levels * d;
          })
          .style("fill", "#ffffff")
          .style("stroke", "#ffffff")
          .style("fill-opacity", this.opacityCircles)
          .style("filter", "url(#glow)");

      // //Text indicating at what % each level is
      // axisGrid.selectAll(".axisLabel")
      //     .data(d3.range(1, (this.levels + 1)).reverse())
      //     .enter().append("text")
      //     .attr("class", "axisLabel")
      //     .attr("x", 4)
      //     .attr("y", (d) => {
      //       return -d * this.radius / this.levels;
      //     })
      //     .attr("dy", "0.4em")
      //     .style("font-size", "10px")
      //     .attr("fill", "#ffce82")
      //     .text((d) => {
      //       return this.Format(this.maxValue * d / this.levels);
      //     })

      /////////////////////////////////////////////////////////
      //////////////////// Draw the axes //////////////////////
      /////////////////////////////////////////////////////////

      //Create the straight lines radiating outward from the center
      var axis = axisGrid.selectAll(".axis")
          .data(this.allAxis)
          .enter()
          .append("g")
          .attr("class", "axis");
      //Append the lines
      console.log(this.scaleData)
      axis.append("line")
          .attr("x1", 0)
          .attr("y1", 0)
          .attr("x2", (d, i) => {
            return this.rScale(10 * 1.05) * Math.cos(this.angleSlice * i - Math.PI / 2);
          })
          .attr("y2", (d, i) => {
            return this.rScale(10 * 1.05) * Math.sin(this.angleSlice * i - Math.PI / 2);
          })
          .attr("class", "line")
          .style("stroke", "white")
          .style("stroke-width", "2px");

      //Append the labels at each axis
      axis.append("text")
          .attr("class", "legend")
          .style("font-size", "50px")
          .attr("text-anchor", "middle")
          .style("fill", "#ffffff")
          .attr("dy", "0.35em")
          .attr("x", (d, i) => {
            return this.rScale(10 * this.labelFactor) * Math.cos(this.angleSlice * i - Math.PI / 2);
          })
          .attr("y", (d, i) => {
            return this.rScale(10 * this.labelFactor) * Math.sin(this.angleSlice * i - Math.PI / 2);
          })
          .text((d) => {
            return d
          })
          .call(this.wrap, this.wrapWidth);

      /////////////////////////////////////////////////////////
      ///////////// Draw the radar chart blobs ////////////////
      /////////////////////////////////////////////////////////

      //The radial line function
      var radarLine = d3.lineRadial()
          .radius((d) => {
            let useScale
            if(!this.selectedCountry || this.selectedCountry === []){
              useScale = this.rScale
            }else{
              useScale = d3.scaleLinear()
                  .domain([this.scaleData[d.axis][0], this.scaleData[d.axis][1]])
                  .range([0, this.radius])
            }
            return useScale(d.value);
          })
          .angle((d, i) => {
            return i * this.angleSlice;
          });


      //Create a wrapper for the blobs
      var blobWrapper = g.selectAll(".radarWrapper")
          .data(this.data)
          .enter().append("g")
          .attr("class", "radarWrapper");


      //Append the backgrounds
      blobWrapper
          .append("path")
          .attr("class", "radarArea")
          .attr("d", (d) => {
            return radarLine(d);
          })
          .style("fill", (d, i) => {
            return this.color(i);
          })
          .style("fill-opacity", this.opacityArea)
          .on('mouseover', function () {
            //Dim all blobs
            d3.selectAll(".radarArea")
                .transition().duration(200)
                .style("fill-opacity", 0.1);
            //Bring back the hovered over blob
            d3.select(this)
                .transition().duration(200)
                .style("fill-opacity", 0.7);
          })
          .on('mouseout', () => {
            //Bring back all blobs
            d3.selectAll(".radarArea")
                .transition().duration(200)
                .style("fill-opacity", this.opacityArea);
          });

      // this thing is broken
      //Create the outlines
      // blobWrapper.append("path")
      //     .attr("class", "radarStroke")
      //     .attr("d", (d) => { return radarLine(d); })
      //     .style("stroke-width", this.strokeWidth + "px")
      //     .style("stroke", "#db2020")
      //     .style("fill", "none")
      //     .style("filter" , "url(#glow)");

      //Append the circles
      blobWrapper.selectAll(".radarCircle")
          .data((d) => {
            return d;
          })
          .enter()
          .append("circle")
          .attr("class", "radarCircle")
          .attr("r", this.dotRadius)
          .attr("cx", (d, i) => {
            let useScale
            if(!this.selectedCountry || this.selectedCountry === []){
              useScale = this.rScale
            }else{

              useScale = d3.scaleLinear()
                  .domain([this.scaleData[d.axis][0], this.scaleData[d.axis][1]])
                  .range([0, this.radius])
            }
            return useScale(d.value) * Math.cos(this.angleSlice * i - Math.PI / 2);
          })
          .attr("cy", (d, i) => {
            let useScale
            if(!this.selectedCountry || this.selectedCountry === []){
              useScale = this.rScale
            }else{

              useScale = d3.scaleLinear()
                  .domain([this.scaleData[d.axis][0], this.scaleData[d.axis][1]])
                  .range([0, this.radius])
            }
            return useScale(d.value) * Math.sin(this.angleSlice * i - Math.PI / 2);
          })
          .style("fill", (d, i, j) => {
            return this.color(j);
          })
          .style("fill-opacity", 0.8);

      /////////////////////////////////////////////////////////
      //////// Append invisible circles for tooltip ///////////
      /////////////////////////////////////////////////////////

      //Wrapper for the invisible circles on top
      var blobCircleWrapper = g.selectAll(".radarCircleWrapper")
          .data(this.data)
          .enter()
          .append("g")
          .attr("class", "radarCircleWrapper");

      //Set up the small tooltip for when you hover over a circle
      var tooltip = g.append("text")
          .attr("class", "tooltip")
          .style("opacity", 0)

      //Append a set of invisible circles on top for the mouseover pop-up
      const self = this
      blobCircleWrapper.selectAll(".radarInvisibleCircle")
          .data((d) => {
            return d;
          })
          .enter()
          .append("circle")
          .attr("class", "radarInvisibleCircle")
          .attr("r", this.dotRadius * 2)
          .attr("cx", (d, i) => {
            let useScale
            if(!this.selectedCountry || this.selectedCountry === []){
              useScale = this.rScale
            }else{

              useScale = d3.scaleLinear()
                  .domain([this.scaleData[d.axis][0], this.scaleData[d.axis][1]])
                  .range([0, this.radius])
            }
            return useScale(d.value) * Math.cos(this.angleSlice * i - Math.PI / 2);
          })
          .attr("cy", (d, i) => {
            let useScale
            if(!this.selectedCountry || this.selectedCountry === []){
              useScale = this.rScale
            }else{

              useScale = d3.scaleLinear()
                  .domain([this.scaleData[d.axis][0], this.scaleData[d.axis][1]])
                  .range([0, this.radius])
            }
            return useScale(d.value) * Math.sin(this.angleSlice * i - Math.PI / 2);
          })
          .style("fill", "none")
          .style("pointer-events", "all")
          .on("mouseover", function (event, d) {
            const newX = parseFloat(d3.select(this).attr('cx')) - 10;
            const newY = parseFloat(d3.select(this).attr('cy')) - 10;
            tooltip
                .attr('x', newX)
                .attr('y', newY)
                .text(Math.round(d.value * 100) / 100)
                .style("font-size", "40px")
                .style("fill", "#f8f6ff")
                .transition().duration(200)
                .style('opacity', 1);
          })
          .on("mouseout", () => {
            tooltip.transition().duration(200)
                .style("opacity", 0);
          });

    },
    wrap(texts, width) {
      //Taken from http://bl.ocks.org/mbostock/7555321
      //Wraps SVG text
      texts.each(function () {
        var text = d3.select(this)
        var words = text.text().split(/\s+/).reverse(),
            word,
            line = [],
            lineNumber = 0,
            lineHeight = 1.4, // ems
            y = text.attr("y"),
            x = text.attr("x"),
            dy = parseFloat(text.attr("dy")),
            tspan = text.text(null).append("tspan").attr("x", x).attr("y", y).attr("dy", dy + "em");

        // eslint-disable-next-line no-cond-assign
        while (word = words.pop()) {
          line.push(word);
          tspan.text(line.join(" "));
          if (tspan.node().getComputedTextLength() > width) {
            line.pop();
            tspan.text(line.join(" "));
            line = [word];
            tspan = text.append("tspan").attr("x", x).attr("y", y).attr("dy", ++lineNumber * lineHeight + dy + "em").text(word);
          }
        }
      });
    }
  },
  computed: {
    viewBox() {
      return `0 0 ${this.width + this.margin.left  + this.margin.right} ${this.height + this.margin.top + this.margin.bottom}`
    },
  }
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style>
/* Add your CSS here */
.tooltip {
  position: absolute;
  text-align: center;
  width: 80px;
  height: 40px;
  padding: 2px;
  font: 12px sans-serif;
  background: seashell;
  border: 0px;
  border-radius: 8px;
  pointer-events: none;
}
</style>