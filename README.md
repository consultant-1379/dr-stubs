#Discover and Reconciliation Test Stub

<!-- TOC -->
* [Overview](#Overview)
* [Wiremock](#Wiremock)
* [Kafka](#Kafka)
* [TLS/MTLS](#TLS/MTLS)
* [Deployment](#Deployment)
<!-- TOC -->
        
##Overview
The Discover and Reconciliation test stub deploys wiremock and kafka to enable end-to-end testing of the D&R application.

## Wiremock

Wiremock is deployed using wiremock/wiremock docker image. For details on configuring and running the image go to https://wiremock.org/docs/standalone/docker/.

The deployment supports both HTTP and HTTPS running on local ports 8080 and 8443 respectively.
For HTTPS, both TLS and MTLS are supported. MTLS is enabled by default which requires the client to sends its certificate.
Client certificate validation can be disabled by setting the value 'wiremock.mtls.enabled' to false. The certificates used by
 the wiremock deployment 'ca.p12' and 'server.p12' are located in the charts certs directory.

The deployment is pre-configured with wiremock mappings for a source and target system.

* Login (cookie)
* Login (bearer)
* Get sources
* Get source (enrichment)
* Get targets 
* Get target (enrichment)
* Reconcile target

The wiremock mappings are configured to return matches for the following built-in filters. The supported mappings are described in
the [Mappings](#Mappings) section.
* sourceInTarget
* sourceNotInTarget
* sourceMismatchedInTarget
* targetNotInSource

### Deployment options

| Value                 | Default | Description                  |
|-----------------------|---------|------------------------------|
| wiremock.mtls.enabled | true    | Verify client cert for mtls. |

###Mappings

####Cookie Login
URL: **POST /login?***

Return a response with authentication cookie. The cookie is required in all requests to /sources.

Example Request:
```
kubectl -n <namespace> exec deployment/eric-esoa-dr-stub -- curl -X POST "http://localhost:8080/login?username=test&password=test" -i
```
Example Response Cookie:

```
JSESSIONID=a52f3a6d-d328-4708-bfa3-5f2d5dfcc151; Path=/; Max-Age=36000; Expires=Fri, 09 Jun 2023 02:01:40 GMT; Secure; HttpOnly; SameSite=Lax
```
####Bearer Login

URL: **POST /token?***

Return a response with body containing a bearer token. The bearer token is required in all requests to /targets.

Example Request:
```
kubectl -n <namespace> exec deployment/eric-esoa-dr-stub -- curl -X POST "http://localhost:8080/token?username=test&password=test" 
```
Example Response:
```
{
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJwcmVmZXJyZWRfdXNlcm5hbWUiOiJkci11c2VyIn0.STtPZ7Ar0qJzfIu7S723DOO2wHmp18n47edXTzm8jcA",
    "expires_in": 300,
    "refresh_expires_in": 1800,
    "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJwcmVmZXJyZWRfdXNlcm5hbWUiOiJkci11c2VyIn0.STtPZ7Ar0qJzfIu7S723DOO2wHmp18n47edXTzm8jcA",
    "token_type": "Bearer",
    "not-before-policy": 0,
    "session_state": "94cdb815-f874-4ceb-89c6-5db9570d377e",
    "scope": "email profile"
 }
```

####Get Sources

URL: **GET /sources**

Returns a list of 10 source objects with id property ranging from 1-10.

Example Request:
```
kubectl -n <namespace> exec deployment/eric-esoa-dr-stub -- curl http://localhost:8080/sources --cookie "JSESSIONID=a52f3a6d-d328-4708-bfa3-5f2d5dfcc151"
```
Example Response:
```
[
 {
   "id": "1",
   "name": "object1"
 }
 .
 .
 .
 {
   "id": "1",
   "name": "object1"
 }
]
 ```

####Get Source

URL: **GET /sources/{id}**

Return details for a source object where id can be in the range 1-10.

Example Request:
```
kubectl -n <namespace> exec deployment/eric-esoa-dr-stub -- curl http://localhost:8080/sources/1 --cookie "JSESSIONID=a52f3a6d-d328-4708-bfa3-5f2d5dfcc151"
```
Example Response:
 ```
  {
    "id": "1",
    "name": "object1",
    "prop1": "value1",
    "prop2": 1
  }
 ```


####Get Targets

URL: **GET /targets**

Returns a list of 8 target objects.

6 of target objects with id 1-6 exist in the source.
2 of the target objects with id 1000 and 2000 do not exist in the source.

Example Request:
```
kubectl -n <namespace> exec deployment/eric-esoa-dr-stub -- curl http://localhost:8080/targets -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJwcmVmZXJyZWRfdXNlcm5hbWUiOiJkci11c2VyIn0.STtPZ7Ar0qJzfIu7S723DOO2wHmp18n47edXTzm8jcA"
```
Example response:
 ```
 [
  {
    "id": "1",
    "name": "object1"
  }
  .
  .
  .
    {
    "id": "10",
    "name": "object10"
  }
 ]
 ```

####Get Target

URL: **GET /targets/{id}**

Return details for a target object where id can be in the range 1-6.

Targets with id 1-4 are configured to match the object in the source system.

Target with ids 5 and 6 are configured to mismatch the corresponding objects in the source.
Both of the properties prop1 and prop2 mismatch with the soruce object.

Example Request:
```
kubectl -n <namespace> exec deployment/eric-esoa-dr-stub -- curl http://localhost:8080/targets/1 -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJwcmVmZXJyZWRfdXNlcm5hbWUiOiJkci11c2VyIn0.STtPZ7Ar0qJzfIu7S723DOO2wHmp18n47edXTzm8jcA"
```
Example Response:
```
  {
    "id": "1",
    "name": "object1",
    "prop1": "value1",
    "prop2": 1
  }
 ```

####Reconcile Target

URL: **POST /reconcile/targets/{id}**

Returns reconcile result for a target object where id can be any integer.

Example Request:
```
kubectl -n <namespace> exec deployment/eric-esoa-dr-stub -- curl http://localhost:8080/reconcile/targets/1 -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJwcmVmZXJyZWRfdXNlcm5hbWUiOiJkci11c2VyIn0.STtPZ7Ar0qJzfIu7S723DOO2wHmp18n47edXTzm8jcA"
```
Example Response:
```
{
    "id": "1",
    "result": "SUCCESS"
}
 ```

###Wiremock Commands

#### List mappings

List the mappings in the running deployment.
```
kubectl -n <namespace> exec deployment/eric-bos-dr-stub -- curl http://localhost:8080/__admin/mappings
```

#### List requests

List all received requests in the running deployment.
```
kubectl -n <namespace> exec deployment/eric-bos-dr-stub -- curl http://localhost:8080/__admin/requests
```

## Kafka

Kafka is deployed using confluentinc/confluent-local image. For details on configuring and running the image go to https://hub.docker.com/r/confluentinc/confluent-local.

The deployment supports both unsecure and secure communication on local ports 9092 and 9094 respectively. The keystores used by
the kafka deployment 'trustore.jks' and 'keystore.jks' are located in the charts certs directory.

The confluent-local image includes the Confluent REST Proxy, providing a RESTful interface (https://docs.confluent.
io/platform/current/kafka-rest/api.html) to access the kafka broker. 


### Deployment Options


| Value                 | Default | Description                                        |
|-----------------------|---------|----------------------------------------------------|
| kafka.nodeId          | 1       | Unique broker identifier, required for KRaft mode. |
| kafka.topicAutoCreate | false   | Auto-create topic when producer sends message.     |
| kafka.sslClientAuth   | true    | Verify client cert for mtls.                       |

### Kafka Commands

#### Create a topic

```
kubectl -n <namespace> exec -it deployment/eric-bos-dr-stub-kafka -- bash -c "/usr/bin/kafka-topics --create --topic my_topic --partitions 1 --replication-factor 1 --bootstrap-server localhost:9092"
```

#### Send a message 
Exec onto the kafka pod.
```
kubectl --namespace <namespace> exec -it deployment/eric-bos-dr-stub-kafka --bash
```
Start console producer and input message(s).
```
/usr/bin/kafka-console-producer --bootstrap-server localhost:9092 --topic topic_one
>{"eventType": "CREATE"}
```


## TLS/MTLS
Both the kafka and wiremock deployments serve the same self-signed certificate 'server.crt' located in the chart directory '/certs'.

For TLS, a client must include the self-signed CA certificate 'ca.p12' in its truststore.

For MTLS, a client must generate its client certificate using the same self-signed root CA cert.

##Deployment 

The stub is packaged as a helm chart and published in the repository, https://arm.sero.gic.ericsson.se/artifactory/proj-so-gs-all-helm/eric-bos-dr-stub.

An ingress is created to provide access to the Kafka deployment via HTTP. It requires the value 'ingress.hostname' to be set, where hostname is
the fqdn e.g. eric-bos-dr-stub-kafka.anvil-haber003.ews.gic.ericsson.se.
If the ingress is not required then it can be disabled by setting 'ingress.enabled=false'.

Run the following command to install the stub using one of the available helm chart versions.

```
helm install <NAME> <CHART> -n <namespace> --wait --timeout 60s [--set ingress.hostname=<INGRESS_HOSTNAME>]

e.g

helm install eric-bos-dr-stub https://arm.sero.gic.ericsson.se/artifactory/proj-so-gs-all-helm/eric-bos-dr-stub/eric-bos-dr-stub-0.0.1-1.tgz -n my_namespace --wait --timeout 60s --set ingress.hostname=eric-bos-dr-stub-kafka.anvil-haber003.ews.gic.ericsson.se
```

In order to test against multiple kafka instances, the stub can be deployed multiple times using the name override.

```
helm install eric-bos-dr-stub2 https://arm.sero.gic.ericsson.se/artifactory/proj-so-gs-all-helm/eric-bos-dr-stub/eric-bos-dr-stub-0.0.1-1.tgz -n my_namespace --wait --timeout 60s --set nameOverride=eric-bos-dr-stub2 --set ingress.hostname=eric-bos-dr-stub-kafka.anvil-haber003.ews.gic.ericsson.se
```
