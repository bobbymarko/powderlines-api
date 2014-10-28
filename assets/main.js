$(function() {  
  (function basic_time(container) {
  
    var
      d1 = [],
      options,
      graph,
      o;
    
    $.ajax({
      url: '/station/418:WA:SNTL',
      jsonp: "callback",
      dataType: "jsonp",
      data: {
        days: 100
      },
      success: function(data) {
        $.each(data.data, function() {
          d1.push([new Date(this["Date"]).getTime(), this["Snow Depth (in)"]]);
          graph = drawGraph(); 
        });
      }
    });
          
    options = {
      shadowSize: 0,
      lines : { fill : true, show: false, lineWidth: 0, color: '#ccc', fillColor:'#ccc' },
      xaxis : {
        mode : 'time', 
        labelsAngle : 45
      },
      yaxis : {
        min: 0,
        max: 200
      },
      selection : {
        mode : 'x'
      },
      HtmlText : false,
      title : 'Snow Depth (in)'
    };
          
    // Draw graph with default options, overwriting with passed options
    function drawGraph (opts) {
  
      // Clone the options, so the 'options' variable always keeps intact.
      o = Flotr._.extend(Flotr._.clone(options), opts || {});
  
      // Return a new graph.
      return Flotr.draw(
        container,
        [ d1 ],
        o
      );
    }
  
         
          
    Flotr.EventAdapter.observe(container, 'flotr:select', function(area){
      // Draw selected area
      graph = drawGraph({
        xaxis : { min : area.x1, max : area.x2, mode : 'time', labelsAngle : 45 },
        yaxis : { min : area.y1, max : area.y2 }
      });
    });
          
    // When graph is clicked, draw the graph with default area.
    Flotr.EventAdapter.observe(container, 'flotr:click', function () { graph = drawGraph(); });
  })(document.getElementById("editor-render-0"));
  
});