// Renders the shop via phantomjs for access tests
var page = require('webpage').create();
var system = require('system');
var env = system.env;
var exitCode = 0;

page.onResourceError = function(resourceError) {
    page.reason = resourceError.errorString;
    page.reason_url = resourceError.url;
};

page.open(env.URL, function(status) {
    if (status !== 'success') {
        console.log("Failed to load the page.");
        console.log(page.reason_url);
        console.log(page.reason);
        exitCode = 1;
    }
    phantom.exit(exitCode);
});
