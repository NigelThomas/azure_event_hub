# Using SQLstream with Azure Event Hub

See https://docs.microsoft.com/en-us/azure/event-hubs/event-hubs-quickstart-kafka-enabled-event-hubs

To use Kafka API your event hub must be on the Standard plan (not Basic) This is 2x cost.

For simplest approach to security, use SSL option at step 6.

Your broker URL will be NAMESPACENAME.servicebus.windows.net:9093 (NAMESPACE is the name of your hub)

config will be:
    bootstrap.servers=NAMESPACENAME.servicebus.windows.net:9093
    security.protocol=SASL_SSL
    sasl.mechanism=PLAIN
    sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username="$ConnectionString" password="{YOUR.EVENTHUBS.CONNECTION.STRING}";
Replace NAMESPACENAME with your event hub name; replace the password with your connection string (don't keep the {} brackets).

You need to create a security principal, assign it at least one appropriate Azure Event Hub role.

Once you have that, you can go into the Shared Access Policies section of Event Hub and click on the policy RootManageSharedAccessKey. The Primary and secondary keys and connection strings will be dusplayed.
Use the primary connection string to replace {YOUR.EVENTHUBS.CONNECTION.STRING} in the sasl.jaas.config above.


Example of sending data to Azure Event Hub via kafkacat:

```
(base) Nigels-iMac:azure_event_hub nigel$ cat ./20-min-at-50-rps.xml.gz | zcat | ./dribble.sh | docker run -v `pwd`:/data/buses --interactive edenhill/kafkacat:1.5.0 kafkacat -b nigelthomas-guavus.servicebus.windows.net:9093 -t buses -P -F /data/buses/kafka.producer.config
% Reading configuration from file /data/buses/kafka.producer.config
% ERROR: Failed to produce message (266 bytes): Local: Unknown topic
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
 * On Ubuntu, the latest kafkacat is 1.3 which doesn't support the -F option, and can't deal with all the security config for Azure Event Hub
* Using the docker option `--interactive` and `-P` allows us to pipe data into `kafkacat` runnin in the container


Error reading for kafka topic: buses                                                                SEVERE [5720 2020-03-27 12:36:19.359]: com.sqlstream.aspen.namespace.kafka.KafkaInputSource$Impl run Error reading field 'member_assignment': Bytes size -1 cannot be negative
org.apache.kafka.common.protocol.types.SchemaException: Error reading field 'member_assignment': Bytes size -1 cannot be negative
        at org.apache.kafka.common.protocol.types.Schema.read(Schema.java:76)
        at org.apache.kafka.common.protocol.ApiKeys.parseResponse(ApiKeys.java:279)
        at org.apache.kafka.clients.NetworkClient.parseStructMaybeUpdateThrottleTimeMetrics(NetworkClient.java:586)
        at org.apache.kafka.clients.NetworkClient.handleCompletedReceives(NetworkClient.java:686)
        at org.apache.kafka.clients.NetworkClient.poll(NetworkClient.java:469)
        at org.apache.kafka.clients.consumer.internals.ConsumerNetworkClient.poll(ConsumerNetworkClient.java:258)
        at org.apache.kafka.clients.consumer.internals.ConsumerNetworkClient.poll(ConsumerNetworkClient.java:230)
        at org.apache.kafka.clients.consumer.internals.ConsumerNetworkClient.poll(ConsumerNetworkClient.java:190)
        at org.apache.kafka.clients.consumer.internals.AbstractCoordinator.joinGroupIfNeeded(AbstractCoordinator.java:364)
        at org.apache.kafka.clients.consumer.internals.AbstractCoordinator.ensureActiveGroup(AbstractCoordinator.java:316)
        at org.apache.kafka.clients.consumer.internals.ConsumerCoordinator.poll(ConsumerCoordinator.java:295)
        at org.apache.kafka.clients.consumer.KafkaConsumer.pollOnce(KafkaConsumer.java:1146)
        at org.apache.kafka.clients.consumer.KafkaConsumer.poll(KafkaConsumer.java:1111)
        at com.sqlstream.aspen.namespace.kafka.KafkaInputSource$Impl.run(KafkaInputSource.java:459)
        at java.lang.Thread.run(Thread.java:748)

 Index: 0, Size: 0                                                                                  INFO [5719 2020-03-27 12:36:19.382]: com.sqlstream.discovery.AbstractParserType isTypeOf

