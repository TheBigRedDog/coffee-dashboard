<!-- This file will be used to layout and connect your views -->
<template>
  <div id="app">
    <!-- This is only a basic setup to display your views. Use HTML and CSS to create your layout using these basic commands -->
    <div id="overview">
      <WorldMap
          class="world-map"
          chartId="coffe-quality-1"
          title="World Map by Coffee Bean"
          :width="800"
          :height="1200"
          :data="coffee_bean_color"
          v-if='coffee_bean_color'
          @countries_selected='countries_selected'
      />
    </div>
<div id="detail">
    <div id="sankey">
      <SankeyChart
          class="sankey-chart"
          chartId="coffee-quality-3"
          :data='data_with_percentiles_and_continents'
          v-if='data_with_percentiles_and_continents'
          :selected_countries='mapSelection'
          title="Coffee Flow"
          :width="1000"
          :height="1000"/>
    </div>


    <div id="Spider_Chart">
      <div id="Actual_Spider_Chart">
        <SpiderChart
            class="spider-chart"
            chartId="coffee-quality-2"
            title="Quality of Coffee Beans"
            v-if="spider_dataset"
            :data="spider_dataset"
            :selected-country="mapSelection"
            :scale-data="spider_scale_data"
            :width="1600"
            :height="1600"/>
      </div>
      <div id="Spider_checks">
        <h3 id="selection_title">Quality Selector</h3>
        <ul>
          <br>
          <li><input type="checkbox" id="1" value="Aroma" v-model="selectedAttrs">
            <label for="1">Aroma</label>
          </li>

          <li><input type="checkbox" id="2" value="Aftertaste" v-model="selectedAttrs">
            <label for="2">Aftertaste</label>
          </li>
          <li><input type="checkbox" id="3" value="Sweetness" v-model="selectedAttrs">
            <label for="3">Sweetness</label>
          </li>

          <li><input type="checkbox" id="4" value="Flavor" v-model="selectedAttrs">
            <label for="4">Flavor</label></li>

          <li><input type="checkbox" id="5" value="Uniformity" v-model="selectedAttrs">
            <label for="5">Uniformity</label></li>

          <li><input type="checkbox" id="6" value="Balance" v-model="selectedAttrs">
            <label for="6">Balance</label>
          </li>

          <li><input type="checkbox" id="7" value="Clean Cup" v-model="selectedAttrs">
            <label for="7">Clean Cup</label></li>
          <li><input type="checkbox" id="8" value="Acidity" v-model="selectedAttrs">
            <label for="8">Acidity</label></li>
        </ul>
      </div>
    </div>
  </div>
  </div>
</template>

<script>
// You are free to define more than three views!
// Try to use descriptive names like 'OverviewScatterPlot' or 'DetailLineChart'
import * as d3 from 'd3'
import WorldMap from './components/WorldMap.vue'
import SankeyChart from './components/SankeyChart.vue'
import SpiderChart from './components/SpiderChart.vue';

