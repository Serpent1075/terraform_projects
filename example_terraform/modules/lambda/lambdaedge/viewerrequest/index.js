const querystring = require('querystring');

// defines the allowed dimensions, default dimensions and how much variance from allowed
// dimension is allowed.

const variables = {
        allowedDimension : [ {w:100,h:100}, {w:200,h:200}, {w:300,h:300}, {w:400,h:400} , {w:500,h:500}],
        defaultDimension : {w:200,h:200},
        variance: 20,
        webpExtension: 'webp'
  };

exports.handler = (event, context, callback) => {
    const request = event.Records[0].cf.request;
   
    // parse the querystrings key-value pairs. In our case it would be d=100x100
    const params = new URLSearchParams(request.querystring);
   
    // fetch the uri of original image
    let fwdUri = request.uri;
    // if there is no dimension attribute, just pass the request
    if (!params.get("w") && !params.get("h")) {
        callback(null, request);
        return;
    }
    // read the dimension parameter value = width x height and split it by 'x'
    let width = params.get("w");
    let height = params.get("h");
  
    // calculate the acceptable variance. If image dimension is 105 and is within acceptable
    // range, then in our case, the dimension would be corrected to 100.
    let variancePercent = (variables.variance/100);

    for (let dimension of variables.allowedDimension) {
        let minWidth = dimension.w - (dimension.w * variancePercent);
        let maxWidth = dimension.w + (dimension.w * variancePercent);
        if(width >= minWidth && width <= maxWidth){
            width = dimension.w;
            height = dimension.h;
            matchFound = true;
            break;
        }
    }
    // if no match is found from allowed dimension with variance then set to default
    //dimensions.
    if(!matchFound){
        width = variables.defaultDimension.w;
        height = variables.defaultDimension.h;
    }
    params.set("w",width);
    params.set("h",height);

    request.uri = fwdUri;
    request.querystring = params.toString();

    
    callback(null, request);
};
