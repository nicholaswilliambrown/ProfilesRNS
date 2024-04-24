WatchdogTimer = function (timeout_ms, callback) {
    this.timer = setTimeout(callback, timeout_ms);
};

WatchdogTimer.prototype.cancel = function () {
    clearTimeout(this.timer);
};

function getClusterWatchdog() {
    let dog = new WatchdogTimer(30000, function () {
        var el = jQuery(".clusterView");
        el = el[0];
        el.innerHTML = "<h2>There was a problem loading this visualization. You might need to upgrade your browser or select one of the options below.</h2>";
        el.style.height = "auto";
        jQuery(el.nextSibling).remove();
    });
    return dog;
}
