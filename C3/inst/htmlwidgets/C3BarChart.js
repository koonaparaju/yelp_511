HTMLWidgets.widget({

  name: 'C3BarChart',

  type: 'output',

  factory: function(el, width, height) {

    var chart = null;

    // TODO: define shared variables for this instance

    return {

      renderValue: function(x) {

        if (chart == null){
          var chart = c3.generate({
                      bindto: el,
              data: {
                  json:[],
                  type: 'bar',
                  keys: {
                        x: 'rating',
                        value: 'count'
                  },
                  onclick: function(d, element) {

                    // id of pie to shiny to input$chartId_click
                    var inputId =  "pie1";

                    // pie slice label
                    var value = 'test';
                    //d.id;
                    console.log("test");
                    console.log(inputId);
                    console.log(d);
                    console.log(element);
                    // send message to shiny
                  Shiny.setInputValue(inputId,value);

                },

              },
              axis: {
                      x: {
                          type: 'category'
                      }
              },
              bar: {
                  width: {
                      ratio: 0.5 // this makes bar width 50% of length between ticks
                  }
                  // or
        //width: 100 // this makes bar width 100px
          }
      });
        }
        chart.load({
          json  : x.value,

          // unload data that we don't need anymore
          //unload: diff
        });



},

      resize: function(width, height) {

        // TODO: code to re-render the widget with a new size

      }

    };
  }
});
