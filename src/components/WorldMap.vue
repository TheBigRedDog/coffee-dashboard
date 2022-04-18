<!-- Your HTML goes here -->
<template>
    <div>
        <h1>{{ title }}</h1>
         <h4> Single click to select a country, double click to unselect a country.</h4>
        <svg class="`world-map-svg-${chartId}`" :viewBox = 'myViewBox'>
            <g :transform = "`translate(${margin.left}, ${margin.top})`">
                <g :transform = "`translate(0,-50)`" class = "World_Map">
                    <!-- Your map goes here! -->
                </g>
                <g :transform = "`translate(${margin.left + 250}, ${margin.top+420})`" class='legend'></g>
            </g>
        </svg>
    </div>
</template>

<script>
import * as d3 from 'd3'
const topojson = require('topojson-client')

export default {
  name: 'WorldMap', // Feel free to rename this and the file
  props: {
    data:{
        required:true,
        type:Array
    },
    title:{
      required:true,
      type:String
    },
    height:{
          required:true,
          type:Number
    },
    width:{
        required:true,
        type:Number
    }
  },
   data(){
      return{
          x:null,
          y: null,
          margin: {
              left:-100,
              top: 100,
              right: 0,
              bottom: -500,
          }
      }
    },
  mounted() {
      this.init()
  },
  watch: {
      data(){
          this.renderMap()
      }
  },
  methods: {
      init() {
          this.renderMap()
      },
      renderMap(){
        let h= 50, w = 300;
           let legendY = d3.scaleLinear()
            .range([295, 8])
            .domain([100, 0]);
            let legendYAxis = d3.axisBottom()
            .scale(legendY)
            .ticks(5);
          let countryArr = []
          let color = d3.scaleSqrt().range(["#a6aeba","#823535"]).domain([0,120])
          let myMap = d3.json("/maps/countries-110m.json")
          let worldMap = myMap.then(function(data){
              return topojson.feature(data, data.objects.countries).features
          })
          let self = this
          async function createMap(){
              let projection = d3.geoMercator()
              .scale(100)
              let path = d3.geoPath().projection(projection)
              let dataColor = await self.data;
              let country_data = await worldMap;
              const plot_items =
              d3.select('.World_Map')
              .selectAll(".country")
              .data(country_data)
              .enter()
              .append("path")
              .attr("fill", function(d,i){
                   for (let j = 0; j < dataColor.length; j++){
                       if (dataColor[j].name == d.properties.name){
                           return color(dataColor[j].bean_count)
                       }
                   }
                   return "#a6aeba"
               })
              .attr("class","country")
              .attr("d", path)
              .on('click',clicked)
              .on('dblclick',unclicked)
              .on('mouseover',mouseOver)
                  //console.log(self)
              .on('mouseout', data=>
              d3.select('.World_Map')
              .selectAll("#Pop_up_name")
              .remove())
              function countriesSelected(myCountries){
                  self.$emit('countries_selected',myCountries)
              }
              function unclicked(event,d){
                // Remove from array
                d3.select(this).attr("fill",function(d,i){
                    for(let j = 0; j <dataColor.length; j++){
                        if (dataColor[j].name == d.properties.name){
                            return color(dataColor[j].bean_count)
                        }
                    }
                    return "#a6aeba"
                })
                if(countryArr.length >= 1){
                  for (let i = 0; i < countryArr.length; i++){
                    if (countryArr[i] == d.properties.name){
                        countryArr.splice(i,1)
                        }
                    }
                    countriesSelected(countryArr)
                 }
              }
              function clicked(event,d){
                  if (countryArr.length <= 2 && countryArr.includes(d.properties.name)== false){
                      d3.select(this).attr("fill","#425f43")
                      countryArr.push(d.properties.name)
                      countriesSelected(countryArr)
                  }else{
                      console.log("De-select a country first!")
                  }
              }
              function mouseOver(event,d){
                let mouseLoc = d3.pointer(event)
                let country_name = d.properties.name
                let group = d3.select('.World_Map').append('g');
                let coffee_bean_count = 0
                for(let i = 0; i < dataColor.length; i++){
                    if(dataColor[i].name == country_name){
                        coffee_bean_count = dataColor[i].bean_count
                    }
                }
                group.append("text")
                .text("Country Name: " + country_name)
                .attr('font-size',15)
                .attr("x",mouseLoc[0])
                .attr("y",mouseLoc[1])
                .attr("transform", `translate(0,0)`)
                .attr("fill","white")
                .attr("id","Pop_up_name")
                .attr("opacity",1)
                group.append("text")
                .text("Bean Count: " + coffee_bean_count)
                .attr('font-size',15)
                .attr("x",mouseLoc[0])
                .attr("y",mouseLoc[1])
                .attr("transform", `translate(1,15)`)
                .attr("fill","white")
                .attr("id","Pop_up_name")
                .attr("opacity",1)
              }
               const key = d3.select(".legend")
              .append("svg")
              .attr("width", w)
              .attr("height", h);

              let legend = key.append("defs")
              .append("svg:linearGradient")
              .attr("id", "gradient")
              .attr("x1", "0%")
              .attr("y1", "100%")
              .attr("x2", "100%")
              .attr("y2", "100%")
              .attr("spreadMethod", "pad");

              legend.append("stop")
                .attr("offset", "0%")
                .attr("stop-color", "#a6aeba")
                .attr("stop-opacity", 1);

                legend.append("stop")
                .attr("offset", "33%")
                .attr("stop-color", "#523737")
                .attr("stop-opacity", 1);

                legend.append("stop")
                .attr("offset", "66%")
                .attr("stop-color", "#542828")
                .attr("stop-opacity", 1);

                legend.append("stop")
                .attr("offset", "100%")
                .attr("stop-color", "#5e1111")
                .attr("stop-opacity", 1);

                key.append("rect")
                .attr("width", w)
                .attr("height", h - 35)
                .style("fill", "url(#gradient)")
                .attr("transform", "translate(0,15)");

                 key.append("g")
                .attr("class", "y axis")
                .attr("transform", "translate(-6.5,30)")
                .call(legendYAxis)
                .append("text")
                .attr("y", 0)
                .attr("dy", ".71em")
                .style("text-anchor", "end");

                key.append("text")
                .text("Coffee Bean Count:")
                .attr("font-size",14)
                .attr("transform", "translate(0,12)")
                .attr("fill","#ffd953")
                .attr("opacity",1)
          }
          let newMap = createMap()
      },

  },
  computed: {
      myViewBox(){
          return `0 0 ${this.width} ${this.height + this.margin.bottom}`
      }
  }
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style>
text{
   outline-style: none;
}
</style>