export default {
  name: 'App',
  components: {
    WorldMap,
    SankeyChart,
    SpiderChart
  },
  data() {
    return {
      mapSelection: [],
      coffee_bean_color: null,
      original_data: null,
      robusta_data: null,
      percentile_brackets: null,
      spider_dataset: null,
      spider_state: "no selection",
      selectedAttrs: ["Aroma", "Acidity", "Aftertaste", "Flavor", "Sweetness"],
      spider_scale_data: {},
      data_with_percentiles_and_continents: null,
    }
  },
  created() {
    var countries_lookup = {};
    d3.json('/data/country-by-continent.json', d3.autoType)
        .then(country_continent_pairs => {
          country_continent_pairs.forEach(pair => {
            countries_lookup[pair.country] = pair.continent
          })
        });

    d3.csv('/data/robusta_data_cleaned.csv', d3.autoType)
        .then(data => {
          this.robusta_data = data
        });

    d3.csv('/data/arabica_data_cleaned.csv', d3.autoType)
        .then(data => {
          function createCountryGroups(dataset) {
            const countries = {};
            dataset.forEach(d => {
              if (d.Country_of_Origin in countries) {
                countries[d.Country_of_Origin].bean_count += 1
              } else if (d.Country_of_Origin.includes("United States")) {
                if ("United States" in countries) {
                  countries["United States"].bean_count += 1
                } else {
                  const country = {
                    name: d.Country_of_Origin,
                    bean_count: 0
                  }
                  countries[d.Country_of_Origin] = country
                }
              } else {
                const country = {
                  name: d.Country_of_Origin,
                  bean_count: 0
                }
                countries[d.Country_of_Origin] = country
              }
            })
            const formatted_data = []
            Object.keys(countries).forEach(d => {
              formatted_data.push(countries[d]);
            });

            return formatted_data
          }

          function createPercentileGroupsAndContinents(dataset) {
            const total_cup_scores = []
            dataset.forEach(d => {
              total_cup_scores.push(d.Total_Cup_Points)
            })
            total_cup_scores.sort();

            var twenty_percentile_cutoff = total_cup_scores[Math.floor(total_cup_scores.length / 5)]
            var fourty_percentile_cutoff = total_cup_scores[Math.floor(total_cup_scores.length / 5 * 2)]
            var sixty_percentile_cutoff = total_cup_scores[Math.floor(total_cup_scores.length / 5 * 3)]
            var eighty_percentile_cutoff = total_cup_scores[Math.floor(total_cup_scores.length / 5 * 4)]
            var new_data = dataset.slice()
            new_data.forEach(d => {
              if (d.Total_Cup_Points > eighty_percentile_cutoff) {
                d.percentile = "80-100th Percentile of Coffees"
              } else if (sixty_percentile_cutoff < d.Total_Cup_Points && d.Total_Cup_Points <= eighty_percentile_cutoff) {
                d.percentile = "60-80th Percentile of Coffees"
              } else if (fourty_percentile_cutoff < d.Total_Cup_Points && d.Total_Cup_Points <= sixty_percentile_cutoff) {
                d.percentile = "40-60th Percentile of Coffees"
              } else if (twenty_percentile_cutoff < d.Total_Cup_Points && d.Total_Cup_Points <= fourty_percentile_cutoff) {
                d.percentile = "20-40th Percentile of Coffees"
              } else {
                d.percentile = "0-20th Percentile of Coffees"
              }
              var country = d.Country_of_Origin
              switch (country) {
                case "United States (Hawaii)":
                  d.continent = "North America";
                  break;
                case "United States (Puerto Rico)":
                  d.continent = "North America";
                  break;
                case "Taiwan":
                  d.continent = "Asia";
                  break;
                case "Tanzania, United Republic Of":
                  d.continent = "Africa";
                  break;
                case "Cote d'Ivoire":
                  d.continent = "Africa";
                  break;
                default:
                  if (countries_lookup[d.Country_of_Origin] == "Oceania") {
                    d.continent = "Asia"
                  } else {
                    d.continent = countries_lookup[d.Country_of_Origin]
                  }
              }

            })
            return new_data
          }

          var arabica_with_percentiles = createPercentileGroupsAndContinents(data)
          var robusta_with_percetile = createPercentileGroupsAndContinents(this.robusta_data)
          this.data_with_percentiles_and_continents = arabica_with_percentiles.concat(robusta_with_percetile)
          this.coffee_bean_color = createCountryGroups(data)
        })
    this.spider_country_average()
  },
  watch: {
    selectedAttrs() {
      if (!this.mapSelection || this.mapSelection === [] || this.mapSelection.length === 0) {
        this.spider_country_average()
      } else {
        this.spider_selected_country_average()
      }
    },
    mapSelection() {
      if (!this.mapSelection || this.mapSelection === [] || this.mapSelection.length === 0) {
        console.log("no map selection")
        this.spider_country_average()
      } else {
        console.log("map selection")
        console.log(this.mapSelection)
        this.spider_selected_country_average()
      }
    }
  },
  methods: {
    spider_country_average() {
      // updates spider_dataset
      d3.csv("/data/spider_chart_data.csv", d3.autoType).then((data) => {
        this.spider_dataset = [this.spider_calc_average(data)]
      })
    },
    spider_calc_average(data) {
      const attributes = this.selectedAttrs
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
      const attrToAvgScore = []
      for (let attribute of attributes) {
        attrToAvgScore.push({"axis": attribute, "value": d3.mean(attrToScoreArr[attribute])})
      }
      return attrToAvgScore
    },
    spider_selected_country_average() {
      d3.csv("/data/spider_chart_data.csv", d3.autoType).then((data) => {
        let countryToAttrToAvgScore = []
        for (let country of this.mapSelection) {
          const countryData = data.filter(d => {
            return d["Country of Origin"] === country
          })
          countryToAttrToAvgScore.push(this.spider_calc_average(countryData))
        }
        this.spider_dataset = countryToAttrToAvgScore
      })

    },

    countries_selected(myCountries) {
      this.mapSelection = myCountries
      // Returns a list of country names
      console.log(this.mapSelection)
    },

  }
}
</script>

<style>
body {background-color: #2c3e50;}
#app {
  font-family: Avenir, Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-align: center;
  color: #ffd953;
  background-color: #2c3e50;
  display: grid;
  grid-template-columns: 50vw 50vw;
  grid-template-areas:
    "overview detail";
}

#overview{
  grid-area: overview;
  padding-top: 20px;
}


#detail{
  grid-area: detail;
  grid-template-rows: 100px 40vh;
  grid-template-areas:
    "sankey";

}

#sankey{
  padding-top: 20px;
  grid-area: sankey;
}

#Spider_Chart {
  padding-top: 50px;
  display: grid;
  grid-template-columns: 1fr 1fr;
}

ul {
  list-style-type: none;
  border: 2px solid coral;
  border-radius: 5px;
  line-height: 2.5em;
  padding: 0;
  margin: 0;
}

#Spider_checks {
  display: grid;
}

#Actual_Spider_Chart {
  text-decoration: underline;
}

#selection_title {
  text-decoration: underline;
  padding-left: 40px;
}

h1 {
  margin: 0;
  text-decoration: underline;
}


</style>
