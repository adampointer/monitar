exports.handler = (event, context, callback) => {
    try {
        console.log("value1 = " + event.key1);
        callback(null, "some success message");
    } catch (err) {
        callback(err);
    }
};
