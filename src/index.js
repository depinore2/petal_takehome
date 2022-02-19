const fetch = require('node-fetch');

async function main(message) {
    const result = await fetch("http://API.SHOUTCLOUD.IO/V1/SHOUT", {
        method: 'post',
        body: JSON.stringify({ INPUT: message.split('').reverse().join('') }),
        headers: {'Content-Type': 'application/json'}
    })
    const jsonResponse = await result.json();
    return jsonResponse.OUTPUT;
}

// https://docs.aws.amazon.com/lambda/latest/dg/services-alb.html
exports.handler = async function(event) {
    const arg = JSON.parse(event.body).data;
    return {
        "statusCode": 200,
        "statusDescription": "200 OK",
        "isBase64Encoded": false,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": JSON.stringify({ data: await main(arg)})
    }
};