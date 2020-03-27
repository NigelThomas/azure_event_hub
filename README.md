# Using SQLstream with Azure Event Hub

See https://docs.microsoft.com/en-us/azure/event-hubs/event-hubs-quickstart-kafka-enabled-event-hubs

To use Kafka API your event hub must be on the Standard plan _(not Basic)_ This is 2x cost.

For simplest approach to security, use SSL option at step 6.

Your broker URL will be NAMESPACENAME.servicebus.windows.net:9093 (NAMESPACE is the name of your hub)

config will be:
```
    bootstrap.servers=NAMESPACENAME.servicebus.windows.net:9093
    security.protocol=SASL_SSL
    sasl.mechanism=PLAIN
    sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username="$ConnectionString" password="{YOUR.EVENTHUBS.CONNECTION.STRING}";
```

Replace NAMESPACENAME with your event hub name; replace the password with your connection string (don't keep the {} brackets).

You need to create a security principal, assign it at least one appropriate Azure Event Hub role.

Once you have that, you can go into the Shared Access Policies section of Event Hub and click on the policy RootManageSharedAccessKey. The Primary and secondary keys and connection strings will be dusplayed.
Use the primary connection string to replace {YOUR.EVENTHUBS.CONNECTION.STRING} in the sasl.jaas.config above.


## Sending data to Azure Event Hub via kafkacat:

```
(base) Nigels-iMac:azure_event_hub nigel$ cat ./20-min-at-50-rps.xml.gz | zcat | ./dribble.sh | docker run -v `pwd`:/data/buses --interactive edenhill/kafkacat:1.5.0 kafkacat -b nigelthomas-guavus.servicebus.windows.net:9093 -t test -P -F /data/buses/kafka.producer.config
% Reading configuration from file /data/buses/kafka.producer.config
```
Here is the command line:

```
cat ./20-min-at-50-rps.xml.gz | zcat | ./dribble.sh | docker run -v `pwd`:/data/buses --interactive edenhill/kafkacat:1.5.0 kafkacat -b nigelthomas-guavus.servicebus.windows.net:9093 -t buses -P -F /data/buses/kafka.producer.config
```

* I am piping from `cat` into `zcat` because zcat on Mac has a bug when given a filename
* `dribble.sh` is a simple script to read from `stdin` and sleep 1 second between records before emitting to `stdout` - in this repository
* I use the docker container `edenhill/kafkacat:1.5.0` in interactive mode because this is the easiest way to get most up to date kafkacat on Mac. 
 * On Ubuntu, the latest kafkacat is 1.3 which doesn't support the -F option, and so can't deal with all the security config for Azure Event Hub
* Using the docker option `--interactive` and `-P` allows us to pipe data into `kafkacat` running in the container

## Reading data using kafkacat

```
docker run -v `pwd`:/data/buses -it edenhill/kafkacat:1.5.0 kafkacat -b nigelthomas-guavus.servicebus.windows.net:9093  -F /data/buses/kafka.consumer.config -o beginning -v -f "%s\n" -t buses | tee buses.log
```

## Example StreamLab projects

### azure_event_lab_buses

* Replace the buses file source with a Kafka source reading from Azure Event Hub
* Use kafkacat as shown above to trickle XML data into the topic
* Verify that data appears in pipeline_1
* This demonstrates SQLstream reading from an AEH topic

* Add a pipeline reading from the nexus
* Add an additional target - route to sink: JSON data to Kafka (AEH) into a separate topic
* This demonstrates SQLstream writing to an AEH topic


#### Issues

* Add another pipeline to read that JSON data
* We seem to get blank lines between JSON records; so we get a good message followed by an empty message.
* We see the same reading from the same topic using kafkacat
* So I believe the SQLstream producer is somehow confusing AEH into thinking there are two records in each message - perhaps there is a trailing newline?
* At some point I should test whether the same behaviour occurs if we use Kafka instead of AEH. 

### azure_event_hub.slab

Simple source to read from an AEH topic which is populated by kafkacat

