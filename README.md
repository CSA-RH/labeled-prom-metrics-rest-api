# Sample Usage of Labeled Prometheus Metrics with Python and Node.js Client Libraries

This system showcases the use of labeled Prometheus metrics to monitor tenant or customer-specific usage. It stores usage counters in user workload instances of Prometheus running in an OpenShift 4.x cluster.

The demo consists of two REST APIs: one implemented in Python using FastAPI and the `prometheus-client` library, and the other in Node.js using Express and the prom-client npm package. Both APIs feature two GET endpoints: `/operation1` and `/operation2`, which take a random amount of time to complete successfully.

Two Prometheus metric counters are provided: `billed_api_counter` and `billed_api_duration`. The billed_api_counter counts the number of requests and labels the metric with the value of the `customer` header if it is included in the request. The `billed_api_duration` counter tracks the duration of requests in milliseconds, using the same labeling approach.

In both systems, the architectural principle is consistent: a middleware component calculates request-specific metrics to be stored in the Prometheus instance.

Additionally, a `/reset` endpoint will set the counters to 0. 

# Deployment

To deploy the APIs, you need a running and accessible OpenShift cluster, along with a user logged into the oc utility with admin permissions for the currently selected namespace. Additionally, the cluster must have the user workload monitoring flag enabled to scrape custom metrics.

To deploy the application, navigate to the root folder and run the command:

```console
./deploy.sh python|node
``` 

This command will deploy either the Python or Node.js solution. If they are not already created, it will also generate the necessary resources, including Build, BuildConfig, Deployment, Services, ServiceMonitor, and Route, to successfully deploy the REST APIs.

# Testing

To create sample traffic for either the Python or Node.js API, simply use the script located in the root folder: ./test.sh. Run the command:

```console
./test.sh node|python
```

This will randomly invoke either `operation1` or `operation2` for three random tenants. The script will generate labeled metrics at the `/metrics` endpoint, which will be scraped by Prometheus using the preconfigured ServiceMonitor.

# Results

Since the counter values result from monotonically increasing functions, application restarts will reset these metrics to 0. Additionally, you can manually reset the counters by calling the /reset endpoint.

To avoid relying on a persistence mechanism, you can perform aggregate calculations. For example, by taking the last known value over a specified period and summarizing the results, you can obtain the total count of the monotonically increasing functions during that time.

For instance, the following PromQL function will give the aggregated value of the sum of the last value given before pod restart. 

```console
sum(last_over_time(billed_api_counter{customer="malagacf", namespace="test-prom-clients"}[1h]) or vector(0))
```
