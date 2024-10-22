"use strict"

const Express = require('express');
const PrometheusClient = require('prom-client')

const register = new PrometheusClient.Registry();
const http_customer_request_counter = new PrometheusClient.Counter({
    name: 'billed_api_counter',
    help: 'Count of Customer HTTP requests made to my API',
    labelNames: ['customer'],
});
register.registerMetric(http_customer_request_counter);
const http_customer_request_duration = new PrometheusClient.Counter({
    name: 'billed_api_duration',
    help: 'Amount of time consumed by Customer HTTP requests made to my API',
    labelNames: ['customer'],
});
register.registerMetric(http_customer_request_duration);

const app = Express();
const billingCountersMiddleware = (req, res, next) => {
    const customerHeader = req.headers['customer'];

    if (!customerHeader) {
        next();
        return;
    }    
    //request counter
    http_customer_request_counter.labels({ customer: customerHeader }).inc();
    //request duration
    const start = Date.now();
    res.once('finish', () => {
        const duration = Date.now() - start;
        console.log("Customer: " + customerHeader +". Time taken(ms) to process " + req.originalUrl + " is: " + duration);
        http_customer_request_duration.labels({ customer: customerHeader }).inc(duration);
    });    

    next();
}

app.use(Express.json());
app.use(billingCountersMiddleware);

app.get("/metrics", (req, res) => {
    res.setHeader("Content-Type", register.contentType);

    register.metrics().then(data => res.status(200).send(data));    
});

const sleep = s => new Promise(r => setTimeout(r, Math.floor(Math.random() * 1000 * s)));
app.get("/operation1", async (req, res) => {    
    console.log("This operation will take a random time up to 1 second to complete");    
    await sleep(1);

    res.status(200).send("OK[op1]");
});

app.get("/operation2", async (req, res) => {    
    console.log("This operation will take a random time up to 10 second to complete");    
    await sleep(10);

    res.status(200).send("OK[op2]");
})

app.get("/reset", async (req, res) => {    
    http_customer_request_counter.reset();
    http_customer_request_duration.reset();
    console.log("Customer counter reset.")
    res.status(200).send("OK[reset]");
})


app.listen(8000, () => console.log(`Example for using Prometheus labels running on port 8000`));