const querystring = require('querystring'); // Node.js를 실행할 Lambda 머신이 가지고 있기에 별도의 설치를 하지 않습니다.
const AWS = require('aws-sdk'); // Node.js를 실행할 Lambda 머신이 가지고 있기에 별도의 설치를 하지 않습니다.
const S3 = new AWS.S3({
  signatureVersion: 'v4',
  region: "ap-northeast-2"
});
const sharp = require('sharp');
const BUCKET = 'jhoh-tf-cloudfront-s3'; // your bucket
const supportImageTypes = ['jpg', 'jpeg', 'png', 'svg', 'tiff', 'webp'];

exports.handler = async (event, context, callback) => {
    const response = event.Records[0].cf.response;
    const request = event.Records[0].cf.request;

    // check if image is present and not cached.
    if (response.status == 200) {
        const params = new URLSearchParams(request.querystring);
        const uri = request.uri;
        const [mainuri,,imageName, extension] = uri.match(/\/(.*)\/(.*)\.(.*)/);
        const formatMatch = params.get("webp");

        const originFormat = extension == "jpg" ? "jpeg" : extension;
        const requiredFormat = formatMatch == 'true' ? 'webp' : originFormat;

        let str = mainuri.split('/')
        let bucketprefix = "users/"+str[1]+"/"+str[2] +"/"
        
        // 이미지 포맷이 아닌 경우 무시
        if (!supportImageTypes.includes(requiredFormat)) {
            console.log("no image format")
            callback(null, response);
            return;
        }

        response.headers["content-type"] = [{key: "Content-type", value: "image/" + requiredFormat}];
        if (!response.headers['cache-control']) {
            response.headers['cache-control'] = [{key: 'Cache-Control', value: 'public, max-age=86400'}];
        }
        if (!params.has("w") && !params.has("h")) {
            callback(null, response);
            console.log("no have param image just returned!")
            return;
        }
        try {
            const originalKey = bucketprefix+decodeURIComponent(imageName) + "." + extension;
            console.log(originalKey) // 디코딩한 파일 이름 및 확장자
            const s3Object = await S3.getObject({Bucket: BUCKET, Key: originalKey}).promise();
            let resizedImage;
            let metaData;
            let s3OriginImage;
            let type;
            // query param t가 존재한다면 해당 타입으로 리사이징을 한다. Default는 cover를 사용한다.
            /***
             * cover: (default) Preserving aspect ratio, ensure the image covers both provided dimensions by cropping/clipping to fit.
             * contain: Preserving aspect ratio, contain within both provided dimensions using "letterboxing" where necessary.
             * fill: Ignore the aspect ratio of the input and stretch to both provided dimensions.
             * inside: Preserving aspect ratio, resize the image to be as large as possible while ensuring its dimensions are less than or equal to both those specified.
             * outside: Preserving aspect ratio, resize the image to be as small as possible while ensuring its dimensions are greater than or equal to both those specified.
             */
            if (params.get("t"))
                type = params.get("t");
            else
                type = "fill";

            s3OriginImage = await sharp(s3Object.Body).rotate();
            metaData = await s3OriginImage.metadata();
            if (params.get("w") && params.get("h")) { // 둘다 있으면
                const width = parseInt(params.get("w"));
                const height = parseInt(params.get("h"));
                resizedImage = s3OriginImage.resize(width, height, {fit: type}).toFormat(requiredFormat);
            } else if (params.get("w")) { // 하나만 있으면
                const width = parseInt(params.get("w"));
                resizedImage = s3OriginImage.resize({width: width}).toFormat(requiredFormat);
            } else if (params.get("h")) { // 하나만 있으면
                const height = parseInt(params.get("h"));
                resizedImage = s3OriginImage.resize({height: height}).toFormat(requiredFormat);
            } else {
                return callback(null, response);
            }
            resizedImage = await resizedImage.toBuffer();
            byteLength = Buffer.byteLength(resizedImage, 'base64');
            
            // 만약 resizing을 했음에도 불구하고 1GB를 넘는다면 바디를 조작할 수 없다 ( AWS edge 한계 )
            // 따라서 이 경우는 화질을 70프로까지 떨어뜨리는 시도를 한다
            if (byteLength >= 1046528) {

                s3OriginImage = await sharp(s3Object.Body).rotate();
                metaData = await s3OriginImage.metadata();
                if (params.get("w") && params.get("h")) { // 둘다 있으면
                    const width = parseInt(params.get("w"));
                    const height = parseInt(params.get("h"));
                    resizedImage = s3OriginImage.resize(width, height, {fit: type}).toFormat(requiredFormat, {quality: 70});
                } else if (params.get("w")) { // 하나만 있으면
                    const width = parseInt(params.get("w"));
                    resizedImage = s3OriginImage.resize(width, metaData.height, {fit: type}).toFormat(requiredFormat, {quality: 70});
                } else if (params.get("h")) { // 하나만 있으면
                    const height = parseInt(params.get("h"));
                    resizedImage = s3OriginImage.resize(metaData.width, height, {fit: type}).toFormat(requiredFormat, {quality: 70});
                } else {
                    return callback(null, response);
                }

                resizedImage = await resizedImage.toBuffer();
                byteLength = Buffer.byteLength(resizedImage, 'base64');
                console.log("70 quality " + byteLength);
                if (byteLength >= 1046528) //TODO  반복문을 돌며 loop를 돌며 검사하는 방식으로 수정하면 더 좋을것 같음.
                    return callback(null, response); // 리사이징 + 70프로에서도 1MB를 넘는다면 그냥 원본을 반환해준다
            }
            response.status = 200;
            response.body = resizedImage.toString('base64');
            response.bodyEncoding = "base64";
            return callback(null, response);
        } catch
            (error) {
            console.log(error);
            return callback(error);
        }
    } else {// allow the response to pass through
        console.log("status " + response.status);
        callback(null, response);
    }
}